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
        let studyId = try input.path.id.toUUID()
        guard case .json(let content) = input.body else {
            throw ServerError.Defaults.jsonBodyRequired
        }

        let created = try await questionnaireComponentService.createComponent(
            studyId: studyId,
            content: content
        )

        return .created(.init(body: .json(created.data)))
    }

    func getStudiesIdComponentsQuestionnaireComponentId(
        _ input: Operations.GetStudiesIdComponentsQuestionnaireComponentId.Input
    ) async throws -> Operations.GetStudiesIdComponentsQuestionnaireComponentId.Output {
        let studyId = try input.path.id.toUUID()
        let componentId = try input.path.componentId.toUUID()

        let component = try await questionnaireComponentService.getComponent(
            studyId: studyId,
            id: componentId
        )

        return .ok(.init(body: .json(component.data)))
    }

    func putStudiesIdComponentsQuestionnaireComponentId(
        _ input: Operations.PutStudiesIdComponentsQuestionnaireComponentId.Input
    ) async throws -> Operations.PutStudiesIdComponentsQuestionnaireComponentId.Output {
        let studyId = try input.path.id.toUUID()
        let componentId = try input.path.componentId.toUUID()

        guard case .json(let content) = input.body else {
            throw ServerError.Defaults.jsonBodyRequired
        }

        let updated = try await questionnaireComponentService.updateComponent(
            studyId: studyId,
            id: componentId,
            content: content
        )

        return .ok(.init(body: .json(updated.data)))
    }
}
