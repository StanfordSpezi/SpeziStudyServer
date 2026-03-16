//
// This source file is part of the SpeziStudyServer open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Fluent
import Foundation
import Spezi


final class ConsentRepository: Module, Sendable {
    let database: any Database

    init(database: any Database) {
        self.database = database
    }

    func listConsentRecords(enrollmentId: UUID) async throws -> [EnrollmentConsent] {
        try await EnrollmentConsent.query(on: database)
            .filter(\.$enrollment.$id == enrollmentId)
            .all()
    }

    func createConsentRecord(_ record: EnrollmentConsent) async throws -> EnrollmentConsent {
        try await record.save(on: database)
        return record
    }
}
