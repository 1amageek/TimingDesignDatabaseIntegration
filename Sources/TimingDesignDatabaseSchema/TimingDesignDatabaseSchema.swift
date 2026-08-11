import CircuiteFoundation
import DesignDatabaseCore

public enum TimingDesignDatabaseSchema {
    public static let adapterVersion = "1.0.0"
    public static let bindingManifest = """
    lsi.timing-design-database-schema/v1
    entity=TimingDatabaseFacetPage
    directory=design-database/timing-facets/{facetID}/{documentDigest}/pages
    fields=id,facetID,ordinal,pageCount,documentByteCount,documentDigest,payload
    facets=timing.design
    sourceBinding=exact-gate+standard-cell+optional-parasitic
    canonicalState=design+constraints+libraries+optional-parasitics
    verdicts=evidence-only
    pageByteCount=65536
    """

    public static var schemaID: DesignSchemaID {
        get throws { try DesignSchemaID(rawValue: "lsi.timing") }
    }
}
