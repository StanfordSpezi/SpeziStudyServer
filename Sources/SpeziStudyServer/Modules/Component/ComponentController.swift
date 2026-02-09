//
// This source file is part of the SpeziStudyServer open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//
import Foundation

extension Controller {
    func getStudiesIdComponents(
        _ input: Operations.GetStudiesIdComponents.Input
    ) async throws -> Operations.GetStudiesIdComponents.Output {
        let studyId = try input.path.id.requireID()
        let components = try await componentService.listComponents(studyId: studyId)
        return .ok(.init(body: .json(components)))
    }

    func deleteStudiesIdComponentsComponentId(
        _ input: Operations.DeleteStudiesIdComponentsComponentId.Input
    ) async throws -> Operations.DeleteStudiesIdComponentsComponentId.Output {
        let studyId = try input.path.id.requireID()
        let componentId = try input.path.componentId.requireID()
        try await componentService.deleteComponent(studyId: studyId, componentId: componentId)
        return .noContent(.init())
    }
}
