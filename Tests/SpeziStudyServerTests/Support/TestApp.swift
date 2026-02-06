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


enum TestApp {
    static func withApp(_ test: @escaping @Sendable (Application) async throws -> Void) async throws {
        let app = try await Application.make(.testing)

        do {
            try await configure(app, database: .testing, keycloak: .disabled)
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
        try await Group.query(on: database).delete()
    }
}
