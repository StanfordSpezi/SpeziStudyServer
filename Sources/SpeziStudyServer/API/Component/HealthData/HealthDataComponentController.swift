//
// This source file is part of the SpeziStudyServer open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//
import Foundation

extension Controller {
    func postStudiesIdComponentsHealthData(
        _ input: Operations.PostStudiesIdComponentsHealthData.Input
    ) async throws -> Operations.PostStudiesIdComponentsHealthData.Output {
        let studyId = try input.path.id.toUUID()
        guard case .json(let content) = input.body else {
            throw ServerError.Defaults.jsonBodyRequired
        }

        let created = try await healthDataComponentService.createComponent(
            studyId: studyId,
            content: content
        )

        return .created(.init(body: .json(created.data)))
    }

    func getStudiesIdComponentsHealthDataComponentId(
        _ input: Operations.GetStudiesIdComponentsHealthDataComponentId.Input
    ) async throws -> Operations.GetStudiesIdComponentsHealthDataComponentId.Output {
        let studyId = try input.path.id.toUUID()
        let componentId = try input.path.componentId.toUUID()

        let component = try await healthDataComponentService.getComponent(
            studyId: studyId,
            id: componentId
        )

        return .ok(.init(body: .json(component.data)))
    }

    func putStudiesIdComponentsHealthDataComponentId(
        _ input: Operations.PutStudiesIdComponentsHealthDataComponentId.Input
    ) async throws -> Operations.PutStudiesIdComponentsHealthDataComponentId.Output {
        let studyId = try input.path.id.toUUID()
        let componentId = try input.path.componentId.toUUID()

        guard case .json(let content) = input.body else {
            throw ServerError.Defaults.jsonBodyRequired
        }

        let updated = try await healthDataComponentService.updateComponent(
            studyId: studyId,
            id: componentId,
            content: content
        )

        return .ok(.init(body: .json(updated.data)))
    }
}
