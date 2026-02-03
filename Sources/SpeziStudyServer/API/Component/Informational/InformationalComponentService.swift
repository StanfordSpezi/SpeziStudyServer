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

    func getComponent(studyId: UUID, id: UUID) async throws -> InformationalComponent {
        try await studyService.validateExists(id: studyId)

        guard let data = try await repository.find(id: id, studyId: studyId) else {
            throw ServerError.notFound(resource: "InformationalComponent", identifier: id.uuidString)
        }

        return data
    }

    func createComponent(
        studyId: UUID,
        content: LocalizedDictionary<InformationalContent>
    ) async throws -> InformationalComponent {
        try await studyService.validateExists(id: studyId)
        return try await repository.create(studyId: studyId, data: content)
    }

    func updateComponent(
        studyId: UUID,
        id: UUID,
        content: LocalizedDictionary<InformationalContent>
    ) async throws -> InformationalComponent {
        try await studyService.validateExists(id: studyId)

        guard let data = try await repository.find(id: id, studyId: studyId) else {
            throw ServerError.notFound(resource: "InformationalComponent", identifier: id.uuidString)
        }

        data.data = content
        try await repository.update(data)

        return data
    }

    func deleteComponent(studyId: UUID, id: UUID) async throws {
        try await studyService.validateExists(id: studyId)

        let deleted = try await repository.delete(id: id, studyId: studyId)
        if !deleted {
            throw ServerError.notFound(resource: "InformationalComponent", identifier: id.uuidString)
        }
    }
}
