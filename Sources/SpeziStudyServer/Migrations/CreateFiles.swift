//
// This source file is part of the SpeziStudyServer open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//
import Fluent

struct CreateFiles: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema("files")
            .id()
            .field("component_id", .uuid, .references("components", "id", onDelete: .cascade))
            .field("study_id", .uuid, .references("studies", "id", onDelete: .cascade))
            .field("name", .string, .required)
            .field("locale", .string, .required)
            .field("content", .string, .required)
            .field("type", .string, .required)
            .create()
    }

    func revert(on database: any Database) async throws {
        try await database.schema("files").delete()
    }
}
