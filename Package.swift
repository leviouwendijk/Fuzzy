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
    ],
    dependencies: [
        .package(url: "https://github.com/swift-langs/Tokens.git", branch: "master"),
        .package(url: "https://github.com/swift-lco/Position.git", branch: "master"),
        .package(url: "https://github.com/swift-lco/Matching.git", branch: "master"),
        .package(url: "https://github.com/swift-lco/Ranking.git", branch: "master"),
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
    ]
)
