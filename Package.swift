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
        releasedDependency(named: "CircuiteFoundation", exactVersion: "26.812.0"),
        .package(url: "https://github.com/1amageek/DesignDatabase.git", revision: "78f1c2e28e804e7c750014827e9f18c88c2272e3"),
        .package(url: "https://github.com/1amageek/TimingEngine.git", revision: "087143be22e5c54283bfabc590067aa23203ee6a"),
        .package(url: "https://github.com/1amageek/LogicDesignDatabaseIntegration.git", revision: "3a90516c438c497dc5be1d3665fde6fea7e9f07d"),
        .package(url: "https://github.com/1amageek/StandardCellLibraryDesignDatabaseIntegration.git", revision: "0d25766b3add533959f73d623d56a5388274aa6d"),
        .package(url: "https://github.com/1amageek/ParasiticDesignDatabaseIntegration.git", revision: "4fd4fe6c1c76c837bdf44048d8a26f86b5777d6e"),
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
