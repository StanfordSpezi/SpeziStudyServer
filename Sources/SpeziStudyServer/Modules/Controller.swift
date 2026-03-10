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

    var profileService: ProfileService {
        spezi[ProfileService.self]
    }

    var invitationCodeService: InvitationCodeService {
        spezi[InvitationCodeService.self]
    }

    var publishedStudyService: PublishedStudyService {
        spezi[PublishedStudyService.self]
    }

    var enrollmentService: EnrollmentService {
        spezi[EnrollmentService.self]
    }

    var participantEnrollmentService: ParticipantEnrollmentService {
        spezi[ParticipantEnrollmentService.self]
    }

    var consentService: ConsentService {
        spezi[ConsentService.self]
    }
}


