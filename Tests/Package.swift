// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "FuzzyTests",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "fuzzytest",
            targets: ["FuzzyTests"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/swift-langs/Tokens.git", branch: "master"),
        .package(url: "https://github.com/swift-lco/Matching.git", branch: "master"),
        .package(url: "https://github.com/swift-lco/Ranking.git", branch: "master"),
        .package(url: "https://github.com/swift-tooling/Testing.git", branch: "master"),
        .package(path: ".."),
    ],
    targets: [
        .executableTarget(
            name: "FuzzyTests",
            dependencies: [
                .product(name: "Fuzzy", package: "Fuzzy"),
                .product(name: "Matching", package: "Matching"),
                .product(name: "Ranking", package: "Ranking"),
                .product(name: "Tokens", package: "Tokens"),
                .product(name: "Testing", package: "Testing"),
            ]
        ),
    ]
)
