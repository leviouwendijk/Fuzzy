// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Fuzzy",
    products: [
        .library(
            name: "Fuzzy",
            targets: ["Fuzzy"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/leviouwendijk/Tokens.git", branch: "master"),
        .package(url: "https://github.com/leviouwendijk/Position.git", branch: "master"),
        .package(url: "https://github.com/leviouwendijk/Matching.git", branch: "master"),
        .package(url: "https://github.com/leviouwendijk/Ranking.git", branch: "master"),
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
        .testTarget(
            name: "FuzzyTests",
            dependencies: ["Fuzzy"]
        ),
    ]
)
