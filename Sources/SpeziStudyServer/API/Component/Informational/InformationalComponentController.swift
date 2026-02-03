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
            content: content
        )

        return .created(.init(body: .json(created.data)))
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

        return .ok(.init(body: .json(component.data)))
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
            content: content
        )

        return .ok(.init(body: .json(updated.data)))
    }
}
