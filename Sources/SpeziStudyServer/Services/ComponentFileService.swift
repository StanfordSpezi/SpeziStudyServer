//
// This source file is part of the SpeziStudyServer open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//
import Foundation

struct ComponentFileService: Sendable {
    let studyRepository: any StudyRepository
    let componentRepository: any ComponentRepository
    let fileRepository: any ComponentFileRepository

    func listFiles(
        studyId: UUID,
        componentId: UUID
    ) async throws -> [Components.Schemas.ComponentFile] {
        if try await studyRepository.find(id: studyId) == nil {
            throw ServerError.notFound(resource: "Study", identifier: studyId.uuidString)
        }

        if try await componentRepository.find(id: componentId, studyId: studyId) == nil {
            throw ServerError.notFound(resource: "Component", identifier: componentId.uuidString)
        }

        let files = try await fileRepository.findAll(componentId: componentId)
        return try ComponentFileMapper.toDTO(files)
    }

    func getFile(
        studyId: UUID,
        componentId: UUID,
        locale: String
    ) async throws -> Components.Schemas.ComponentFile {
        if try await studyRepository.find(id: studyId) == nil {
            throw ServerError.notFound(resource: "Study", identifier: studyId.uuidString)
        }

        if try await componentRepository.find(id: componentId, studyId: studyId) == nil {
            throw ServerError.notFound(resource: "Component", identifier: componentId.uuidString)
        }

        guard let file = try await fileRepository.find(componentId: componentId, locale: locale) else {
            throw ServerError.notFound(resource: "File", identifier: "\(componentId)/\(locale)")
        }

        return try ComponentFileMapper.toDTO(file)
    }

    func createFile(
        studyId: UUID,
        componentId: UUID,
        dto: Components.Schemas.CreateFileRequest
    ) async throws -> Components.Schemas.ComponentFile {
        if try await studyRepository.find(id: studyId) == nil {
            throw ServerError.notFound(resource: "Study", identifier: studyId.uuidString)
        }

        if try await componentRepository.find(id: componentId, studyId: studyId) == nil {
            throw ServerError.notFound(resource: "Component", identifier: componentId.uuidString)
        }

        let file = try ComponentFileMapper.toModel(dto, componentId: componentId)
        let createdFile = try await fileRepository.create(file)

        return try ComponentFileMapper.toDTO(createdFile)
    }

    func updateFile(
        studyId: UUID,
        componentId: UUID,
        locale: String,
        dto: Components.Schemas.UpdateFileRequest
    ) async throws -> Components.Schemas.ComponentFile {
        if try await studyRepository.find(id: studyId) == nil {
            throw ServerError.notFound(resource: "Study", identifier: studyId.uuidString)
        }

        if try await componentRepository.find(id: componentId, studyId: studyId) == nil {
            throw ServerError.notFound(resource: "Component", identifier: componentId.uuidString)
        }

        guard let existingFile = try await fileRepository.find(componentId: componentId, locale: locale) else {
            throw ServerError.notFound(resource: "File", identifier: "\(componentId)/\(locale)")
        }

        let newFile = try ComponentFileMapper.toModel(dto, locale: locale, componentId: componentId)
        existingFile.name = newFile.name
        existingFile.content = newFile.content
        existingFile.type = newFile.type

        try await fileRepository.update(existingFile)

        return try ComponentFileMapper.toDTO(existingFile)
    }

    func deleteFile(
        studyId: UUID,
        componentId: UUID,
        locale: String
    ) async throws {
        if try await studyRepository.find(id: studyId) == nil {
            throw ServerError.notFound(resource: "Study", identifier: studyId.uuidString)
        }

        if try await componentRepository.find(id: componentId, studyId: studyId) == nil {
            throw ServerError.notFound(resource: "Component", identifier: componentId.uuidString)
        }

        let deleted = try await fileRepository.delete(componentId: componentId, locale: locale)
        if !deleted {
            throw ServerError.notFound(resource: "File", identifier: "\(componentId)/\(locale)")
        }
    }
}
