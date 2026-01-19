//
// This source file is part of the SpeziStudyServer open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation

extension Controller {
    func getStudiesIdComponents(
        _ input: Operations.GetStudiesIdComponents.Input
    ) async throws -> Operations.GetStudiesIdComponents.Output {
        let uuid = try input.path.id.toUUID()
        let dtos = try await componentService.listComponents(studyId: uuid)
        return .ok(.init(body: .json(dtos)))
    }

    func postStudiesIdComponents(
        _ input: Operations.PostStudiesIdComponents.Input
    ) async throws -> Operations.PostStudiesIdComponents.Output {
        let uuid = try input.path.id.toUUID()
        guard case .json(let componentDTO) = input.body else {
            throw ServerError.defaults.jsonBodyRequired
        }

        let responseDTO = try await componentService.createComponent(
            studyId: uuid,
            dto: componentDTO
        )
        return .created(.init(body: .json(responseDTO)))
    }

    func getStudiesIdComponentsComponentId(
        _ input: Operations.GetStudiesIdComponentsComponentId.Input
    ) async throws -> Operations.GetStudiesIdComponentsComponentId.Output {
        let studyUUID = try input.path.id.toUUID()
        let componentUUID = try input.path.componentId.toUUID()

        let dto = try await componentService.getComponent(
            id: componentUUID,
            studyId: studyUUID
        )
        return .ok(.init(body: .json(dto)))
    }

    func putStudiesIdComponentsComponentId(
        _ input: Operations.PutStudiesIdComponentsComponentId.Input
    ) async throws -> Operations.PutStudiesIdComponentsComponentId.Output {
        let studyUUID = try input.path.id.toUUID()
        let componentUUID = try input.path.componentId.toUUID()

        guard case .json(let componentDTO) = input.body else {
            throw ServerError.defaults.jsonBodyRequired
        }

        let responseDTO = try await componentService.updateComponent(
            id: componentUUID,
            studyId: studyUUID,
            dto: componentDTO
        )
        return .ok(.init(body: .json(responseDTO)))
    }

    func deleteStudiesIdComponentsComponentId(
        _ input: Operations.DeleteStudiesIdComponentsComponentId.Input
    ) async throws -> Operations.DeleteStudiesIdComponentsComponentId.Output {
        let studyUUID = try input.path.id.toUUID()
        let componentUUID = try input.path.componentId.toUUID()

        try await componentService.deleteComponent(
            id: componentUUID,
            studyId: studyUUID
        )
        return .noContent(.init())
    }
}
