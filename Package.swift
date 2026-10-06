// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "Fuzzy",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "Fuzzy",
            targets: ["Fuzzy"]
        ),
        .executable(
            name: "fuzzytest",
            targets: ["FuzzyTests"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/leviouwendijk/Tokens.git", branch: "master"),
        .package(url: "https://github.com/leviouwendijk/Position.git", branch: "master"),
        .package(url: "https://github.com/leviouwendijk/Matching.git", branch: "master"),
        .package(url: "https://github.com/leviouwendijk/Ranking.git", branch: "master"),
        .package(url: "https://github.com/leviouwendijk/Testing.git", branch: "master"),
    ],
    targets: [
        .target(
            name: "Fuzzy",
            dependencies: [
                .product(name: "Tokens", package: "Tokens"),
                .product(name: "Position", package: "Position"),
                .product(name: "Matching", package: "Matching"),
                .product(name: "Ranking", package: "Ranking"),
            ],
        ),
        .executableTarget(
            name: "FuzzyTests",
            dependencies: [
                "Fuzzy",
                .product(name: "Matching", package: "Matching"),
                .product(name: "Ranking", package: "Ranking"),
                .product(name: "Tokens", package: "Tokens"),
                .product(name: "Testing", package: "Testing"),
            ],
            path: "Testing/FuzzyTests"
        ),
    ]
)
