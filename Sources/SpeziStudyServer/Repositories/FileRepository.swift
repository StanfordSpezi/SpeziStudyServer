//
// This source file is part of the SpeziStudyServer open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//
import Fluent
import Foundation

protocol FileRepository: VaporModule {
    func findAll(componentId: UUID) async throws -> [StoredFile]
    func findAll(studyId: UUID) async throws -> [StoredFile]
    func find(componentId: UUID, locale: String) async throws -> StoredFile?
    func find(studyId: UUID, locale: String) async throws -> StoredFile?
    func create(_ file: StoredFile) async throws -> StoredFile
    func update(_ file: StoredFile) async throws
    func delete(componentId: UUID, locale: String) async throws -> Bool
    func delete(studyId: UUID, locale: String) async throws -> Bool
}

final class DatabaseFileRepository: FileRepository {
    let database: any Database
    
    init(database: any Database) {
        self.database = database
    }

    func findAll(componentId: UUID) async throws -> [StoredFile] {
        try await StoredFile.query(on: database)
            .filter(\.$component.$id == componentId)
            .all()
    }

    func findAll(studyId: UUID) async throws -> [StoredFile] {
        try await StoredFile.query(on: database)
            .filter(\.$study.$id == studyId)
            .all()
    }

    func find(componentId: UUID, locale: String) async throws -> StoredFile? {
        try await StoredFile.query(on: database)
            .filter(\.$component.$id == componentId)
            .filter(\.$locale == locale)
            .first()
    }

    func find(studyId: UUID, locale: String) async throws -> StoredFile? {
        try await StoredFile.query(on: database)
            .filter(\.$study.$id == studyId)
            .filter(\.$locale == locale)
            .first()
    }

    func create(_ file: StoredFile) async throws -> StoredFile {
        try await file.save(on: database)

        guard let fileId = file.id,
              let createdFile = try await StoredFile.find(fileId, on: database) else {
            throw ServerError.Defaults.failedToRetrieveCreatedObject
        }

        return createdFile
    }

    func update(_ file: StoredFile) async throws {
        try await file.update(on: database)
    }

    func delete(componentId: UUID, locale: String) async throws -> Bool {
        guard let file = try await StoredFile.query(on: database)
            .filter(\.$component.$id == componentId)
            .filter(\.$locale == locale)
            .first() else {
            return false
        }

        try await file.delete(on: database)
        return true
    }

    func delete(studyId: UUID, locale: String) async throws -> Bool {
        guard let file = try await StoredFile.query(on: database)
            .filter(\.$study.$id == studyId)
            .filter(\.$locale == locale)
            .first() else {
            return false
        }

        try await file.delete(on: database)
        return true
    }
}
