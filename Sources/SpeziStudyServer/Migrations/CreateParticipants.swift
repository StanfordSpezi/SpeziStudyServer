//
// This source file is part of the SpeziStudyServer open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Fluent


struct CreateParticipants: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema("participants")
            .id()
            .field("identity_provider_id", .string, .required)
            .unique(on: "identity_provider_id")
            .field("first_name", .string, .required)
            .field("last_name", .string, .required)
            .field("email", .string, .required)
            .field("gender", .string, .required)
            .field("date_of_birth", .date, .required)
            .field("region", .string, .required)
            .field("language", .string, .required)
            .field("phone_number", .string, .required)
            .timestamps()
            .create()
    }

    func revert(on database: any Database) async throws {
        try await database.schema("participants").delete()
    }
}
