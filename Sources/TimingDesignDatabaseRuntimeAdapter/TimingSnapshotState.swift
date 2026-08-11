import TimingDesignDatabaseSchema

public struct TimingSnapshotState: Sendable, Hashable, Codable {
    public let timing: TimingDatabaseState?
    public let invalidation: TimingFacetInvalidation?

    public init(timing: TimingDatabaseState?, invalidation: TimingFacetInvalidation?) {
        self.timing = timing
        self.invalidation = invalidation
    }

    public var isSemanticallyCurrent: Bool { invalidation == nil }
}
