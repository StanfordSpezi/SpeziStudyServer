//
// This source file is part of the SpeziStudyServer open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation


extension Controller {
    func getStudiesStudyIdComponents(
        _ input: Operations.GetStudiesStudyIdComponents.Input
    ) async throws -> Operations.GetStudiesStudyIdComponents.Output {
        let studyId = try input.path.studyId.requireId()
        let components = try await componentService.listComponents(studyId: studyId)
        return .ok(.init(body: .json(try components.map { try Components.Schemas.Component($0) })))
    }

    func deleteStudiesStudyIdComponentsComponentId(
        _ input: Operations.DeleteStudiesStudyIdComponentsComponentId.Input
    ) async throws -> Operations.DeleteStudiesStudyIdComponentsComponentId.Output {
        let studyId = try input.path.studyId.requireId()
        let componentId = try input.path.componentId.requireId()
        try await componentService.deleteComponent(studyId: studyId, componentId: componentId)
        return .noContent(.init())
    }
}
