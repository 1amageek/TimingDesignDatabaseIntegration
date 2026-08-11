import CircuiteFoundation
import DesignDatabaseCore

public enum TimingDatabaseFacet: String, Sendable, Hashable, Codable, CaseIterable {
    case timing = "timing.design"

    public var designFacetID: DesignFacetID {
        get throws { try DesignFacetID(rawValue: rawValue) }
    }
}
