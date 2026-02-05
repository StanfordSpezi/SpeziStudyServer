//
// This source file is part of the SpeziStudyServer open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//
import Fluent
@testable import SpeziStudyServer
import Vapor
import VaporTesting

/// Test application lifecycle management.
enum TestApp {
    /// Executes a test with a configured application instance.
    ///
    /// Creates an in-memory database, runs migrations, executes the test,
    /// then cleans up and shuts down the application.
    ///
    /// - Parameter test: The async test closure to execute with the configured app.
    static func withApp(_ test: @escaping @Sendable (Application) async throws -> Void) async throws {
        let app = try await Application.make(.testing)

        do {
            try await configure(app, database: .testing)
            try await app.autoMigrate()
            try await test(app)
            try await cleanup(on: app.db)
            try await app.asyncShutdown()
        } catch {
            try? await cleanup(on: app.db)
            try? await app.asyncShutdown()
            throw error
        }
    }

    private static func cleanup(on database: any Database) async throws {
        try await Study.query(on: database).delete()
    }
}
