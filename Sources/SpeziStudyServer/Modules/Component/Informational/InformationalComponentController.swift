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
        guard case .json(let schema) = input.body else {
            throw ServerError.Defaults.jsonBodyRequired
        }

        let component = try await informationalComponentService.createComponent(
            studyId: studyId,
            name: schema.name,
            content: schema.data
        )

        return .created(.init(body: .json(try .init(component, name: schema.name))))
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

        let name = try await componentService.getComponentName(studyId: studyId, componentId: componentId)

        return .ok(.init(body: .json(try .init(component, name: name))))
    }

    func putStudiesStudyIdComponentsInformationalComponentId(
        _ input: Operations.PutStudiesStudyIdComponentsInformationalComponentId.Input
    ) async throws -> Operations.PutStudiesStudyIdComponentsInformationalComponentId.Output {
        let studyId = try input.path.studyId.requireId()
        let componentId = try input.path.componentId.requireId()

        guard case .json(let schema) = input.body else {
            throw ServerError.Defaults.jsonBodyRequired
        }

        let component = try await informationalComponentService.updateComponent(
            studyId: studyId,
            id: componentId,
            name: schema.name,
            content: schema.data
        )

        return .ok(.init(body: .json(try .init(component, name: schema.name))))
    }
}
