//
// This source file is part of the SpeziStudyServer open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//
import Foundation
import SpeziLocalization

final class InformationalComponentService: VaporModule, @unchecked Sendable {
    @Dependency(StudyService.self) var studyService: StudyService
    @Dependency(DatabaseInformationalComponentRepository.self) var repository: DatabaseInformationalComponentRepository
    @Dependency(DatabaseComponentRepository.self) var componentRepository: DatabaseComponentRepository

    func getComponent(studyId: UUID, id: UUID) async throws -> InformationalComponent {
        // Validate component belongs to study
        guard let registry = try await componentRepository.find(id: id, studyId: studyId) else {
            throw ServerError.notFound(resource: "InformationalComponent", identifier: id.uuidString)
        }

        guard registry.type == .informational else {
            throw ServerError.notFound(resource: "InformationalComponent", identifier: id.uuidString)
        }

        guard let data = try await repository.find(id: id) else {
            throw ServerError.notFound(resource: "InformationalComponent", identifier: id.uuidString)
        }

        return data
    }

    func getName(studyId: UUID, id: UUID) async throws -> String? {
        guard let component = try await componentRepository.find(id: id, studyId: studyId) else {
            return nil
        }
        return component.name
    }

    func createComponent(
        studyId: UUID,
        name: String,
        content: LocalizedDictionary<InformationalContent>
    ) async throws -> InformationalComponent {
        try await studyService.validateExists(id: studyId)

        // Create registry entry first
        let registry = try await componentRepository.create(
            studyId: studyId,
            type: .informational,
            name: name
        )

        // Create specialized component data with same ID
        return try await repository.create(componentId: registry.id!, data: content)
    }

    func updateComponent(
        studyId: UUID,
        id: UUID,
        name: String,
        content: LocalizedDictionary<InformationalContent>
    ) async throws -> InformationalComponent {
        // Validate component belongs to study
        guard let registry = try await componentRepository.find(id: id, studyId: studyId) else {
            throw ServerError.notFound(resource: "InformationalComponent", identifier: id.uuidString)
        }

        guard registry.type == .informational else {
            throw ServerError.notFound(resource: "InformationalComponent", identifier: id.uuidString)
        }

        guard let data = try await repository.find(id: id) else {
            throw ServerError.notFound(resource: "InformationalComponent", identifier: id.uuidString)
        }

        // Update registry entry name
        registry.name = name
        try await componentRepository.update(registry)

        // Update component data
        data.data = content
        try await repository.update(data)

        return data
    }
}
