import CircuiteFoundation
import TimingDesignDatabaseSchema

public enum TimingDatabaseReadError: Error, Sendable, Hashable {
    case unsupportedSnapshotImplementation
    case invalidBudget
    case pageBudgetExceeded(limit: Int)
    case missingFacetPages
    case inconsistentPageMetadata
    case nonContiguousPages
    case byteCountMismatch(expected: UInt64, actual: UInt64)
    case facetRootMismatch(expected: ContentDigest, actual: ContentDigest)
    case decodeFailed(TimingDatabaseSchemaError)
}
