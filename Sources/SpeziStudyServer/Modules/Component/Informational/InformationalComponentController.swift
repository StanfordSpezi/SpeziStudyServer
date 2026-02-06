//
// This source file is part of the SpeziStudyServer open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation


extension Controller {
    func postStudiesStudyIdComponentsInformational(
        _ input: Operations.PostStudiesStudyIdComponentsInformational.Input
    ) async throws -> Operations.PostStudiesStudyIdComponentsInformational.Output {
        let studyId = try input.path.studyId.requireId()
        guard case .json(let content) = input.body else {
            throw ServerError.Defaults.jsonBodyRequired
        }

        let created = try await informationalComponentService.createComponent(
            studyId: studyId,
            name: content.name,
            content: content.data
        )

        let response = Components.Schemas.InformationalComponentResponse(
            id: try created.requireId().uuidString,
            name: content.name,
            data: created.data
        )
        return .created(.init(body: .json(response)))
    }

    func getStudiesStudyIdComponentsInformationalComponentId(
        _ input: Operations.GetStudiesStudyIdComponentsInformationalComponentId.Input
    ) async throws -> Operations.GetStudiesStudyIdComponentsInformationalComponentId.Output {
        let studyId = try input.path.studyId.requireId()
        let componentId = try input.path.componentId.requireId()

        let component = try await informationalComponentService.getComponent(
            studyId: studyId,
            id: componentId
        )

        let name = try await informationalComponentService.getName(studyId: studyId, id: componentId) ?? ""

        let response = Components.Schemas.InformationalComponentResponse(
            id: try component.requireId().uuidString,
            name: name,
            data: component.data
        )
        return .ok(.init(body: .json(response)))
    }

    func putStudiesStudyIdComponentsInformationalComponentId(
        _ input: Operations.PutStudiesStudyIdComponentsInformationalComponentId.Input
    ) async throws -> Operations.PutStudiesStudyIdComponentsInformationalComponentId.Output {
        let studyId = try input.path.studyId.requireId()
        let componentId = try input.path.componentId.requireId()

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
            id: try updated.requireId().uuidString,
            name: content.name,
            data: updated.data
        )
        return .ok(.init(body: .json(response)))
    }
}
