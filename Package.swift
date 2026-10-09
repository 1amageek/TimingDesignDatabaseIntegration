// swift-tools-version: 6.4
import PackageDescription

func releasedDependency(named name: String, exactVersion: Version) -> Package.Dependency {
    .package(
        url: "https://github.com/1amageek/\(name).git",
        exact: exactVersion
    )
}

let package = Package(
    name: "TimingDesignDatabaseIntegration",
    platforms: [.macOS(.v26)],
    products: [
        .library(
            name: "TimingDesignDatabaseSchema",
            targets: ["TimingDesignDatabaseSchema"]
        ),
        .library(
            name: "TimingDesignDatabaseRuntimeAdapter",
            targets: ["TimingDesignDatabaseRuntimeAdapter"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/1amageek/CircuiteFoundation.git", revision: "ae88104c556f5802819713ed741f5b2fffffc2d9"),
        .package(url: "https://github.com/1amageek/DesignDatabase.git", revision: "11df4ff7d905d642b5935defb3bc1fbcfefda038"),
        .package(url: "https://github.com/1amageek/TimingEngine.git", revision: "f645f1af8309061b760ff8596f7a1f73894967eb"),
        .package(url: "https://github.com/1amageek/LogicDesignDatabaseIntegration.git", revision: "20077f5a8a11b026289e0e4b4588e7afcd883fa6"),
        .package(url: "https://github.com/1amageek/StandardCellLibraryDesignDatabaseIntegration.git", revision: "8c788d2acbe67bced26aeb9585324ba309a1f676"),
        .package(url: "https://github.com/1amageek/ParasiticDesignDatabaseIntegration.git", revision: "cdfe99597b9f5583894ba7bd770935857869d66c"),
        .package(url: "https://github.com/1amageek/database-kit.git", exact: "26.0809.4"),
        .package(url: "https://github.com/1amageek/database-types.git", exact: "26.0730.0"),
        .package(
            url: "https://github.com/1amageek/database-framework.git",
            exact: "26.0809.1",
            traits: ["SQLite"]
        ),
    ],
    targets: [
        .target(
            name: "TimingDesignDatabaseSchema",
            dependencies: [
                .product(name: "CircuiteFoundation", package: "CircuiteFoundation"),
                .product(name: "CircuiteFoundationCrypto", package: "CircuiteFoundation"),
                .product(name: "DesignDatabaseCore", package: "DesignDatabase"),
                .product(name: "TimingCore", package: "TimingEngine"),
                .product(name: "LogicDesignDatabaseSchema", package: "LogicDesignDatabaseIntegration"),
                .product(name: "StandardCellLibraryDesignDatabaseSchema", package: "StandardCellLibraryDesignDatabaseIntegration"),
                .product(name: "ParasiticDesignDatabaseSchema", package: "ParasiticDesignDatabaseIntegration"),
                .product(name: "DatabaseKit", package: "database-kit"),
                .product(name: "DatabaseTypes", package: "database-types"),
                .product(name: "DatabaseTypesFoundation", package: "database-types"),
            ]
        ),
        .target(
            name: "TimingDesignDatabaseRuntimeAdapter",
            dependencies: [
                "TimingDesignDatabaseSchema",
                .product(name: "CircuiteFoundation", package: "CircuiteFoundation"),
                .product(name: "CircuiteFoundationCrypto", package: "CircuiteFoundation"),
                .product(name: "DesignDatabaseCore", package: "DesignDatabase"),
                .product(name: "DesignDatabaseRuntime", package: "DesignDatabase"),
                .product(name: "LogicDesignDatabaseSchema", package: "LogicDesignDatabaseIntegration"),
                .product(name: "StandardCellLibraryDesignDatabaseSchema", package: "StandardCellLibraryDesignDatabaseIntegration"),
                .product(name: "ParasiticDesignDatabaseSchema", package: "ParasiticDesignDatabaseIntegration"),
                .product(name: "Database", package: "database-framework"),
            ]
        ),
        .testTarget(
            name: "TimingDesignDatabaseIntegrationTests",
            dependencies: [
                "TimingDesignDatabaseSchema",
                "TimingDesignDatabaseRuntimeAdapter",
                .product(name: "CircuiteFoundation", package: "CircuiteFoundation"),
                .product(name: "DesignDatabaseCore", package: "DesignDatabase"),
                .product(name: "TimingCore", package: "TimingEngine"),
                .product(name: "LogicDesignDatabaseSchema", package: "LogicDesignDatabaseIntegration"),
                .product(name: "StandardCellLibraryDesignDatabaseSchema", package: "StandardCellLibraryDesignDatabaseIntegration"),
            ]
        ),
    ]
)
