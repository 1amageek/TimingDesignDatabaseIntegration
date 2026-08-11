import CircuiteFoundation
import CircuiteFoundationCrypto

public enum TimingDatabaseDigesting {
    public static func sha256(_ bytes: borrowing [UInt8]) throws -> ContentDigest {
        let count = UInt64(bytes.count)
        let limits = try ContentDigestSessionLimits(
            maximumChunkByteCount: max(count, 1),
            maximumTotalByteCount: max(count, 1),
            maximumUpdateCount: 1
        )
        return try SHA256ContentDigester().digest(using: .sha256, limits: limits) {
            (lease: borrowing ContentDigestUpdateLease) throws(ContentDigestError) in
            try lease.update(bytes)
        }.digest
    }
}
