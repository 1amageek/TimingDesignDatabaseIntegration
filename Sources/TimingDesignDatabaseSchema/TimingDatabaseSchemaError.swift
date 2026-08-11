public enum TimingDatabaseSchemaError: Error, Sendable, Hashable {
    case unsupportedSchemaVersion(Int)
    case invalidSourceBinding(reason: String)
    case invalidArtifactDescriptor(role: String)
    case invalidTimingState([String])
    case nonCanonicalOrdering
    case encodingFailed(reason: String)
    case decodingFailed(reason: String)
    case nonCanonicalPayload
    case invalidPageByteCount(Int)
    case pageCountOverflow
}
