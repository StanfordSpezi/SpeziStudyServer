//
// This source file is part of the SpeziStudyServer open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//
import Foundation
import SpeziStudyDefinition

final class HealthDataComponentService: VaporModule, @unchecked Sendable {
    @Dependency(StudyService.self) var studyService: StudyService
    @Dependency(DatabaseHealthDataComponentRepository.self) var repository: DatabaseHealthDataComponentRepository
    @Dependency(DatabaseComponentRepository.self) var componentRepository: DatabaseComponentRepository

    func getComponent(studyId: UUID, id: UUID) async throws -> HealthDataComponent {
        guard let registry = try await componentRepository.find(id: id, studyId: studyId) else {
            throw ServerError.notFound(resource: "HealthDataComponent", identifier: id.uuidString)
        }

        guard let component = try await repository.find(id: id) else {
            throw ServerError.notFound(resource: "HealthDataComponent", identifier: id.uuidString)
        }

        return component
    }

    func getName(studyId: UUID, id: UUID) async throws -> String? {
        guard let component = try await componentRepository.find(id: id, studyId: studyId) else {
            throw ServerError.notFound(resource: "HealthDataComponent", identifier: id.uuidString)
        }
        return component.name
    }

    func createComponent(
        studyId: UUID,
        name: String,
        data: StudyDefinition.HealthDataCollectionComponent
    ) async throws -> HealthDataComponent {
        try await studyService.validateExists(id: studyId)

        let component = try await componentRepository.create(
            studyId: studyId,
            type: .healthDataCollection,
            name: name
        )

        return try await repository.create(componentId: component.id!, data: data)
    }

    func updateComponent(
        studyId: UUID,
        id: UUID,
        name: String,
        data: StudyDefinition.HealthDataCollectionComponent
    ) async throws -> HealthDataComponent {
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
