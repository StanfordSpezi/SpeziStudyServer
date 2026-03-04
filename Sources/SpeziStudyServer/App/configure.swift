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
        AuthMiddleware(keyCollection: keyCollection, requiredRole: keycloakConfig.requiredRole, logger: app.logger)
    ])
}

/// Configures services and repositories.
public func configureServices(for app: Application) async {
    await app.spezi.configure {
        GroupService()
        StudyService()
        InformationalComponentService()
        QuestionnaireComponentService()
        HealthDataComponentService()
        ComponentScheduleService()
        ComponentService()
        GroupRepository(database: app.db)
        StudyRepository(database: app.db)
        ComponentRepository(database: app.db)
        InformationalComponentRepository(database: app.db)
        QuestionnaireComponentRepository(database: app.db)
        HealthDataComponentRepository(database: app.db)
        ComponentScheduleRepository(database: app.db)
    }
}

/// The API route prefix component.
let apiPrefix = "api"

/// The API version component.
let apiVersion = "v0"

/// The base path prefix for all API routes.
public let apiBasePath = "\(apiPrefix)/\(apiVersion)"

/// Registers OpenAPI routes and the health endpoint.
public func configureRoutes(for app: Application, middlewares: [any ServerMiddleware]) throws {
    let controller = Controller(spezi: app.spezi)

    let transport = VaporTransport(routesBuilder: app)
    try controller.registerHandlers(
        on: transport,
        serverURL: URL(string: "/\(apiBasePath)")!,
        middlewares: middlewares
    )

    app.get("\(apiPrefix)", "\(apiVersion)", "health") { _ async in
        ["status": "ok"]
    }
}
