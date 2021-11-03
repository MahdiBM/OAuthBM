// swift-tools-version:5.5

import PackageDescription

let package = Package(
    name: "OAuthBM",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .library(name: "OAuthBM", targets: ["OAuthBM"]),
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "4.0.0"),
        .package(url: "https://github.com/vapor/fluent.git", from: "4.0.0"),
        .package(url: "https://github.com/vapor/fluent-postgres-driver.git", from: "2.0.0"),
    ],
    targets: [
        .target(
            name: "OAuthBM",
            dependencies: [
                .product(name: "Fluent", package: "fluent"),
                .product(name: "FluentPostgresDriver", package: "fluent-postgres-driver"),
                .product(name: "Vapor", package: "vapor"),
            ]
        ),
    ]
)
