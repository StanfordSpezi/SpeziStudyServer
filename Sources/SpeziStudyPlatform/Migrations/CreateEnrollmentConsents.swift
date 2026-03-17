//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Fluent


struct CreateEnrollmentConsents: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema("enrollment_consents")
            .id()
            .field("enrollment_id", .uuid, .required, .references("enrollments", "id", onDelete: .cascade))
            .field("revision", .uint, .required)
            .field("user_responses", .json, .required)
            .field("consent_url", .string, .required)
            .timestamps()
            .unique(on: "enrollment_id", "revision")
            .create()
    }

    func revert(on database: any Database) async throws {
        try await database.schema("enrollment_consents").delete()
    }
}
