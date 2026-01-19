//
// This source file is part of the SpeziStudyServer open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//
import Fluent
import FluentPostgresDriver
import NIOSSL
import Vapor

/// Configures the application services and routes.
public func configure(_ app: Application) async throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

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

    app.migrations.add(CreateStudy())
    app.migrations.add(CreateComponents())
    app.migrations.add(CreateComponentFiles())
    app.migrations.add(CreateComponentSchedules())

    // register routes
    try routes(app)
}
