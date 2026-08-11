import Database
import DesignDatabaseRuntime
import TimingDesignDatabaseSchema

extension TimingDesignDatabaseRuntimeAdapter:
    DesignDatabaseRuntimePhysicalWriteReclaimer
{
    static let physicalStorageType =
        "TimingDesignDatabaseSchema.TimingDatabaseFacetPage.v1"

    public var storageType: String { Self.physicalStorageType }

    public func deleteImmutableWrite(
        _ identity: DesignDatabaseRuntimeImmutableWriteIdentity,
        from transaction: any DatabaseTransactionWriting
    ) async throws(DesignDatabaseRuntimePhysicalWriteReclaimerError) {
        let components = try DesignDatabaseRuntimePhysicalWriteDeletion
            .requirePartitionComponents(identity, storageType: storageType, count: 2)
        var partition = DirectoryPath<TimingDatabaseFacetPage>()
        partition.set(TimingDatabaseFacetPage.fields.facetID, to: components[0])
        partition.set(TimingDatabaseFacetPage.fields.documentDigest, to: components[1])
        try await DesignDatabaseRuntimePhysicalWriteDeletion.delete(
            identity,
            model: TimingDatabaseFacetPage.self,
            identifiedBy: identity.modelID,
            in: partition,
            expectedIdentity: Self.physicalWriteIdentity,
            from: transaction
        )
    }

    static func physicalWriteIdentity(
        _ page: TimingDatabaseFacetPage
    ) throws(DesignDatabaseRuntimePreparedMutationError)
        -> DesignDatabaseRuntimeImmutableWriteIdentity {
        try DesignDatabaseRuntimeImmutableWriteIdentity(
            storageType: physicalStorageType,
            partitionComponents: [page.facetID, page.documentDigest],
            modelID: page.id
        )
    }
}
