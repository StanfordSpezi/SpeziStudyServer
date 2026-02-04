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
    func postStudiesIdComponentsHealthData(
        _ input: Operations.PostStudiesIdComponentsHealthData.Input
    ) async throws -> Operations.PostStudiesIdComponentsHealthData.Output {
        let studyId = try input.path.id.requireID()
        guard case .json(let content) = input.body else {
            throw ServerError.Defaults.jsonBodyRequired
        }
        
        let data = StudyDefinition.HealthDataCollectionComponent(
            id: UUID(),
            content.data
        )
        
        let created = try await healthDataComponentService.createComponent(
            studyId: studyId,
            name: content.name,
            data: data
        )

        let response = Components.Schemas.HealthDataComponentResponse(
            id: try created.requireID().uuidString,
            name: content.name,
            data: .init(created.data)
        )
        
        return .created(.init(body: .json(response)))
    }

    func getStudiesIdComponentsHealthDataComponentId(
        _ input: Operations.GetStudiesIdComponentsHealthDataComponentId.Input
    ) async throws -> Operations.GetStudiesIdComponentsHealthDataComponentId.Output {
        let studyId = try input.path.id.requireID()
        let componentId = try input.path.componentId.requireID()

        let component = try await healthDataComponentService.getComponent(
            studyId: studyId,
            id: componentId
        )

        let name = try await healthDataComponentService.getName(studyId: studyId, id: componentId) ?? ""

        let response = Components.Schemas.HealthDataComponentResponse(
            id: try component.requireID().uuidString,
            name: name,
            data: .init(component.data)
        )
        return .ok(.init(body: .json(response)))
    }

    func putStudiesIdComponentsHealthDataComponentId(
        _ input: Operations.PutStudiesIdComponentsHealthDataComponentId.Input
    ) async throws -> Operations.PutStudiesIdComponentsHealthDataComponentId.Output {
        let studyId = try input.path.id.requireID()
        let componentId = try input.path.componentId.requireID()

        guard case .json(let content) = input.body else {
            throw ServerError.Defaults.jsonBodyRequired
        }

        let data = StudyDefinition.HealthDataCollectionComponent(
            id: componentId,
            content.data
        )

        let updated = try await healthDataComponentService.updateComponent(
            studyId: studyId,
            id: componentId,
            name: content.name,
            data: data
        )

        let response = Components.Schemas.HealthDataComponentResponse(
            id: try updated.requireID().uuidString,
            name: content.name,
            data: .init(updated.data)
        )
        
        return .ok(.init(body: .json(response)))
    }
}
