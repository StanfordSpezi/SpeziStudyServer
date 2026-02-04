//
// This source file is part of the SpeziStudyServer open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//
import Foundation

extension Controller {
    func postStudiesIdComponentsQuestionnaire(
        _ input: Operations.PostStudiesIdComponentsQuestionnaire.Input
    ) async throws -> Operations.PostStudiesIdComponentsQuestionnaire.Output {
        let studyId = try input.path.id.requireID()
        guard case .json(let content) = input.body else {
            throw ServerError.Defaults.jsonBodyRequired
        }

        let created = try await questionnaireComponentService.createComponent(
            studyId: studyId,
            name: content.name,
            content: content.data
        )

        let response = Components.Schemas.QuestionnaireComponentResponse(
            id: try created.requireID().uuidString,
            name: content.name,
            data: created.data
        )
        return .created(.init(body: .json(response)))
    }

    func getStudiesIdComponentsQuestionnaireComponentId(
        _ input: Operations.GetStudiesIdComponentsQuestionnaireComponentId.Input
    ) async throws -> Operations.GetStudiesIdComponentsQuestionnaireComponentId.Output {
        let studyId = try input.path.id.requireID()
        let componentId = try input.path.componentId.requireID()

        let component = try await questionnaireComponentService.getComponent(
            studyId: studyId,
            id: componentId
        )

        let name = try await questionnaireComponentService.getName(studyId: studyId, id: componentId) ?? ""

        let response = Components.Schemas.QuestionnaireComponentResponse(
            id: try component.requireID().uuidString,
            name: name,
            data: component.data
        )
        return .ok(.init(body: .json(response)))
    }

    func putStudiesIdComponentsQuestionnaireComponentId(
        _ input: Operations.PutStudiesIdComponentsQuestionnaireComponentId.Input
    ) async throws -> Operations.PutStudiesIdComponentsQuestionnaireComponentId.Output {
        let studyId = try input.path.id.requireID()
        let componentId = try input.path.componentId.requireID()

        guard case .json(let content) = input.body else {
            throw ServerError.Defaults.jsonBodyRequired
        }

        let updated = try await questionnaireComponentService.updateComponent(
            studyId: studyId,
            id: componentId,
            name: content.name,
            content: content.data
        )

        let response = Components.Schemas.QuestionnaireComponentResponse(
            id: try updated.requireID().uuidString,
            name: content.name,
            data: updated.data
        )
        return .ok(.init(body: .json(response)))
    }
}
