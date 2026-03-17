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


final class ParticipantEnrollmentService: Module, @unchecked Sendable {
    @Dependency(EnrollmentRepository.self) var enrollmentRepository
    @Dependency(ProfileService.self) var profileService
    @Dependency(PublishedStudyRepository.self) var publishedStudyRepository
    @Dependency(InvitationCodeService.self) var invitationCodeService

    func enroll(studyId: UUID, invitationCode: String?) async throws -> Enrollment {
        let participant = try await profileService.getProfile()
        let participantId = try participant.requireId()

        guard let publishedStudy = try await publishedStudyRepository.findLatestPublished(forStudyId: studyId) else {
            throw ServerError.notFound(resource: "PublishedStudy", identifier: studyId.uuidString)
        }

        var invitationCodeId: UUID?
        if publishedStudy.enrollmentCondition == .requiresInvitationCode {
            guard let code = invitationCode else {
                throw ServerError.badRequest("This study requires an invitation code")
            }
            invitationCodeId = try await invitationCodeService.validateCode(code, studyId: studyId)
        }

        let enrollment = Enrollment(
            participantId: participantId,
            studyId: studyId,
            currentRevision: publishedStudy.revision,
            invitationCodeId: invitationCodeId
        )

        do {
            return try await enrollmentRepository.create(enrollment)
        } catch where (error as? any DatabaseError)?.isConstraintFailure == true {
            throw ServerError.conflict("Already enrolled in this study or invitation code has already been used")
        }
    }

    func listParticipantEnrollments() async throws -> [Enrollment] {
        let participant = try await profileService.getProfile()
        return try await enrollmentRepository.listByParticipantId(try participant.requireId())
    }

    func requireOwnedEnrollment(id enrollmentId: UUID) async throws -> Enrollment {
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

    func withdraw(enrollmentId: UUID) async throws -> Enrollment {
        let enrollment = try await requireOwnedEnrollment(id: enrollmentId)

        if enrollment.withdrawnAt != nil {
            throw ServerError.conflict("Already withdrawn from this study")
        }

        enrollment.withdrawnAt = Date()
        return try await enrollmentRepository.update(enrollment)
    }
}
