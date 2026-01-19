//
// This source file is part of the SpeziStudyServer open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//
import Fluent
import OpenAPIRuntime
import OpenAPIVapor
import Vapor

func routes(_ app: Application) throws {
    app.get { _ async in
        "It works!"
    }

    let studyRepository = DatabaseStudyRepository(database: app.db)
    let componentRepository = DatabaseComponentRepository(database: app.db)
    let componentFileRepository = DatabaseComponentFileRepository(database: app.db)
    let componentScheduleRepository = DatabaseComponentScheduleRepository(database: app.db)

    let studyService = StudyService(repository: studyRepository)
    let componentService = ComponentService(
        studyRepository: studyRepository,
        componentRepository: componentRepository
    )
    let componentFileService = ComponentFileService(
        studyRepository: studyRepository,
        componentRepository: componentRepository,
        fileRepository: componentFileRepository
    )
    let componentScheduleService = ComponentScheduleService(
        studyRepository: studyRepository,
        componentRepository: componentRepository,
        scheduleRepository: componentScheduleRepository
    )
    let downloadService = DownloadService(repository: studyRepository)

    let controller = Controller(
        studyService: studyService,
        componentService: componentService,
        componentFileService: componentFileService,
        componentScheduleService: componentScheduleService,
        downloadService: downloadService
    )

    let transport = VaporTransport(routesBuilder: app)
    try controller.registerHandlers(
        on: transport,
        serverURL: URL(string: "/")!,
        middlewares: [ErrorMiddleware(logger: app.logger)]
    )
}
