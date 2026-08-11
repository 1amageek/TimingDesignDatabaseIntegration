import Foundation

public enum TimingDatabaseCanonicalCodec {
    public static func encode(
        _ state: TimingDatabaseState
    ) throws(TimingDatabaseSchemaError) -> Data {
        try state.validate()
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        do { return try encoder.encode(state) }
        catch { throw .encodingFailed(reason: String(describing: error)) }
    }

    public static func decode(
        _ data: Data,
        requireCanonicalEncoding: Bool = true
    ) throws(TimingDatabaseSchemaError) -> TimingDatabaseState {
        let state: TimingDatabaseState
        do { state = try JSONDecoder().decode(TimingDatabaseState.self, from: data) }
        catch { throw .decodingFailed(reason: String(describing: error)) }
        try state.validate()
        if requireCanonicalEncoding, try encode(state) != data {
            throw .nonCanonicalPayload
        }
        return state
    }
}
