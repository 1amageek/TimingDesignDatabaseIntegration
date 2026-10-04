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
        releasedDependency(named: "DesignDatabase", exactVersion: "26.812.1"),
        .package(url: "https://github.com/1amageek/TimingEngine.git", revision: "fc21d6abe40e2888e595bcb58ed76f2733497e1d"),
        .package(url: "https://github.com/1amageek/LogicDesignDatabaseIntegration.git", exact: "26.812.0"),
        .package(url: "https://github.com/1amageek/StandardCellLibraryDesignDatabaseIntegration.git", revision: "8efd484f3d013a53d5597492c82a9fb97daa10f2"),
        .package(url: "https://github.com/1amageek/ParasiticDesignDatabaseIntegration.git", revision: "22d62ec5c069ff0b5b3cf79e258d1709f933084d"),
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
