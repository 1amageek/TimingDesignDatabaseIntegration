import CircuiteFoundation

public struct TimingDatabaseFacetSourceBinding: Sendable, Hashable, Codable {
    public static let currentSchemaVersion = 1
    public let schemaVersion: Int
    public let sourceRevision: DesignRevisionReference
    public let sourceFacet: TimingDatabaseFacet
    public let sourceRootDigest: ContentDigest

    public init(
        sourceRevision: DesignRevisionReference,
        sourceFacet: TimingDatabaseFacet = .timing,
        sourceRootDigest: ContentDigest
    ) throws(TimingDatabaseSchemaError) {
        guard sourceFacet == .timing else {
            throw .invalidSourceBinding(reason: "DFT consumers must bind the canonical timing facet.")
        }
        schemaVersion = Self.currentSchemaVersion
        self.sourceRevision = sourceRevision
        self.sourceFacet = sourceFacet
        self.sourceRootDigest = sourceRootDigest
    }

    public func validate() throws(TimingDatabaseSchemaError) {
        guard schemaVersion == Self.currentSchemaVersion else {
            throw .unsupportedSchemaVersion(schemaVersion)
        }
        guard sourceFacet == .timing else {
            throw .invalidSourceBinding(reason: "DFT consumers must bind the canonical timing facet.")
        }
    }
}
