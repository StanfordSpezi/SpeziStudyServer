//
// This source file is part of the SpeziStudyServer open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation

extension Controller {
    func postStudiesIdComponentsInformational(
        _ input: Operations.PostStudiesIdComponentsInformational.Input
    ) async throws -> Operations.PostStudiesIdComponentsInformational.Output {
        let studyId = try input.path.id.toUUID()
        guard case .json(let content) = input.body else {
            throw ServerError.Defaults.jsonBodyRequired
        }

        let created = try await informationalComponentService.createComponent(
            studyId: studyId,
            name: content.name,
            content: content.data
        )

        let response = Components.Schemas.InformationalComponentResponse(
            id: created.id!.uuidString,
            name: content.name,
            data: created.data
        )
        return .created(.init(body: .json(response)))
    }

    func getStudiesIdComponentsInformationalComponentId(
        _ input: Operations.GetStudiesIdComponentsInformationalComponentId.Input
    ) async throws -> Operations.GetStudiesIdComponentsInformationalComponentId.Output {
        let studyId = try input.path.id.toUUID()
        let componentId = try input.path.componentId.toUUID()

        let component = try await informationalComponentService.getComponent(
            studyId: studyId,
            id: componentId
        )

        let name = try await informationalComponentService.getName(studyId: studyId, id: componentId) ?? ""

        let response = Components.Schemas.InformationalComponentResponse(
            id: component.id!.uuidString,
            name: name,
            data: component.data
        )
        return .ok(.init(body: .json(response)))
    }

    func putStudiesIdComponentsInformationalComponentId(
        _ input: Operations.PutStudiesIdComponentsInformationalComponentId.Input
    ) async throws -> Operations.PutStudiesIdComponentsInformationalComponentId.Output {
        let studyId = try input.path.id.toUUID()
        let componentId = try input.path.componentId.toUUID()

        guard case .json(let content) = input.body else {
            throw ServerError.Defaults.jsonBodyRequired
        }

        let updated = try await informationalComponentService.updateComponent(
            studyId: studyId,
            id: componentId,
            name: content.name,
            content: content.data
        )

        let response = Components.Schemas.InformationalComponentResponse(
            id: updated.id!.uuidString,
            name: content.name,
            data: updated.data
        )
        return .ok(.init(body: .json(response)))
    }
}
