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
    case postgres
    case inMemory

    public func configure(for app: Application) throws {
        switch self {
        case .inMemory:
            app.databases.use(.sqlite(.memory), as: .psql)

        case .postgres:
            let sqlConfig = SQLPostgresConfiguration(
                hostname: try Environment.require("DATABASE_HOST"),
                port: Environment.get("DATABASE_PORT").flatMap(Int.init) ?? SQLPostgresConfiguration.ianaPortNumber,
                username: try Environment.require("DATABASE_USERNAME"),
                password: try Environment.require("DATABASE_PASSWORD"),
                database: try Environment.require("DATABASE_NAME"),
                tls: .prefer(try .init(configuration: .clientDefault))
            )
            app.databases.use(.postgres(configuration: sqlConfig), as: .psql)
        }
    }
}
