//
// This source file is part of the SpeziStudyServer open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import Spezi
import SpeziStudyDefinition


final class ParticipantEnrollmentService: Module, @unchecked Sendable {
    @Dependency(EnrollmentRepository.self) var enrollmentRepository: EnrollmentRepository
    @Dependency(ProfileService.self) var profileService: ProfileService
    @Dependency(PublishedStudyRepository.self) var publishedStudyRepository: PublishedStudyRepository
    @Dependency(InvitationCodeService.self) var invitationCodeService: InvitationCodeService
    @Dependency(StudyRepository.self) var studyRepository: StudyRepository

    init() {}

    func enroll(studyId: UUID, invitationCode: String?) async throws -> Enrollment {
        let participant = try await profileService.getProfile()
        let participantId = try participant.requireId()

        guard let latestRevision = try await publishedStudyRepository.maxRevision(forStudyId: studyId) else {
            throw ServerError.notFound(resource: "PublishedStudy", identifier: studyId.uuidString)
        }

        guard let study = try await studyRepository.find(id: studyId) else {
            throw ServerError.notFound(resource: "Study", identifier: studyId.uuidString)
        }

        if case .requiresInvitation = study.enrollmentConditions {
            guard let invitationCode else {
                throw ServerError.badRequest("This study requires an invitation code")
            }
            try await invitationCodeService.redeemInvitationCode(invitationCode, studyId: studyId)
        }

        if try await enrollmentRepository.findByParticipantAndStudy(participantId: participantId, studyId: studyId) != nil {
            throw ServerError.conflict("Already enrolled in this study")
        }

        let enrollment = Enrollment(
            participantId: participantId,
            studyId: studyId,
            currentRevision: latestRevision
        )

        let created = try await enrollmentRepository.create(enrollment)

        if case .requiresInvitation = study.enrollmentConditions {
            try await invitationCodeService.linkInvitationCode(invitationCode!, toEnrollmentId: try created.requireId(), studyId: studyId) // swiftlint:disable:this force_unwrapping
        }

        return created
    }

    func listParticipantEnrollments() async throws -> [Enrollment] {
        let participant = try await profileService.getProfile()
        return try await enrollmentRepository.listByParticipantId(try participant.requireId())
    }

    func withdraw(enrollmentId: UUID) async throws -> Enrollment {
        let participant = try await profileService.getProfile()
        let participantId = try participant.requireId()

        guard let enrollment = try await enrollmentRepository.find(id: enrollmentId) else {
            throw ServerError.notFound(resource: "Enrollment", identifier: enrollmentId.uuidString)
        }

        guard enrollment.$participant.id == participantId else {
            throw ServerError.notFound(resource: "Enrollment", identifier: enrollmentId.uuidString)
        }

        if enrollment.withdrawnAt != nil {
            throw ServerError.conflict("Already withdrawn from this study")
        }

        enrollment.withdrawnAt = Date()
        return try await enrollmentRepository.update(enrollment)
    }
}
