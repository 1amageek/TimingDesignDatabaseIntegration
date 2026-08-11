import CircuiteFoundation

public struct TimingFacetInvalidation: Sendable, Hashable, Codable {
    public enum Dependency: String, Sendable, Hashable, Codable {
        case logic
        case standardCellLibrary
        case parasitics
    }

    public let observedRevision: DesignRevisionReference
    public let dependency: Dependency
    public let expectedRootDigest: ContentDigest
    public let actualRootDigest: ContentDigest?

    public init(
        observedRevision: DesignRevisionReference,
        dependency: Dependency,
        expectedRootDigest: ContentDigest,
        actualRootDigest: ContentDigest?
    ) {
        self.observedRevision = observedRevision
        self.dependency = dependency
        self.expectedRootDigest = expectedRootDigest
        self.actualRootDigest = actualRootDigest
    }
}
