//
// This source file is part of the SpeziStudyServer open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Fluent
import Foundation


/// Placeholder for consent-specific data stored as JSON.
struct ConsentData: Codable, Sendable, Hashable {
    init() {}
}


final class ConsentRecord: Model, @unchecked Sendable {
    static let schema = "consent_records"

    @ID(key: .id) var id: UUID?

    @Parent(key: "enrollment_id") var enrollment: Enrollment

    @Field(key: "revision") var revision: Int

    @Field(key: "consent_url") var consentURL: URL

    @Field(key: "consent_data") var consentData: ConsentData

    @Timestamp(key: "created_at", on: .create) var createdAt: Date?

    @Timestamp(key: "updated_at", on: .update) var updatedAt: Date?

    init() {}

    init(
        enrollmentId: UUID,
        revision: Int,
        consentURL: URL,
        consentData: ConsentData = ConsentData(),
        id: UUID? = nil
    ) {
        self.id = id
        self.$enrollment.id = enrollmentId
        self.revision = revision
        self.consentURL = consentURL
        self.consentData = consentData
    }
}
