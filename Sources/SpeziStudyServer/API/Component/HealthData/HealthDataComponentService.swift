//
// This source file is part of the SpeziStudyServer open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//
import Foundation

final class HealthDataComponentService: VaporModule, @unchecked Sendable {
    @Dependency(StudyService.self) var studyService: StudyService
    @Dependency(DatabaseHealthDataComponentRepository.self) var repository: DatabaseHealthDataComponentRepository

    func getComponent(studyId: UUID, id: UUID) async throws -> HealthDataComponent {
        try await studyService.validateExists(id: studyId)

        guard let component = try await repository.find(id: id, studyId: studyId) else {
            throw ServerError.notFound(resource: "HealthDataComponent", identifier: id.uuidString)
        }

        return component
    }

    func createComponent(
        studyId: UUID,
        content: HealthDataContent
    ) async throws -> HealthDataComponent {
        try await studyService.validateExists(id: studyId)
        return try await repository.create(studyId: studyId, data: content)
    }

    func updateComponent(
        studyId: UUID,
        id: UUID,
        content: HealthDataContent
    ) async throws -> HealthDataComponent {
        try await studyService.validateExists(id: studyId)

        guard let component = try await repository.find(id: id, studyId: studyId) else {
            throw ServerError.notFound(resource: "HealthDataComponent", identifier: id.uuidString)
        }

        component.data = content
        try await repository.update(component)

        return component
    }

    func deleteComponent(studyId: UUID, id: UUID) async throws {
        try await studyService.validateExists(id: studyId)

        let deleted = try await repository.delete(id: id, studyId: studyId)
        if !deleted {
            throw ServerError.notFound(resource: "HealthDataComponent", identifier: id.uuidString)
        }
    }
}
