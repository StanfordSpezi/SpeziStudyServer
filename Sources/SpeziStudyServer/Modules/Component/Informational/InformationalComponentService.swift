//
// This source file is part of the SpeziStudyServer open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import Spezi
import SpeziLocalization


final class InformationalComponentService: Module, @unchecked Sendable {
    @Dependency(StudyService.self) var studyService: StudyService
    @Dependency(InformationalComponentRepository.self) var repository: InformationalComponentRepository
    @Dependency(ComponentRepository.self) var componentRepository: ComponentRepository

    func getComponent(studyId: UUID, id: UUID) async throws -> InformationalComponent {
        try await studyService.requireStudyAccess(id: studyId)

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

    func createComponent(
        studyId: UUID,
        name: String,
        content: LocalizedDictionary<InformationalContent>
    ) async throws -> InformationalComponent {
        try await studyService.requireStudyAccess(id: studyId)

        let registry = try await componentRepository.create(
            studyId: studyId,
            type: .informational,
            name: name
        )

        return try await repository.create(componentId: try registry.requireId(), data: content)
    }

    func updateComponent(
        studyId: UUID,
        id: UUID,
        name: String,
        content: LocalizedDictionary<InformationalContent>
    ) async throws -> InformationalComponent {
        try await studyService.requireStudyAccess(id: studyId)

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
