//
// This source file is part of the SpeziStudyServer open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//
import Foundation
import Logging
import Spezi

final class StudyService: @unchecked Sendable, Module {
    @Dependency(DatabaseStudyRepository.self) var repository: DatabaseStudyRepository
        
    init() {}

    func createStudy(_ dto: Components.Schemas.StudyInput) async throws -> Components.Schemas.StudyResponse {
        let study = try StudyMapper.toModel(dto)
        let createdStudy = try await repository.create(study)
        return try StudyMapper.toDTO(createdStudy)
    }

    func listStudies() async throws -> [Components.Schemas.StudyResponse] {
        let studies = try await repository.listAll()
        return try studies.map { try StudyMapper.toDTO($0) }
    }

    func getStudy(id: UUID) async throws -> Components.Schemas.StudyResponse {
        guard let study = try await repository.find(id: id) else {
            throw ServerError.notFound(resource: "Study", identifier: id.uuidString)
        }

        return try StudyMapper.toDTO(study)
    }

    func updateStudy(id: UUID, dto: Components.Schemas.StudyInput) async throws -> Components.Schemas.StudyResponse {
        let metadata = try StudyMapper.toMetadata(dto)
        guard let updatedStudy = try await repository.update(id: id, metadata: metadata) else {
            throw ServerError.notFound(resource: "Study", identifier: id.uuidString)
        }

        return try StudyMapper.toDTO(updatedStudy)
    }

    func deleteStudy(id: UUID) async throws {
        let deleted = try await repository.delete(id: id)
        if !deleted {
            throw ServerError.notFound(resource: "Study", identifier: id.uuidString)
        }
    }

    func validateExists(id: UUID) async throws {
        if try await repository.find(id: id) == nil {
            throw ServerError.notFound(resource: "Study", identifier: id.uuidString)
        }
    }
}
