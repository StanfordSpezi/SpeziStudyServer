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
        try await database.schema("study_definitions")
            .id()
            .field("metadata", .json, .required)
            .create()
    }

    func revert(on database: any Database) async throws {
        try await database.schema("study_definitions").delete()
    }
}
