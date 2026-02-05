//
// This source file is part of the SpeziStudyServer open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//
import Fluent
import Spezi
import SpeziVapor
import Vapor

/// Configures the application services and routes.
public func configure(_ app: Application, database: DatabaseConfiguration = .production) async throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    try database.configure(for: app)

    app.migrations.add(CreateStudy())
    app.migrations.add(CreateComponents())
    app.migrations.add(CreateFiles())
    app.migrations.add(CreateComponentSchedules())
    app.migrations.add(CreateInformationalComponents())
    app.migrations.add(CreateQuestionnaireComponents())
    app.migrations.add(CreateHealthDataComponents())

    await app.spezi.configure {
        StudyService()
        InformationalComponentService()
        QuestionnaireComponentService()
        HealthDataComponentService()
        ComponentService()
        StudyRepository(database: app.db)
        ComponentRepository(database: app.db)
        InformationalComponentRepository(database: app.db)
        QuestionnaireComponentRepository(database: app.db)
        HealthDataComponentRepository(database: app.db)
    }
    
    // register routes
    try routes(app)
}
