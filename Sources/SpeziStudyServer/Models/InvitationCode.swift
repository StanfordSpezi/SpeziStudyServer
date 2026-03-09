//
// This source file is part of the SpeziStudyServer open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Fluent
import Foundation


final class InvitationCode: Model, @unchecked Sendable {
    static let schema = "invitation_codes"

    @ID(key: .id) var id: UUID?

    @Parent(key: "study_id") var study: Study

    @Field(key: "code") var code: String

    @OptionalParent(key: "enrollment_id") var enrollment: Enrollment?

    @Field(key: "issued_by") var issuedBy: String

    @OptionalField(key: "redeemed_at") var redeemedAt: Date?

    @OptionalField(key: "expires_at") var expiresAt: Date?

    @Timestamp(key: "created_at", on: .create) var createdAt: Date?

    @Timestamp(key: "updated_at", on: .update) var updatedAt: Date?

    init() {}

    init(
        studyId: UUID,
        code: String,
        issuedBy: String,
        enrollmentId: UUID? = nil,
        redeemedAt: Date? = nil,
        expiresAt: Date? = nil,
        id: UUID? = nil
    ) {
        self.id = id
        self.$study.id = studyId
        self.code = code
        self.issuedBy = issuedBy
        self.redeemedAt = redeemedAt
        self.expiresAt = expiresAt
        if let enrollmentId {
            self.$enrollment.id = enrollmentId
        }
    }
}
