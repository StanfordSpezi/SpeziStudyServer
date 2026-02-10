//
// This source file is part of the SpeziStudyServer open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation


extension Controller {
    func postStudiesStudyIdComponentsQuestionnaire(
        _ input: Operations.PostStudiesStudyIdComponentsQuestionnaire.Input
    ) async throws -> Operations.PostStudiesStudyIdComponentsQuestionnaire.Output {
        let studyId = try input.path.studyId.requireId()
        guard case .json(let content) = input.body else {
            throw ServerError.Defaults.jsonBodyRequired
        }

        let created = try await questionnaireComponentService.createComponent(
            studyId: studyId,
            name: content.name,
            content: content.data
        )

        return .created(.init(body: .json(try .init(created, name: content.name))))
    }

    func getStudiesStudyIdComponentsQuestionnaireComponentId(
        _ input: Operations.GetStudiesStudyIdComponentsQuestionnaireComponentId.Input
    ) async throws -> Operations.GetStudiesStudyIdComponentsQuestionnaireComponentId.Output {
        let studyId = try input.path.studyId.requireId()
        let componentId = try input.path.componentId.requireId()

        let component = try await questionnaireComponentService.getComponent(
            studyId: studyId,
            id: componentId
        )

        let name = try await componentService.getComponentName(studyId: studyId, componentId: componentId)

        return .ok(.init(body: .json(try .init(component, name: name))))
    }

    func putStudiesStudyIdComponentsQuestionnaireComponentId(
        _ input: Operations.PutStudiesStudyIdComponentsQuestionnaireComponentId.Input
    ) async throws -> Operations.PutStudiesStudyIdComponentsQuestionnaireComponentId.Output {
        let studyId = try input.path.studyId.requireId()
        let componentId = try input.path.componentId.requireId()

        guard case .json(let content) = input.body else {
            throw ServerError.Defaults.jsonBodyRequired
        }

        let updated = try await questionnaireComponentService.updateComponent(
            studyId: studyId,
            id: componentId,
            name: content.name,
            content: content.data
        )

        return .ok(.init(body: .json(try .init(updated, name: content.name))))
    }
}
