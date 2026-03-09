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
import OpenAPIVapor
import Spezi
import SpeziVapor
import Vapor


private var isServing: Bool {
    !CommandLine.arguments.dropFirst().contains(where: { $0 == "migrate" || $0 == "revert" })
}

/// Configures the application: database, migrations, and (when serving) services and routes.
public func configure(_ app: Application) async throws {
    try DatabaseConfiguration.postgres.configure(for: app)
    configureMigrations(for: app)

    guard isServing else {
        return
    }

    let keycloakConfig = try KeycloakConfiguration()
    let keycloak = KeycloakClient(client: app.client, config: keycloakConfig)
    await configureServices(for: app)

    let groups = try await keycloak.fetchGroups()
    let groupService = app.spezi[GroupService.self]
    try await groupService.syncGroups(from: groups)

    let jwks = try await keycloak.fetchJWKS()
    let keyCollection = JWTKeyCollection()
    try await keyCollection.add(jwks: jwks)

    try configureRoutes(for: app, middlewares: [
        ErrorMiddleware(logger: app.logger),
        AuthMiddleware(
            keyCollection: keyCollection,
            researcherRole: keycloakConfig.researcherRole,
            participantRole: keycloakConfig.participantRole,
            logger: app.logger
        )
    ])
}

/// Configures services and repositories.
public func configureServices(for app: Application) async {
    await app.spezi.configure {
        GroupService()
        StudyService()
        ComponentScheduleService()
        ComponentService()
        StudyBundleService()
        GroupRepository(database: app.db)
        StudyRepository(database: app.db)
        ComponentRepository(database: app.db)
        ComponentScheduleRepository(database: app.db)
    }
}

/// The base path prefix for all API routes, derived from the OpenAPI spec.
public let apiBasePath = try! String(Servers.Server1.url().path.dropFirst()) // swiftlint:disable:this force_try

/// Registers OpenAPI routes and the health endpoint.
public func configureRoutes(for app: Application, middlewares: [any ServerMiddleware]) throws {
    let controller = Controller(spezi: app.spezi)

    let transport = VaporTransport(routesBuilder: app)
    try controller.registerHandlers(
        on: transport,
        serverURL: try Servers.Server1.url(),
        middlewares: middlewares
    )

    let components = apiBasePath.split(separator: "/")
    app.get(components.map { PathComponent(stringLiteral: String($0)) } + ["health"]) { _ async in
        ["status": "ok"]
    }
}
