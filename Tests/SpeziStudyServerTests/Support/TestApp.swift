//
// This source file is part of the SpeziStudyServer open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Fluent
import JWTKit
import OpenAPIRuntime
@testable import SpeziStudyServer
import Vapor
import VaporTesting


enum TestApp {
    private static let testSecret = "test-hmac-secret-for-jwt-signing"
    private static let requiredRole = "spezistudyplatform-authorized-users"

    static func withApp( // swiftlint:disable:next discouraged_optional_collection
        groups: [String]? = ["/Test Group/admin"],
        _ test: @escaping @Sendable (Application, String?) async throws -> Void
    ) async throws {
        let app = try await Application.make(.testing)

        do {
            let keys = try await configureTesting(app)
            let token: String? = if let groups {
                try await signToken(keys: keys, roles: [requiredRole], groups: groups)
            } else {
                nil
            }
            try await test(app, token)
            try await cleanup(on: app.db)
            try await app.asyncShutdown()
        } catch {
            try? await cleanup(on: app.db)
            try? await app.asyncShutdown()
            throw error
        }
    }

    private static func configureTesting(_ app: Application) async throws -> JWTKeyCollection {
        try DatabaseConfiguration.inMemory.configure(for: app)
        configureMigrations(for: app)
        try await app.autoMigrate()
        await configureServices(for: app, client: app.client, keycloakConfig: .default)

        let keys = JWTKeyCollection()
        await keys.add(hmac: HMACKey(from: testSecret), digestAlgorithm: .sha256)

        let middlewares: [any ServerMiddleware] = [
            ErrorMiddleware(logger: app.logger),
            AuthMiddleware(keyCollection: keys, requiredRole: requiredRole, logger: app.logger)
        ]

        try configureRoutes(for: app, middlewares: middlewares)

        return keys
    }

    static func signToken(
        keys: JWTKeyCollection,
        roles: [String],
        groups: [String]
    ) async throws -> String {
        let payload = KeycloakJWTPayload(
            exp: .init(value: Date().addingTimeInterval(3600)),
            roles: roles,
            groups: groups
        )
        return try await keys.sign(payload)
    }

    private static func cleanup(on database: any Database) async throws {
        try await Group.query(on: database).delete()
    }
}
