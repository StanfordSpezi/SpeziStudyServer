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

    func listComponents(studyId: UUID) async throws -> [Components.Schemas.Component] {
        try await studyService.requireStudyAccess(id: studyId)

        let components = try await componentRepository.findAll(studyId: studyId)
        return components.compactMap { component in
            guard let id = component.id else {
                return nil
            }
            return Components.Schemas.Component(
                id: id.uuidString,
                _type: component.type.rawValue,
                name: component.name
            )
        }
    }

    func getComponentName(studyId: UUID, componentId: UUID) async throws -> String {
        try await studyService.requireStudyAccess(id: studyId)

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
        try await studyService.requireStudyAccess(id: studyId)

        // Cascade delete will handle specialized table cleanup
        let deleted = try await componentRepository.delete(id: componentId, studyId: studyId)
        if !deleted {
            throw ServerError.notFound(resource: "Component", identifier: componentId.uuidString)
        }
    }
}
