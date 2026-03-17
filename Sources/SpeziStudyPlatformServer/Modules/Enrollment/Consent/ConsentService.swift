//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Fluent
import Foundation
import Spezi


final class ConsentService: Module, @unchecked Sendable {
    @Dependency(ConsentRepository.self) var repository
    @Dependency(ParticipantEnrollmentService.self) var participantEnrollmentService

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

        do {
            return try await repository.createConsentRecord(record)
        } catch where (error as? any DatabaseError)?.isConstraintFailure == true {
            throw ServerError.conflict("Consent already submitted for this enrollment revision")
        }
    }
}
