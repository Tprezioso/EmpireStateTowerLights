// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "EmpireModule",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "CurrentTowerFeature",
            targets: ["CurrentTowerFeature"]),
        .library(
            name: "MonthlyTowerFeature",
            targets: ["MonthlyTowerFeature"]),
        .library(
            name: "Models",
            targets: ["Models"]),
        .library(
            name: "TowerViews",
            targets: ["TowerViews"])
    ],
    dependencies: [
//        .package(url: "https://github.com/pointfreeco/swift-custom-dump", from: "1.0.0"),
//        .package(url: "https://github.com/pointfreeco/swift-clocks", from: "1.0.0"),
//        .package(url: "https://github.com/pointfreeco/swift-case-paths", from: "1.0.0"),
//        .package(url: "https://github.com/apple/swift-collections", from: "1.0.4"),
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "1.2.0"),
//        .package(url: "https://github.com/pointfreeco/swift-concurrency-extras", from: "1.0.0"),
//        .package(url: "https://github.com/pointfreeco/swift-dependencies", from: "1.0.0"),
//        .package(url: "https://github.com/pointfreeco/swift-identified-collections", from: "1.0.0"),
        .package(url: "https://github.com/scinfu/swiftsoup", from: "2.6.1"),
//        .package(url: "https://github.com/airbnb/lottie-ios", from: "4.3.2"),
//        .package(url: "https://github.com/pointfreeco/swiftui-navigation", from: "1.0.0"),
//        .package(url: "https://github.com/pointfreeco/xctest-dynamic-overlay", from: "1.0.2"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(name: "Models", path: "Sources/Models"),
        .target(name: "TowerViews", dependencies: ["Models"], path: "Sources/TowerViews"),
        .target(
            name: "CurrentTowerFeature",
            dependencies: [
                .product(
                    name: "ComposableArchitecture",
                    package: "swift-composable-architecture"
                ),
                .product(
                    name: "SwiftSoup",
                    package: "swiftsoup"
                ),
                "Models",
                "TowerViews"
            ]
        ),
        .testTarget(
            name: "EmpireStateTowerCurrentLightsTest",
            dependencies:
                [
                    "CurrentTowerFeature",
                    "Models",
                    "TowerViews"
                ]
        ),
        .target(
            name: "MonthlyTowerFeature",
            dependencies: [
                .product(
                    name: "ComposableArchitecture",
                    package: "swift-composable-architecture"
                ),
                .product(
                    name: "SwiftSoup",
                    package: "swiftsoup"
                ),
                "Models",
                "TowerViews"
            ]
        ),
        .testTarget(
            name: "EmpireStateTowerMonthLightsTests", 
            dependencies:
                [
                    "MonthlyTowerFeature",
                    "Models",
                    "TowerViews"
                ]
        )
    ]
)
