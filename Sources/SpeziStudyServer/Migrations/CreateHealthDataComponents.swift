//
// This source file is part of the SpeziStudyServer open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//
import Fluent

struct CreateHealthDataComponents: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema("health_data_components")
            .field("component_id", .uuid, .identifier(auto: false), .references("components", "id", onDelete: .cascade))
            .field("data", .json, .required)
            .create()
    }

    func revert(on database: any Database) async throws {
        try await database.schema("health_data_components").delete()
    }
}
