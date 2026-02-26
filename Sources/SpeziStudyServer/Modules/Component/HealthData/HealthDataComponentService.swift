//
// This source file is part of the SpeziStudyServer open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import Spezi
import SpeziStudyDefinition


final class HealthDataComponentService: Module, @unchecked Sendable {
    @Dependency(StudyService.self) var studyService: StudyService
    @Dependency(HealthDataComponentRepository.self) var repository: HealthDataComponentRepository
    @Dependency(ComponentRepository.self) var componentRepository: ComponentRepository

    func getComponent(studyId: UUID, id: UUID) async throws -> HealthDataComponent {
        try await studyService.checkHasAccess(to: studyId, role: .researcher)

        guard try await componentRepository.find(id: id, studyId: studyId) != nil else {
            throw ServerError.notFound(resource: "HealthDataComponent", identifier: id.uuidString)
        }

        guard let component = try await repository.find(id: id) else {
            throw ServerError.notFound(resource: "HealthDataComponent", identifier: id.uuidString)
        }

        return component
    }

    func createComponent(
        studyId: UUID,
        name: String,
        data: StudyDefinition.HealthDataCollectionComponent
    ) async throws -> HealthDataComponent {
        try await studyService.checkHasAccess(to: studyId, role: .researcher)

        let component = try await componentRepository.create(
            studyId: studyId,
            type: .healthDataCollection,
            name: name
        )

        return try await repository.create(componentId: try component.requireId(), data: data)
    }

    func updateComponent(
        studyId: UUID,
        id: UUID,
        name: String,
        data: StudyDefinition.HealthDataCollectionComponent
    ) async throws -> HealthDataComponent {
        try await studyService.checkHasAccess(to: studyId, role: .researcher)

        guard let component = try await componentRepository.find(id: id, studyId: studyId) else {
            throw ServerError.notFound(resource: "HealthDataComponent", identifier: id.uuidString)
        }

        guard let healthDataComponent = try await repository.find(id: id) else {
            throw ServerError.notFound(resource: "HealthDataComponent", identifier: id.uuidString)
        }

        component.name = name
        try await componentRepository.update(component)

        healthDataComponent.data = data
        try await repository.update(healthDataComponent)

        return healthDataComponent
    }
}
