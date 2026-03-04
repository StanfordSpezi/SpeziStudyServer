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

    func getStudiesStudyIdBundle(_ input: Operations.GetStudiesStudyIdBundle.Input) async throws -> Operations.GetStudiesStudyIdBundle.Output {
        throw ServerError.endpointNotImplemented
    }
}


extension Controller {
    var studyService: StudyService {
        spezi[StudyService.self]
    }

    var informationalComponentService: InformationalComponentService {
        spezi[InformationalComponentService.self]
    }

    var questionnaireComponentService: QuestionnaireComponentService {
        spezi[QuestionnaireComponentService.self]
    }

    var healthDataComponentService: HealthDataComponentService {
        spezi[HealthDataComponentService.self]
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
}
