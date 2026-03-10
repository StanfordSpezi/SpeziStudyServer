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
    private static let researcherRole = "spezistudyplatform-researcher"
    private static let participantRole = "spezistudyplatform-participant"

    enum Token: Sendable {
        /// No token — unauthenticated request.
        case none
        /// Researcher token with the given Keycloak group paths.
        case researcher(groups: [String] = ["/Test Group/admin"])
        /// Participant token with the given subject (identity provider ID).
        case participant(subject: String)
    }

    static func withApp(
        token tokenConfig: Token = .researcher(),
        _ test: @escaping @Sendable (Application, String?) async throws -> Void
    ) async throws {
        let app = try await Application.make(.testing)

        do {
            let keys = try await configureTesting(app)
            let token: String? = switch tokenConfig {
            case .none:
                nil
            case .researcher(let groups):
                try await signToken(keys: keys, subject: "researcher-test-user", roles: [researcherRole], groups: groups)
            case .participant(let subject):
                try await signToken(keys: keys, subject: subject, roles: [participantRole], groups: [])
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
        await configureServices(for: app)

        let keys = JWTKeyCollection()
        await keys.add(hmac: HMACKey(from: testSecret), digestAlgorithm: .sha256)

        let middlewares: [any ServerMiddleware] = [
            ErrorMiddleware(logger: app.logger),
            AuthMiddleware(
                keyCollection: keys,
                researcherRole: researcherRole,
                participantRole: participantRole,
                logger: app.logger
            )
        ]

        try configureRoutes(for: app, middlewares: middlewares)

        return keys
    }

    static func signToken(
        keys: JWTKeyCollection,
        subject: String = "test-user", // swiftlint:disable:this function_default_parameter_at_end
        roles: [String],
        groups: [String]
    ) async throws -> String {
        let payload = KeycloakJWTPayload(
            sub: .init(value: subject),
            exp: .init(value: Date().addingTimeInterval(3600)),
            roles: roles,
            groups: groups
        )
        return try await keys.sign(payload)
    }

    private static func cleanup(on database: any Database) async throws {
        try await InvitationCode.query(on: database).delete()
        try await PublishedStudy.query(on: database).delete()
        try await Participant.query(on: database).delete()
        try await Group.query(on: database).delete()
    }
}
