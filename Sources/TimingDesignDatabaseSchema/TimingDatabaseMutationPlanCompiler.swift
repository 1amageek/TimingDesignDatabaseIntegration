import CircuiteFoundation
import CircuiteFoundationCrypto
import DesignDatabaseCore

public struct TimingDatabaseMutationPlanCompiler: Sendable {
    public init() {}

    public func compile(
        _ state: TimingDatabaseState,
        segmentID: DesignMutationPlanSegmentID,
        databaseID: DesignDatabaseID,
        baseRevision: DesignRevisionReference,
        designSchemaBundleDigest: ContentDigest,
        dependencyRootDigest: ContentDigest,
        semanticDependencyGraphDigest: ContentDigest,
        sourceEvidenceDigest: ContentDigest
    ) throws -> DesignMutationPlan {
        let data = try TimingDatabaseCanonicalCodec.encode(state)
        let payload = Array(data)
        let digester = SHA256ContentDigester()
        let payloadDigest = try DesignMutationPlanDigest.payload(payload, using: digester)
        let writeCount = try TimingDatabaseCanonicalDocument.pageCount(forByteCount: data.count)
        let segment = try DesignMutationPlanSegment(
            id: segmentID,
            schemaID: try TimingDesignDatabaseSchema.schemaID,
            schemaVersion: .v1,
            adapterVersion: TimingDesignDatabaseSchema.adapterVersion,
            targetFacet: try TimingDatabaseFacet.timing.designFacetID,
            payload: payload,
            payloadDigest: payloadDigest,
            expectedWriteCount: writeCount
        )
        let budget = try DesignMutationPlanBudget(
            maximumSegmentCount: 1,
            maximumPayloadByteCount: UInt64(data.count),
            maximumPreparedWriteCount: writeCount,
            maximumValidationReadCount: 1
        )
        let planDigest = try DesignMutationPlanDigest.plan(
            databaseID: databaseID,
            baseRevision: baseRevision,
            designSchemaBundleDigest: designSchemaBundleDigest,
            dependencyRootDigest: dependencyRootDigest,
            semanticDependencyGraphDigest: semanticDependencyGraphDigest,
            sourceEvidenceDigest: sourceEvidenceDigest,
            budget: budget,
            segments: [segment],
            using: digester
        )
        return DesignMutationPlan(
            databaseID: databaseID,
            baseRevision: baseRevision,
            designSchemaBundleDigest: designSchemaBundleDigest,
            dependencyRootDigest: dependencyRootDigest,
            semanticDependencyGraphDigest: semanticDependencyGraphDigest,
            sourceEvidenceDigest: sourceEvidenceDigest,
            budget: budget,
            segments: [segment],
            planDigest: planDigest
        )
    }
}
