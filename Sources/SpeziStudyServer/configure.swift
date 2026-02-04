//
// This source file is part of the SpeziStudyServer open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//
import Fluent
import FluentPostgresDriver
import FluentSQLiteDriver
import NIOSSL
import Spezi
import SpeziVapor
import Vapor

/// Configures the application services and routes.
public func configure(_ app: Application) async throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    if app.environment == .testing {
        app.databases.use(.sqlite(.memory), as: .psql)
    } else {
        let postgresConfiguration = SQLPostgresConfiguration(
            hostname: Environment.get("DATABASE_HOST") ?? "localhost",
            port: Environment.get("DATABASE_PORT").flatMap(Int.init(_:)) ?? SQLPostgresConfiguration.ianaPortNumber,
            username: Environment.get("DATABASE_USERNAME") ?? "vapor_username",
            password: Environment.get("DATABASE_PASSWORD") ?? "vapor_password",
            database: Environment.get("DATABASE_NAME") ?? "vapor_database",
            tls: .prefer(try .init(configuration: .clientDefault))
        )
        app.databases.use(
            DatabaseConfigurationFactory.postgres(configuration: postgresConfiguration),
            as: .psql
        )
    }

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
