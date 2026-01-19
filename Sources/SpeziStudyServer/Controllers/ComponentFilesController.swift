//
// This source file is part of the SpeziStudyServer open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation

extension Controller {
    func getStudiesIdComponentsComponentIdFiles(
        _ input: Operations.GetStudiesIdComponentsComponentIdFiles.Input
    ) async throws -> Operations.GetStudiesIdComponentsComponentIdFiles.Output {
        let studyUUID = try input.path.id.toUUID()
        let componentUUID = try input.path.componentId.toUUID()

        let dtos = try await componentFileService.listFiles(
            studyId: studyUUID,
            componentId: componentUUID
        )
        return .ok(.init(body: .json(dtos)))
    }

    func postStudiesIdComponentsComponentIdFiles(
        _ input: Operations.PostStudiesIdComponentsComponentIdFiles.Input
    ) async throws -> Operations.PostStudiesIdComponentsComponentIdFiles.Output {
        let studyUUID = try input.path.id.toUUID()
        let componentUUID = try input.path.componentId.toUUID()

        guard case .json(let fileDTO) = input.body else {
            throw ServerError.defaults.jsonBodyRequired
        }

        let responseDTO = try await componentFileService.createFile(
            studyId: studyUUID,
            componentId: componentUUID,
            dto: fileDTO
        )
        return .created(.init(body: .json(responseDTO)))
    }

    func getStudiesIdComponentsComponentIdFilesLocale(
        _ input: Operations.GetStudiesIdComponentsComponentIdFilesLocale.Input
    ) async throws -> Operations.GetStudiesIdComponentsComponentIdFilesLocale.Output {
        let studyUUID = try input.path.id.toUUID()
        let componentUUID = try input.path.componentId.toUUID()
        let locale = input.path.locale

        let dto = try await componentFileService.getFile(
            studyId: studyUUID,
            componentId: componentUUID,
            locale: locale
        )
        return .ok(.init(body: .json(dto)))
    }

    func putStudiesIdComponentsComponentIdFilesLocale(
        _ input: Operations.PutStudiesIdComponentsComponentIdFilesLocale.Input
    ) async throws -> Operations.PutStudiesIdComponentsComponentIdFilesLocale.Output {
        let studyUUID = try input.path.id.toUUID()
        let componentUUID = try input.path.componentId.toUUID()
        let locale = input.path.locale

        guard case .json(let fileDTO) = input.body else {
            throw ServerError.defaults.jsonBodyRequired
        }

        let responseDTO = try await componentFileService.updateFile(
            studyId: studyUUID,
            componentId: componentUUID,
            locale: locale,
            dto: fileDTO
        )
        return .ok(.init(body: .json(responseDTO)))
    }

    func deleteStudiesIdComponentsComponentIdFilesLocale(
        _ input: Operations.DeleteStudiesIdComponentsComponentIdFilesLocale.Input
    ) async throws -> Operations.DeleteStudiesIdComponentsComponentIdFilesLocale.Output {
        let studyUUID = try input.path.id.toUUID()
        let componentUUID = try input.path.componentId.toUUID()
        let locale = input.path.locale

        try await componentFileService.deleteFile(
            studyId: studyUUID,
            componentId: componentUUID,
            locale: locale
        )
        return .noContent(.init())
    }
}
