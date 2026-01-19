//
// This source file is part of the SpeziStudyServer open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//
import Fluent

struct CreateComponentFiles: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema("component_files")
            .id()
            .field("component_id", .uuid, .required, .references("components", "id", onDelete: .cascade))
            .field("name", .string, .required)
            .field("locale", .string, .required)
            .field("content", .string, .required)
            .field("type", .string, .required)
            .unique(on: "component_id", "locale")
            .create()
    }

    func revert(on database: any Database) async throws {
        try await database.schema("component_files").delete()
    }
}
