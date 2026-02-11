//
// This source file is part of the SpeziStudyServer open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Fluent


struct CreateStudy: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema("studies")
            .id()
            .field("title", .json, .required)
            .field("locales", .array(of: .string), .required)
            .field("icon", .string, .required)
            .field("details", .json, .required)
            .field("participation_criterion", .json, .required)
            .field(
                "group_id",
                .uuid,
                .required,
                .references("groups", "id", onDelete: .cascade)
            )
            .create()
    }

    func revert(on database: any Database) async throws {
        try await database.schema("studies").delete()
    }
}
