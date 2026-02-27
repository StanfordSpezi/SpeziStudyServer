//
// This source file is part of the SpeziStudyServer open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import SpeziStudyDefinition


extension Controller {
    func postStudiesStudyIdComponentsHealthData(
        _ input: Operations.PostStudiesStudyIdComponentsHealthData.Input
    ) async throws -> Operations.PostStudiesStudyIdComponentsHealthData.Output {
        let studyId = try input.path.studyId.requireId()
        guard case .json(let schema) = input.body else {
            throw ServerError.jsonBodyRequired
        }

        let data = StudyDefinition.HealthDataCollectionComponent(
            id: UUID(),
            schema.data
        )

        let component = try await healthDataComponentService.createComponent(
            studyId: studyId,
            name: schema.name,
            data: data
        )

        return .created(.init(body: .json(try .init(component, name: schema.name))))
    }

    func getStudiesStudyIdComponentsHealthDataComponentId(
        _ input: Operations.GetStudiesStudyIdComponentsHealthDataComponentId.Input
    ) async throws -> Operations.GetStudiesStudyIdComponentsHealthDataComponentId.Output {
        let studyId = try input.path.studyId.requireId()
        let componentId = try input.path.componentId.requireId()

        let component = try await healthDataComponentService.getComponent(
            studyId: studyId,
            id: componentId
        )

        let name = try await componentService.getComponentName(studyId: studyId, componentId: componentId)

        return .ok(.init(body: .json(try .init(component, name: name))))
    }

    func putStudiesStudyIdComponentsHealthDataComponentId(
        _ input: Operations.PutStudiesStudyIdComponentsHealthDataComponentId.Input
    ) async throws -> Operations.PutStudiesStudyIdComponentsHealthDataComponentId.Output {
        let studyId = try input.path.studyId.requireId()
        let componentId = try input.path.componentId.requireId()

        guard case .json(let schema) = input.body else {
            throw ServerError.jsonBodyRequired
        }

        let data = StudyDefinition.HealthDataCollectionComponent(
            id: componentId,
            schema.data
        )

        let component = try await healthDataComponentService.updateComponent(
            studyId: studyId,
            id: componentId,
            name: schema.name,
            data: data
        )

        return .ok(.init(body: .json(try .init(component, name: schema.name))))
    }
}
