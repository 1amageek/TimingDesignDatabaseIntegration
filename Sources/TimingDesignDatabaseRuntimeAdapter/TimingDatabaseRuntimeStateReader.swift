import CircuiteFoundation
import CircuiteFoundationCrypto
import Database
import DatabaseTypesFoundation
import DesignDatabaseRuntime
import Foundation
import TimingDesignDatabaseSchema

public struct TimingDatabaseRuntimeStateReader: Sendable {
    public init() {}

    public func read(
        expectedRoot: ContentDigest,
        from reads: DesignDatabaseRuntimeReadSnapshot,
        budget: TimingDatabaseReadBudget
    ) async throws -> TimingDatabaseState {
        var partition = DirectoryPath<TimingDatabaseFacetPage>()
        partition.set(TimingDatabaseFacetPage.fields.facetID, to: TimingDatabaseFacet.timing.rawValue)
        partition.set(TimingDatabaseFacetPage.fields.documentDigest, to: expectedRoot.hexadecimalValue)
        var pages: [TimingDatabaseFacetPage] = []
        var continuation: DatabaseScanContinuation?
        repeat {
            let page = try await reads.scan(
                TimingDatabaseFacetPage.self,
                in: partition,
                after: continuation,
                limit: budget.pageFetchLimit
            )
            pages.append(contentsOf: page.items)
            guard pages.count <= budget.maximumPageCount else {
                throw TimingDatabaseReadError.pageBudgetExceeded(limit: budget.maximumPageCount)
            }
            continuation = page.continuation
        } while continuation != nil
        guard let first = pages.first else { throw TimingDatabaseReadError.missingFacetPages }
        let ordered = pages.sorted { $0.ordinal < $1.ordinal }
        guard first.pageCount == UInt64(ordered.count),
              ordered.allSatisfy({
                  $0.facetID == TimingDatabaseFacet.timing.rawValue
                    && $0.pageCount == first.pageCount
                    && $0.documentByteCount == first.documentByteCount
                    && $0.documentDigest == first.documentDigest
              }) else { throw TimingDatabaseReadError.inconsistentPageMetadata }
        for (index, page) in ordered.enumerated() where page.ordinal != UInt64(index) {
            throw TimingDatabaseReadError.nonContiguousPages
        }
        guard let capacity = Int(exactly: first.documentByteCount) else {
            throw TimingDatabaseReadError.inconsistentPageMetadata
        }
        var data = Data()
        data.reserveCapacity(capacity)
        for page in ordered {
            page.payload.withUnsafeBytes { data.append($0.bindMemory(to: UInt8.self)) }
        }
        guard UInt64(data.count) == first.documentByteCount else {
            throw TimingDatabaseReadError.byteCountMismatch(
                expected: first.documentByteCount,
                actual: UInt64(data.count)
            )
        }
        let actual = try SHA256ContentDigester().digest(data: data)
        guard actual == expectedRoot else {
            throw TimingDatabaseReadError.facetRootMismatch(expected: expectedRoot, actual: actual)
        }
        do { return try TimingDatabaseCanonicalCodec.decode(data) }
        catch let error { throw TimingDatabaseReadError.decodeFailed(error) }
    }
}
