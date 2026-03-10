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
    @Dependency(ConsentRepository.self) var repository: ConsentRepository
    @Dependency(EnrollmentRepository.self) var enrollmentRepository: EnrollmentRepository
    @Dependency(ProfileService.self) var profileService: ProfileService

    init() {}

    func listConsents(enrollmentId: UUID) async throws -> [EnrollmentConsent] {
        let enrollment = try await requireParticipantEnrollment(enrollmentId: enrollmentId)
        return try await repository.listConsentRecords(enrollmentId: try enrollment.requireId())
    }

    func createConsent(enrollmentId: UUID, userResponses: UserResponses, consentURL: URL) async throws -> EnrollmentConsent {
        let enrollment = try await requireParticipantEnrollment(enrollmentId: enrollmentId)

        let record = EnrollmentConsent(
            enrollmentId: try enrollment.requireId(),
            revision: enrollment.currentRevision,
            userResponses: userResponses,
            consentURL: consentURL
        )

        return try await repository.createConsentRecord(record)
    }

    private func requireParticipantEnrollment(enrollmentId: UUID) async throws -> Enrollment {
        let participant = try await profileService.getProfile()
        let participantId = try participant.requireId()

        guard let enrollment = try await enrollmentRepository.find(id: enrollmentId) else {
            throw ServerError.notFound(resource: "Enrollment", identifier: enrollmentId.uuidString)
        }

        guard enrollment.$participant.id == participantId else {
            throw ServerError.notFound(resource: "Enrollment", identifier: enrollmentId.uuidString)
        }

        return enrollment
    }
}
