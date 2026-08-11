import DesignDatabaseCore
import DesignDatabaseRuntime
import LogicDesignDatabaseSchema
import ParasiticDesignDatabaseSchema
import StandardCellLibraryDesignDatabaseSchema
import TimingDesignDatabaseSchema

public struct TimingDesignDatabaseSnapshotReader: Sendable {
    public init() {}

    public func readState(
        from snapshot: any DesignReadSnapshot,
        budget: TimingDatabaseReadBudget
    ) async throws -> TimingSnapshotState {
        let timingFacetID = try TimingDatabaseFacet.timing.designFacetID
        guard let root = snapshot.facetRoots.first(where: { $0.facetID == timingFacetID })?.digest else {
            return TimingSnapshotState(timing: nil, invalidation: nil)
        }
        guard let runtimeSnapshot = snapshot as? DesignDatabaseRuntimeSnapshot else {
            throw TimingDatabaseReadError.unsupportedSnapshotImplementation
        }
        let state = try await runtimeSnapshot.withRuntimeReads(
            maximumReadCount: try budget.runtimeReadCount
        ) { reads in
            try await TimingDatabaseRuntimeStateReader().read(
                expectedRoot: root,
                from: reads,
                budget: budget
            )
        }
        return TimingSnapshotState(
            timing: state,
            invalidation: try invalidation(for: state, in: snapshot)
        )
    }

    private func invalidation(
        for state: TimingDatabaseState,
        in snapshot: any DesignReadSnapshot
    ) throws -> TimingFacetInvalidation? {
        let logicFacetID = try state.sourceLogic.sourceFacet.designFacetID
        let logicRoot = snapshot.facetRoots.first(where: {
            $0.facetID == logicFacetID
        })?.digest
        if logicRoot != state.sourceLogic.sourceRootDigest {
            return TimingFacetInvalidation(
                observedRevision: snapshot.revision,
                dependency: .logic,
                expectedRootDigest: state.sourceLogic.sourceRootDigest,
                actualRootDigest: logicRoot
            )
        }
        let libraryFacetID = try StandardCellLibraryDatabaseFacet.library.designFacetID
        let libraryRoot = snapshot.facetRoots.first(where: { $0.facetID == libraryFacetID })?.digest
        if libraryRoot != state.sourceLibrary.sourceRootDigest {
            return TimingFacetInvalidation(
                observedRevision: snapshot.revision,
                dependency: .standardCellLibrary,
                expectedRootDigest: state.sourceLibrary.sourceRootDigest,
                actualRootDigest: libraryRoot
            )
        }
        if let source = state.sourceParasitics {
            let facetID = try ParasiticDatabaseFacet.parasitics.designFacetID
            let root = snapshot.facetRoots.first(where: { $0.facetID == facetID })?.digest
            if root != source.sourceRootDigest {
                return TimingFacetInvalidation(
                    observedRevision: snapshot.revision,
                    dependency: .parasitics,
                    expectedRootDigest: source.sourceRootDigest,
                    actualRootDigest: root
                )
            }
        }
        return nil
    }
}
