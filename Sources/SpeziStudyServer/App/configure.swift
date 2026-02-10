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


/// Configures the application services and routes for production.
public func configure(_ app: Application) async throws {
    try DatabaseConfiguration.production.configure(for: app)
    try await configureMigrations(for: app)
    await configureServices(for: app)

    var middlewares: [any ServerMiddleware] = [ErrorMiddleware(logger: app.logger)]

    let keycloakConfig = KeycloakConfiguration.default
    let keycloakService = app.spezi[KeycloakService.self]
    let groups = try await keycloakService.fetchGroups(config: keycloakConfig)
    let groupService = app.spezi[GroupService.self]
    try await groupService.syncGroups(from: groups)

    let jwksURL = URL(string: keycloakConfig.jwksURL)!
    let (jwksData, _) = try await URLSession.shared.data(from: jwksURL)
    let jwks = try JSONDecoder().decode(JWKS.self, from: jwksData)
    let keyCollection = JWTKeyCollection()
    try await keyCollection.add(jwks: jwks)

    middlewares.append(AuthMiddleware(keyCollection: keyCollection, requiredRole: keycloakConfig.requiredRole, logger: app.logger))

    try configureRoutes(for: app, middlewares: middlewares)
}

/// Registers all database migrations and runs auto-migrate.
public func configureMigrations(for app: Application) async throws {
    app.migrations.add(CreateGroups())
    app.migrations.add(CreateStudy())
    app.migrations.add(CreateComponents())
    app.migrations.add(CreateComponentSchedules())
    app.migrations.add(CreateInformationalComponents())
    app.migrations.add(CreateQuestionnaireComponents())
    app.migrations.add(CreateHealthDataComponents())
    try await app.autoMigrate()
}

/// Configures services and repositories.
public func configureServices(for app: Application) async {
    await app.spezi.configure {
        KeycloakService()
        GroupService()
        StudyService()
        InformationalComponentService()
        QuestionnaireComponentService()
        HealthDataComponentService()
        ComponentService()
        GroupRepository(database: app.db)
        StudyRepository(database: app.db)
        ComponentRepository(database: app.db)
        InformationalComponentRepository(database: app.db)
        QuestionnaireComponentRepository(database: app.db)
        HealthDataComponentRepository(database: app.db)
    }
}

/// Registers OpenAPI routes and the health endpoint.
public func configureRoutes(for app: Application, middlewares: [any ServerMiddleware]) throws {
    let controller = Controller(spezi: app.spezi)

    let transport = VaporTransport(routesBuilder: app)
    try controller.registerHandlers(
        on: transport,
        serverURL: URL(string: "/")!,
        middlewares: middlewares
    )

    app.get("health") { _ async in
        ["status": "ok"]
    }
}
