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
import Vapor

public enum DatabaseConfiguration: Sendable {
    case postgres(PostgresConfiguration)
    case inMemory

    public struct PostgresConfiguration: Sendable {
        public static let `default` = PostgresConfiguration()

        public var hostname: String = Environment.get("DATABASE_HOST") ?? "localhost"
        public var port: Int = Environment.get("DATABASE_PORT").flatMap(Int.init) ?? SQLPostgresConfiguration.ianaPortNumber
        public var username: String = Environment.get("DATABASE_USERNAME") ?? "vapor_username"
        public var password: String = Environment.get("DATABASE_PASSWORD") ?? "vapor_password"
        public var database: String = Environment.get("DATABASE_NAME") ?? "vapor_database"
    }

    public static let production = DatabaseConfiguration.postgres(.default)
    public static let testing = DatabaseConfiguration.inMemory

    public func configure(for app: Application) throws {
        switch self {
        case .inMemory:
            app.databases.use(.sqlite(.memory), as: .psql)

        case .postgres(let config):
            let sqlConfig = SQLPostgresConfiguration(
                hostname: config.hostname,
                port: config.port,
                username: config.username,
                password: config.password,
                database: config.database,
                tls: .prefer(try .init(configuration: .clientDefault))
            )
            app.databases.use(.postgres(configuration: sqlConfig), as: .psql)
        }
    }
}
