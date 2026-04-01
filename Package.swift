// swift-tools-version:6.2
//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import class Foundation.ProcessInfo
import PackageDescription


let package = Package(
    name: "SpeziStudyPlatformServer",
    platforms: [
        .macOS(.v26)
    ],
    dependencies: [
        // 💧 A server-side Swift web framework.
        .package(url: "https://github.com/vapor/vapor.git", from: "4.115.0"),
        // 🗄 An ORM for SQL and NoSQL databases.
        .package(url: "https://github.com/vapor/fluent.git", from: "4.9.0"),
        // 🐘 Fluent driver for Postgres.
        .package(url: "https://github.com/vapor/fluent-postgres-driver.git", from: "2.8.0"),
        // 🪶 Fluent driver for SQLite (used for testing).
        .package(url: "https://github.com/vapor/fluent-sqlite-driver.git", from: "4.6.0"),
        // 🔵 Non-blocking, event-driven networking for Swift. Used for custom executors
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.65.0"),
        // OpenAPI runtime & transport
        .package(url: "https://github.com/apple/swift-openapi-runtime.git", from: "1.7.0"),
        .package(url: "https://github.com/swift-server/swift-openapi-vapor.git", from: "1.0.0"),
        // Shared API types, client, and server stubs
        .package(url: "https://github.com/StanfordSpezi/SpeziStudyPlatform-API.git", .upToNextMinor(from: "0.0.2")),
        .package(url: "https://github.com/vapor/jwt-kit.git", from: "5.0.0"),
        .package(url: "https://github.com/weichsel/ZIPFoundation.git", from: "0.9.0"),
        .package(url: "https://github.com/StanfordSpezi/Spezi.git", from: "1.10.1"),
        .package(url: "https://github.com/StanfordSpezi/SpeziVapor.git", .upToNextMajor(from: "0.1.0")),
        .package(url: "https://github.com/StanfordSpezi/SpeziFoundation.git", from: "2.7.3"),
        .package(url: "https://github.com/StanfordSpezi/SpeziHealthKit.git", from: "1.4.0"),
        .package(url: "https://github.com/StanfordSpezi/SpeziStudy.git", from: "0.2.0")
    ] + swiftLintPackage(),
    targets: [
        .executableTarget(
            name: "SpeziStudyPlatformServer",
            dependencies: [
                .product(name: "Fluent", package: "fluent"),
                .product(name: "FluentPostgresDriver", package: "fluent-postgres-driver"),
                .product(name: "FluentSQLiteDriver", package: "fluent-sqlite-driver"),
                .product(name: "Vapor", package: "vapor"),
                .product(name: "NIOCore", package: "swift-nio"),
                .product(name: "NIOPosix", package: "swift-nio"),
                .product(name: "OpenAPIRuntime", package: "swift-openapi-runtime"),
                .product(name: "OpenAPIVapor", package: "swift-openapi-vapor"),
                .product(name: "SpeziStudyPlatformAPIServer", package: "SpeziStudyPlatform-API"),
                .product(name: "SpeziStudyDefinition", package: "SpeziStudy"),
                .product(name: "SpeziHealthKit", package: "SpeziHealthKit"),
                .product(name: "SpeziHealthKitBulkExport", package: "SpeziHealthKit"),
                .product(name: "Spezi", package: "Spezi"),
                .product(name: "SpeziVapor", package: "SpeziVapor"),
                .product(name: "JWTKit", package: "jwt-kit"),
                .product(name: "ZIPFoundation", package: "ZIPFoundation"),
                .product(name: "SpeziLocalization", package: "SpeziFoundation")
            ],
            swiftSettings: swiftSettings,
            plugins: [] + swiftLintPlugin()
        ),
        .testTarget(
            name: "SpeziStudyPlatformServerTests",
            dependencies: [
                .target(name: "SpeziStudyPlatformServer"),
                .product(name: "VaporTesting", package: "vapor"),
                .product(name: "ZIPFoundation", package: "ZIPFoundation"),
                .product(name: "OpenAPIRuntime", package: "swift-openapi-runtime"),
                .product(name: "JWTKit", package: "jwt-kit")
            ],
            swiftSettings: swiftSettings,
            plugins: [] + swiftLintPlugin()
        )
    ]
)

var swiftSettings: [SwiftSetting] {
    [
        .enableUpcomingFeature("ExistentialAny")
    ]
}

func swiftLintPlugin() -> [Target.PluginUsage] {
    // Fully quit Xcode and open again with `open --env SPEZI_DEVELOPMENT_SWIFTLINT /Applications/Xcode.app`
    if ProcessInfo.processInfo.environment["SPEZI_DEVELOPMENT_SWIFTLINT"] != nil {
        [.plugin(name: "SwiftLintBuildToolPlugin", package: "SwiftLint")]
    } else {
        []
    }
}

func swiftLintPackage() -> [PackageDescription.Package.Dependency] {
    if ProcessInfo.processInfo.environment["SPEZI_DEVELOPMENT_SWIFTLINT"] != nil {
        [.package(url: "https://github.com/realm/SwiftLint.git", from: "0.55.1")]
    } else {
        []
    }
}
