import CircuiteFoundation
import CircuiteFoundationCrypto
import Database
import DesignDatabaseCore
import DesignDatabaseRuntime
import Foundation
import LogicDesignDatabaseSchema
import ParasiticDesignDatabaseSchema
import StandardCellLibraryDesignDatabaseSchema
import TimingDesignDatabaseSchema

public struct TimingDesignDatabaseRuntimeAdapter:
    DesignDatabaseRuntimeMutationAdapter,
    Sendable
{
    public let schemaID: DesignSchemaID
    public let schemaVersion = SchemaVersion.v1
    public let adapterVersion = TimingDesignDatabaseSchema.adapterVersion
    public let supportedFacets: Set<DesignFacetID>

    public init() throws {
        schemaID = try TimingDesignDatabaseSchema.schemaID
        supportedFacets = [try TimingDatabaseFacet.timing.designFacetID]
    }

    public func contribution() throws -> DesignDatabaseRuntimeContribution {
        let bindingDigest = try TimingDatabaseDigesting.sha256(
            Array(TimingDesignDatabaseSchema.bindingManifest.utf8)
        )
        return try DesignDatabaseRuntimeContribution(
            id: DesignDatabaseRuntimeContributionID("lsi.timing-design-database"),
            designSchemaMember: DesignSchemaBundleMember(
                schemaID: schemaID,
                version: schemaVersion,
                canonicalDigest: bindingDigest
            ),
            bindingDigest: bindingDigest,
            entities: [try TimingDatabaseFacetPage.schemaEntity],
            entityRuntimes: [try DatabaseFrameworkRuntime.entity(TimingDatabaseFacetPage.self)],
            mutationAdapter: self,
            physicalWriteReclaimers: [self]
        )
    }

    public func validate(
        _ segment: DesignMutationPlanSegment,
        in context: DesignDatabaseRuntimeMutationValidation
    ) async throws(DesignDatabaseRuntimeMutationAdapterError)
        -> DesignDatabaseRuntimeValidatedMutation {
        let facetID: DesignFacetID
        do { facetID = try TimingDatabaseFacet.timing.designFacetID }
        catch { throw .invalidPayload(reason: String(describing: error)) }
        guard segment.schemaID == schemaID,
              segment.schemaVersion == schemaVersion,
              segment.adapterVersion == adapterVersion,
              segment.targetFacet == facetID else {
            throw .invalidPayload(reason: "The timing segment binding is not registered.")
        }
        let state: TimingDatabaseState
        do { state = try TimingDatabaseCanonicalCodec.decode(Data(segment.payload)) }
        catch TimingDatabaseSchemaError.invalidTimingState(let findings) {
            throw .validationFailed(
                diagnostics: findings.map {
                    DesignDiagnostic(
                        code: .trusted("TIMING_CANONICAL_STATE_INVALID"),
                        severity: .error,
                        summary: $0
                    )
                },
                diagnosticsDigest: segment.payloadDigest
            )
        } catch { throw .invalidPayload(reason: String(describing: error)) }
        try validateDependencies(
            state,
            context: context,
            diagnosticsDigest: segment.payloadDigest
        )
        let document: TimingDatabaseCanonicalDocument
        do { document = try TimingDatabaseCanonicalDocument(state: state) }
        catch { throw .invalidPayload(reason: String(describing: error)) }
        guard document.pages.count == segment.expectedWriteCount else {
            throw .invalidPayload(reason: "The declared write count does not match the canonical page count.")
        }
        let observed: ContentDigest
        do {
            observed = try DesignMutationPlanDigest.payload(
                segment.payload,
                using: SHA256ContentDigester()
            )
        } catch { throw .invalidPayload(reason: String(describing: error)) }
        guard observed == segment.payloadDigest,
              document.facetRootDigest == segment.payloadDigest else {
            throw .invalidPayload(reason: "The canonical timing payload digest does not match the segment.")
        }
        return DesignDatabaseRuntimeValidatedMutation(
            segmentID: segment.id,
            materializationPayload: segment.payload
        )
    }

    public func materializeValidatedMutation(
        _ validation: DesignDatabaseRuntimeValidatedMutationRecord,
        for segment: DesignMutationPlanSegment,
        in context: DesignDatabaseRuntimeMutationRestoration
    ) throws(DesignDatabaseRuntimeMutationAdapterError)
        -> any DesignDatabaseRuntimePreparedMutation {
        _ = context
        do {
            guard validation.materializationPayloadDigest
                    == validation.segmentPayloadDigest else {
                throw DesignDatabaseRuntimeMutationAdapterError.invalidPayload(
                    reason: "The validated timing capsule is not the canonical segment payload."
                )
            }
            let materialization = try TimingDatabaseCanonicalDocument
                .materializeValidated(
                    canonicalData: Data(validation.materializationPayload)
                )
            guard UInt64(materialization.pages.count) == segment.expectedWriteCount,
                  materialization.facetRootDigest == segment.payloadDigest else {
                throw DesignDatabaseRuntimeMutationAdapterError.invalidPayload(
                    reason: "The materialized timing pages do not match the validated segment."
                )
            }
            return TimingPreparedMutation(
                segmentID: validation.segmentID,
                pages: materialization.pages,
                facetRootDigest: materialization.facetRootDigest,
                changeContributionDigest: materialization.facetRootDigest
            )
        } catch let error as DesignDatabaseRuntimeMutationAdapterError {
            throw error
        } catch {
            throw .invalidPayload(
                reason: "The validated timing input could not be materialized: \(error)"
            )
        }
    }

    private func validateDependencies(
        _ state: TimingDatabaseState,
        context: DesignDatabaseRuntimeMutationValidation,
        diagnosticsDigest: ContentDigest
    ) throws(DesignDatabaseRuntimeMutationAdapterError) {
        guard state.sourceLogic.sourceRevision == context.baseRevision,
              state.sourceLibrary.sourceRevision == context.baseRevision,
              state.sourceParasitics?.sourceRevision == nil
                || state.sourceParasitics?.sourceRevision == context.baseRevision else {
            throw .validationFailed(
                diagnostics: [DesignDiagnostic(
                    code: .trusted("TIMING_DEPENDENCY_REVISION_MISMATCH"),
                    severity: .error,
                    summary: "All timing dependencies must bind the exact base revision."
                )],
                diagnosticsDigest: diagnosticsDigest
            )
        }
        let logicFacetID: DesignFacetID
        let libraryFacetID: DesignFacetID
        do {
            logicFacetID = try state.sourceLogic.sourceFacet.designFacetID
            libraryFacetID = try StandardCellLibraryDatabaseFacet.library.designFacetID
        } catch { throw .invalidPayload(reason: String(describing: error)) }
        var mismatches: [String] = []
        if context.baseFacetRoots.first(where: { $0.facetID == logicFacetID })?.digest
            != state.sourceLogic.sourceRootDigest {
            mismatches.append("logic")
        }
        if context.baseFacetRoots.first(where: { $0.facetID == libraryFacetID })?.digest
            != state.sourceLibrary.sourceRootDigest {
            mismatches.append("standard-cell-library")
        }
        if let source = state.sourceParasitics {
            let parasiticFacetID: DesignFacetID
            do { parasiticFacetID = try ParasiticDatabaseFacet.parasitics.designFacetID }
            catch { throw .invalidPayload(reason: String(describing: error)) }
            if context.baseFacetRoots.first(where: { $0.facetID == parasiticFacetID })?.digest
                != source.sourceRootDigest {
                mismatches.append("parasitics")
            }
        }
        guard mismatches.isEmpty else {
            throw .validationFailed(
                diagnostics: [DesignDiagnostic(
                    code: .trusted("TIMING_DEPENDENCY_ROOT_MISMATCH"),
                    severity: .error,
                    summary: "Timing dependency roots do not match the exact base revision.",
                    detail: mismatches.joined(separator: ",")
                )],
                diagnosticsDigest: diagnosticsDigest
            )
        }
    }
}
