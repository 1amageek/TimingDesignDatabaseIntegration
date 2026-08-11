import CircuiteFoundation
import DatabaseTypes
import DatabaseTypesFoundation
import Foundation

public struct TimingDatabaseCanonicalDocument: Sendable {
    public static let defaultPageByteCount = 64 * 1_024
    public let canonicalData: Data
    public let facetRootDigest: ContentDigest
    public let pages: [TimingDatabaseFacetPage]

    public init(
        state: TimingDatabaseState,
        pageByteCount: Int = Self.defaultPageByteCount
    ) throws(TimingDatabaseSchemaError) {
        guard pageByteCount > 0 else { throw .invalidPageByteCount(pageByteCount) }
        let data = try TimingDatabaseCanonicalCodec.encode(state)
        let digest: ContentDigest
        do { digest = try TimingDatabaseDigesting.sha256(Array(data)) }
        catch { throw .encodingFailed(reason: String(describing: error)) }
        let count = max(1, (data.count + pageByteCount - 1) / pageByteCount)
        guard let pageCount = UInt64(exactly: count),
              let byteCount = UInt64(exactly: data.count) else {
            throw .pageCountOverflow
        }
        let owner = ByteString(retaining: data)
        var pages: [TimingDatabaseFacetPage] = []
        for index in 0..<count {
            guard let ordinal = UInt64(exactly: index) else { throw .pageCountOverflow }
            let lower = index * pageByteCount
            let upper = min(data.count, lower + pageByteCount)
            pages.append(TimingDatabaseFacetPage(
                id: Self.pageID(ordinal),
                facetID: TimingDatabaseFacet.timing.rawValue,
                ordinal: ordinal,
                pageCount: pageCount,
                documentByteCount: byteCount,
                documentDigest: digest.hexadecimalValue,
                payload: owner[lower..<upper]
            ))
        }
        canonicalData = data
        facetRootDigest = digest
        self.pages = pages
    }

    public static func pageCount(
        forByteCount byteCount: Int,
        pageByteCount: Int = defaultPageByteCount
    ) throws(TimingDatabaseSchemaError) -> UInt64 {
        guard pageByteCount > 0 else { throw .invalidPageByteCount(pageByteCount) }
        guard let result = UInt64(exactly: max(1, (byteCount + pageByteCount - 1) / pageByteCount)) else {
            throw .pageCountOverflow
        }
        return result
    }

    /// Materializes pages from a Runtime-authenticated validation capsule.
    /// This method intentionally does not repeat domain semantic validation.
    public static func materializeValidated(
        canonicalData: Data,
        pageByteCount: Int = defaultPageByteCount
    ) throws(TimingDatabaseSchemaError) -> (
        facetRootDigest: ContentDigest,
        pages: [TimingDatabaseFacetPage]
    ) {
        guard pageByteCount > 0 else { throw .invalidPageByteCount(pageByteCount) }
        let digest: ContentDigest
        do { digest = try TimingDatabaseDigesting.sha256(Array(canonicalData)) }
        catch { throw .encodingFailed(reason: String(describing: error)) }
        let count = max(
            1,
            (canonicalData.count + pageByteCount - 1) / pageByteCount
        )
        guard let pageCount = UInt64(exactly: count),
              let byteCount = UInt64(exactly: canonicalData.count) else {
            throw .pageCountOverflow
        }
        let owner = ByteString(retaining: canonicalData)
        var pages: [TimingDatabaseFacetPage] = []
        pages.reserveCapacity(count)
        for index in 0..<count {
            guard let ordinal = UInt64(exactly: index) else {
                throw .pageCountOverflow
            }
            let lower = index * pageByteCount
            let upper = min(canonicalData.count, lower + pageByteCount)
            pages.append(
                TimingDatabaseFacetPage(
                    id: pageID(ordinal),
                    facetID: TimingDatabaseFacet.timing.rawValue,
                    ordinal: ordinal,
                    pageCount: pageCount,
                    documentByteCount: byteCount,
                    documentDigest: digest.hexadecimalValue,
                    payload: owner[lower..<upper]
                )
            )
        }
        return (digest, pages)
    }

    private static func pageID(_ ordinal: UInt64) -> String {
        let value = String(ordinal)
        return String(repeating: "0", count: 20 - value.count) + value
    }
}
