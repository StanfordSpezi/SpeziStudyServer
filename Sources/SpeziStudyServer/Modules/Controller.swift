//
// This source file is part of the SpeziStudyServer open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import OpenAPIRuntime
import OpenAPIVapor
import SpeziVapor
import Vapor


struct Controller: APIProtocol {
    private var spezi: SpeziVapor

    init(spezi: SpeziVapor) {
        self.spezi = spezi
    }
}


// MARK: - Services

extension Controller {
    var studyService: StudyService {
        spezi[StudyService.self]
    }

    var componentService: ComponentService {
        spezi[ComponentService.self]
    }

    var componentScheduleService: ComponentScheduleService {
        spezi[ComponentScheduleService.self]
    }

    var groupService: GroupService {
        spezi[GroupService.self]
    }

    var studyBundleService: StudyBundleService {
        spezi[StudyBundleService.self]
    }
}


// MARK: - Not Yet Implemented

extension Controller {
    func postStudiesStudyIdPublish(
        _ input: Operations.PostStudiesStudyIdPublish.Input
    ) async throws -> Operations.PostStudiesStudyIdPublish.Output {
        try AuthContext.requireCurrent().requireResearcher()
        throw ServerError.endpointNotImplemented
    }

    func getStudiesStudyIdPublished(
        _ input: Operations.GetStudiesStudyIdPublished.Input
    ) async throws -> Operations.GetStudiesStudyIdPublished.Output {
        try AuthContext.requireCurrent().requireResearcher()
        throw ServerError.endpointNotImplemented
    }

    func getStudiesStudyIdInvitationCodes(
        _ input: Operations.GetStudiesStudyIdInvitationCodes.Input
    ) async throws -> Operations.GetStudiesStudyIdInvitationCodes.Output {
        try AuthContext.requireCurrent().requireResearcher()
        throw ServerError.endpointNotImplemented
    }

    func postStudiesStudyIdInvitationCodes(
        _ input: Operations.PostStudiesStudyIdInvitationCodes.Input
    ) async throws -> Operations.PostStudiesStudyIdInvitationCodes.Output {
        try AuthContext.requireCurrent().requireResearcher()
        throw ServerError.endpointNotImplemented
    }

    func deleteStudiesStudyIdInvitationCodesCodeId(
        _ input: Operations.DeleteStudiesStudyIdInvitationCodesCodeId.Input
    ) async throws -> Operations.DeleteStudiesStudyIdInvitationCodesCodeId.Output {
        try AuthContext.requireCurrent().requireResearcher()
        throw ServerError.endpointNotImplemented
    }

    func getStudiesStudyIdEnrollments(
        _ input: Operations.GetStudiesStudyIdEnrollments.Input
    ) async throws -> Operations.GetStudiesStudyIdEnrollments.Output {
        try AuthContext.requireCurrent().requireResearcher()
        throw ServerError.endpointNotImplemented
    }

    // MARK: - Participant

    func getParticipantProfile(
        _ input: Operations.GetParticipantProfile.Input
    ) async throws -> Operations.GetParticipantProfile.Output {
        try AuthContext.requireCurrent().requireParticipant()
        throw ServerError.endpointNotImplemented
    }

    func postParticipantProfile(
        _ input: Operations.PostParticipantProfile.Input
    ) async throws -> Operations.PostParticipantProfile.Output {
        try AuthContext.requireCurrent().requireParticipant()
        throw ServerError.endpointNotImplemented
    }

    func putParticipantProfile(
        _ input: Operations.PutParticipantProfile.Input
    ) async throws -> Operations.PutParticipantProfile.Output {
        try AuthContext.requireCurrent().requireParticipant()
        throw ServerError.endpointNotImplemented
    }

    func getParticipantStudies(
        _ input: Operations.GetParticipantStudies.Input
    ) async throws -> Operations.GetParticipantStudies.Output {
        try AuthContext.requireCurrent().requireParticipant()
        throw ServerError.endpointNotImplemented
    }

    func postParticipantEnrollments(
        _ input: Operations.PostParticipantEnrollments.Input
    ) async throws -> Operations.PostParticipantEnrollments.Output {
        try AuthContext.requireCurrent().requireParticipant()
        throw ServerError.endpointNotImplemented
    }

    func getParticipantEnrollments(
        _ input: Operations.GetParticipantEnrollments.Input
    ) async throws -> Operations.GetParticipantEnrollments.Output {
        try AuthContext.requireCurrent().requireParticipant()
        throw ServerError.endpointNotImplemented
    }

    func postParticipantEnrollmentsEnrollmentIdWithdraw(
        _ input: Operations.PostParticipantEnrollmentsEnrollmentIdWithdraw.Input
    ) async throws -> Operations.PostParticipantEnrollmentsEnrollmentIdWithdraw.Output {
        try AuthContext.requireCurrent().requireParticipant()
        throw ServerError.endpointNotImplemented
    }

    func getParticipantEnrollmentsEnrollmentIdConsents(
        _ input: Operations.GetParticipantEnrollmentsEnrollmentIdConsents.Input
    ) async throws -> Operations.GetParticipantEnrollmentsEnrollmentIdConsents.Output {
        try AuthContext.requireCurrent().requireParticipant()
        throw ServerError.endpointNotImplemented
    }

    func postParticipantEnrollmentsEnrollmentIdConsents(
        _ input: Operations.PostParticipantEnrollmentsEnrollmentIdConsents.Input
    ) async throws -> Operations.PostParticipantEnrollmentsEnrollmentIdConsents.Output {
        try AuthContext.requireCurrent().requireParticipant()
        throw ServerError.endpointNotImplemented
    }
}
