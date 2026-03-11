//
// This source file is part of the SpeziStudyServer open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import Spezi


final class ConsentService: Module, @unchecked Sendable {
    @Dependency(ConsentRepository.self) var repository
    @Dependency(ParticipantEnrollmentService.self) var participantEnrollmentService

    init() {}

    func listConsents(enrollmentId: UUID) async throws -> [EnrollmentConsent] {
        let enrollment = try await participantEnrollmentService.requireOwnedEnrollment(id: enrollmentId)
        return try await repository.listConsentRecords(enrollmentId: try enrollment.requireId())
    }

    func createConsent(enrollmentId: UUID, userResponses: UserResponses, consentURL: URL) async throws -> EnrollmentConsent {
        let enrollment = try await participantEnrollmentService.requireOwnedEnrollment(id: enrollmentId)

        let record = EnrollmentConsent(
            enrollmentId: try enrollment.requireId(),
            revision: enrollment.currentRevision,
            userResponses: userResponses,
            consentURL: consentURL
        )

        return try await repository.createConsentRecord(record)
    }
}
