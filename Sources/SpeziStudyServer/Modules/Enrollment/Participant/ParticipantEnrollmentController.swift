//
// This source file is part of the SpeziStudyServer open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import OpenAPIRuntime


extension Controller {
    func postParticipantEnrollments(
        _ input: Operations.PostParticipantEnrollments.Input
    ) async throws -> Operations.PostParticipantEnrollments.Output {
        guard case .json(let body) = input.body else {
            throw ServerError.jsonBodyRequired
        }
        let studyId = try body.studyId.requireId()
        let enrollment = try await participantEnrollmentService.enroll(studyId: studyId, invitationCode: body.invitationCode)
        return .created(.init(body: .json(try .init(enrollment))))
    }

    func getParticipantEnrollments(
        _ input: Operations.GetParticipantEnrollments.Input
    ) async throws -> Operations.GetParticipantEnrollments.Output {
        let enrollments = try await participantEnrollmentService.listParticipantEnrollments()
        return .ok(.init(body: .json(try enrollments.map { try .init($0) })))
    }

    func postParticipantEnrollmentsEnrollmentIdWithdraw(
        _ input: Operations.PostParticipantEnrollmentsEnrollmentIdWithdraw.Input
    ) async throws -> Operations.PostParticipantEnrollmentsEnrollmentIdWithdraw.Output {
        let enrollmentId = try input.path.enrollmentId.requireId()
        let enrollment = try await participantEnrollmentService.withdraw(enrollmentId: enrollmentId)
        return .ok(.init(body: .json(try .init(enrollment))))
    }
}
