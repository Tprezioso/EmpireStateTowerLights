// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "EmpireModule",
    platforms: [
        .iOS(.v17),
        .watchOS(.v10)
    ],
    products: [
        .library(name: "AppFeature", targets: ["AppFeature"]),
        .library(name: "AboutFeature", targets: ["AboutFeature"]),
        .library(name: "TowerWidgetKit", targets: ["TowerWidgetKit"]),
        .library(name: "WatchFeature", targets: ["WatchFeature"]),
        .library(name: "CurrentTowerFeature", targets: ["CurrentTowerFeature"]),
        .library(name: "MonthlyTowerFeature", targets: ["MonthlyTowerFeature"]),
        .library(name: "TowerClient", targets: ["TowerClient"]),
        .library(name: "DesignSystem", targets: ["DesignSystem"]),
        .library(name: "Models", targets: ["Models"])
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "1.26.0"),
        .package(url: "https://github.com/pointfreeco/swift-dependencies", from: "1.17.0"),
        .package(url: "https://github.com/scinfu/swiftsoup", from: "2.7.0"),
        // Not used directly. These floors keep older releases, which still reference the
        // pre-rename xctest-dynamic-overlay package, out of the graph.
        .package(url: "https://github.com/pointfreeco/combine-schedulers", from: "1.2.2"),
        .package(url: "https://github.com/pointfreeco/swift-clocks", from: "1.1.1")
    ],
    targets: [
        .target(name: "Models", path: "Sources/Models"),
        .target(
            name: "TowerClient",
            dependencies: [
                "Models",
                .product(name: "Dependencies", package: "swift-dependencies"),
                .product(name: "DependenciesMacros", package: "swift-dependencies"),
                .product(name: "SwiftSoup", package: "swiftsoup")
            ]
        ),
        .target(name: "DesignSystem", dependencies: ["Models"]),
        .target(name: "TowerWidgetKit", dependencies: ["DesignSystem", "Models", "TowerClient"]),
        .target(
            name: "CurrentTowerFeature",
            dependencies: [
                "DesignSystem",
                "Models",
                "TowerClient",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
            ]
        ),
        .target(
            name: "MonthlyTowerFeature",
            dependencies: [
                "DesignSystem",
                "Models",
                "TowerClient",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
            ]
        ),
        .target(
            name: "AboutFeature",
            dependencies: [
                "DesignSystem",
                "Models",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
            ],
            resources: [.process("Resources")]
        ),
        .target(
            name: "AppFeature",
            dependencies: [
                "AboutFeature",
                "CurrentTowerFeature",
                "MonthlyTowerFeature",
                "DesignSystem",
                "TowerClient",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
            ]
        ),
        .target(
            name: "WatchFeature",
            dependencies: [
                "CurrentTowerFeature",
                "MonthlyTowerFeature",
                "DesignSystem",
                "Models",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
            ]
        ),
        .testTarget(
            name: "TowerClientTests",
            dependencies: ["TowerClient", "Models"],
            resources: [.copy("Fixtures")]
        ),
        .testTarget(
            name: "CurrentTowerFeatureTests",
            dependencies: ["CurrentTowerFeature", "TowerClient", "Models"]
        ),
        .testTarget(
            name: "AboutFeatureTests",
            dependencies: ["AboutFeature"]
        ),
        .testTarget(
            name: "AppFeatureTests",
            dependencies: ["AppFeature", "Models"]
        ),
        .testTarget(
            name: "MonthlyTowerFeatureTests",
            dependencies: ["MonthlyTowerFeature", "TowerClient", "Models"]
        )
    ]
)
