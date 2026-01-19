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

struct Controller: APIProtocol {
    let studyService: StudyService
    let componentService: ComponentService
    let componentFileService: ComponentFileService
    let componentScheduleService: ComponentScheduleService
    let downloadService: DownloadService
}
