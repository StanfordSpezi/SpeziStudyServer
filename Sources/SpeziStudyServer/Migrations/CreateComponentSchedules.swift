//
// This source file is part of the SpeziStudyServer open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//
import Fluent

struct CreateComponentSchedules: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema("component_schedules")
            .id()
            .field("component_id", .uuid, .required, .references("components", "id", onDelete: .cascade))
            .field("schedule_data", .json, .required)
            .create()
    }

    func revert(on database: any Database) async throws {
        try await database.schema("component_schedules").delete()
    }
}
