////
//// This source file is part of the SpeziStudyServer open source project
////
//// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
////
//// SPDX-License-Identifier: MIT
////
//import Foundation
//
//struct StudyFileService: Sendable {
//    let studyRepository: any StudyRepository
//    let fileRepository: any FileRepository
//
//    func listFiles(
//        studyId: UUID
//    ) async throws -> [Components.Schemas.FileResource] {
//        if try await studyRepository.find(id: studyId) == nil {
//            throw ServerError.notFound(resource: "Study", identifier: studyId.uuidString)
//        }
//
//        let files = try await fileRepository.findAll(studyId: studyId)
//        return try FileMapper.toDTO(files)
//    }
//
//    func getFile(
//        studyId: UUID,
//        locale: String
//    ) async throws -> Components.Schemas.FileResource {
//        if try await studyRepository.find(id: studyId) == nil {
//            throw ServerError.notFound(resource: "Study", identifier: studyId.uuidString)
//        }
//
//        guard let file = try await fileRepository.find(studyId: studyId, locale: locale) else {
//            throw ServerError.notFound(resource: "File", identifier: "\(studyId)/\(locale)")
//        }
//
//        return try FileMapper.toDTO(file)
//    }
//
//    func createFile(
//        studyId: UUID,
//        dto: Components.Schemas.CreateFileRequest
//    ) async throws -> Components.Schemas.FileResource {
//        if try await studyRepository.find(id: studyId) == nil {
//            throw ServerError.notFound(resource: "Study", identifier: studyId.uuidString)
//        }
//
//        let file = try FileMapper.toModel(dto, studyId: studyId)
//        let createdFile = try await fileRepository.create(file)
//
//        return try FileMapper.toDTO(createdFile)
//    }
//
//    func updateFile(
//        studyId: UUID,
//        locale: String,
//        dto: Components.Schemas.UpdateFileRequest
//    ) async throws -> Components.Schemas.FileResource {
//        if try await studyRepository.find(id: studyId) == nil {
//            throw ServerError.notFound(resource: "Study", identifier: studyId.uuidString)
//        }
//
//        guard let existingFile = try await fileRepository.find(studyId: studyId, locale: locale) else {
//            throw ServerError.notFound(resource: "File", identifier: "\(studyId)/\(locale)")
//        }
//
//        let newFile = try FileMapper.toModel(dto, locale: locale, studyId: studyId)
//        existingFile.name = newFile.name
//        existingFile.content = newFile.content
//        existingFile.type = newFile.type
//
//        try await fileRepository.update(existingFile)
//
//        return try FileMapper.toDTO(existingFile)
//    }
//
//    func deleteFile(
//        studyId: UUID,
//        locale: String
//    ) async throws {
//        if try await studyRepository.find(id: studyId) == nil {
//            throw ServerError.notFound(resource: "Study", identifier: studyId.uuidString)
//        }
//
//        let deleted = try await fileRepository.delete(studyId: studyId, locale: locale)
//        if !deleted {
//            throw ServerError.notFound(resource: "File", identifier: "\(studyId)/\(locale)")
//        }
//    }
//}
