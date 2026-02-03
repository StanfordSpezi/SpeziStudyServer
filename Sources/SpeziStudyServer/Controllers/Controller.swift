//
// This source file is part of the SpeziStudyServer open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import OpenAPIRuntime
import OpenAPIVapor
import Vapor
import SpeziVapor

struct Controller: SpeziAPIProtocol {
    func deleteStudiesIdComponentsComponentId(_ input: Operations.DeleteStudiesIdComponentsComponentId.Input) async throws -> Operations.DeleteStudiesIdComponentsComponentId.Output {
        throw ServerError.Defaults.failedToConvertResponse
    }
    
    func getStudiesIdComponents(_ input: Operations.GetStudiesIdComponents.Input) async throws -> Operations.GetStudiesIdComponents.Output {
        throw ServerError.Defaults.failedToConvertResponse
    }
    
    func getStudiesIdBundle(_ input: Operations.GetStudiesIdBundle.Input) async throws -> Operations.GetStudiesIdBundle.Output {
        throw ServerError.Defaults.failedToConvertResponse
    }
    
    var spezi: SpeziVapor
    
//struct Controller {
//    let studyService: StudyService
//    let componentService: ComponentService
//    let componentFileService: ComponentFileService
//    let studyFileService: StudyFileService
//    let componentScheduleService: ComponentScheduleService
//    let downloadService: DownloadService
    
    init(spezi: SpeziVapor) {
        self.spezi = spezi
    }
}


extension Controller {
//    fileprivate var spezi: SpeziVapor {
//        application.spezi
//    }
    
    var studyService: StudyService {
        spezi[StudyService.self]
    }
    
    var componentScheduleService: ComponentScheduleService {
        spezi[ComponentScheduleService.self]
    }
}

