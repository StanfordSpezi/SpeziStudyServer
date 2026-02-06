//
// This source file is part of the SpeziStudyServer open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Fluent
import OpenAPIRuntime
import OpenAPIVapor
import Spezi
import SpeziVapor
import Vapor


/// Configures the application services and routes.
public func configure(
    _ app: Application,
    database: DatabaseConfiguration = .production,
    keycloak: KeycloakConfiguration = .production
) async throws {
    try database.configure(for: app)

    app.migrations.add(CreateGroups())
    app.migrations.add(CreateStudy())
    app.migrations.add(CreateComponents())
    app.migrations.add(CreateComponentSchedules())
    app.migrations.add(CreateInformationalComponents())
    app.migrations.add(CreateQuestionnaireComponents())
    app.migrations.add(CreateHealthDataComponents())

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

    if case .enabled(let config) = keycloak {
        let keycloakService = app.spezi[KeycloakService.self]
        let groups = try await keycloakService.fetchGroups(config: config)
        let groupService = app.spezi[GroupService.self]
        try await groupService.syncGroups(from: groups)
    }

    let controller = Controller(spezi: app.spezi)

    let transport = VaporTransport(routesBuilder: app)
    try controller.registerHandlers(
        on: transport,
        serverURL: URL(string: "/")!,
        middlewares: [ErrorMiddleware(logger: app.logger)]
    )
    
    app.get("health") { _ async in
        ["status": "ok"]
    }
}
