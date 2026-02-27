//
// This source file is part of the SpeziStudyServer open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import Spezi


final class ComponentService: Module, @unchecked Sendable {
    @Dependency(StudyService.self) var studyService: StudyService
    @Dependency(ComponentRepository.self) var componentRepository: ComponentRepository

    func listComponents(studyId: UUID) async throws -> [Component] {
        try await studyService.checkHasAccess(to: studyId, role: .researcher)
        return try await componentRepository.findAll(studyId: studyId)
    }

    func getComponentName(studyId: UUID, componentId: UUID) async throws -> String {
        try await studyService.checkHasAccess(to: studyId, role: .researcher)

        guard let component = try await componentRepository.find(id: componentId, studyId: studyId) else {
            throw ServerError.notFound(resource: "Component", identifier: componentId.uuidString)
        }
        return component.name
    }

    func validateExists(studyId: UUID, componentId: UUID) async throws {
        guard try await componentRepository.find(id: componentId, studyId: studyId) != nil else {
            throw ServerError.notFound(resource: "Component", identifier: componentId.uuidString)
        }
    }

    func deleteComponent(studyId: UUID, componentId: UUID) async throws {
        try await studyService.checkHasAccess(to: studyId, role: .researcher)

        // Cascade delete will handle specialized table cleanup
        let deleted = try await componentRepository.delete(id: componentId, studyId: studyId)
        if !deleted {
            throw ServerError.notFound(resource: "Component", identifier: componentId.uuidString)
        }
    }
}
