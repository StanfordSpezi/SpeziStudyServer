//
// This source file is part of the SpeziStudyServer open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Fluent


struct CreateConsentRecords: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema("consent_records")
            .id()
            .field("enrollment_id", .uuid, .required, .references("enrollments", "id", onDelete: .cascade))
            .field("revision", .int, .required)
            .field("consent_url", .string, .required)
            .field("consent_data", .json, .required)
            .timestamps()
            .unique(on: "enrollment_id", "revision")
            .create()
    }

    func revert(on database: any Database) async throws {
        try await database.schema("consent_records").delete()
    }
}
