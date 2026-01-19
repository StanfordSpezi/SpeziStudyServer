//
// This source file is part of the SpeziStudyServer open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//
import Fluent
import Foundation

struct DatabaseComponentFileRepository: ComponentFileRepository {
    let database: any Database

    func findAll(componentId: UUID) async throws -> [ComponentFile] {
        try await ComponentFile.query(on: database)
            .filter(\.$component.$id == componentId)
            .all()
    }

    func find(componentId: UUID, locale: String) async throws -> ComponentFile? {
        try await ComponentFile.query(on: database)
            .filter(\.$component.$id == componentId)
            .filter(\.$locale == locale)
            .first()
    }

    func create(_ file: ComponentFile) async throws -> ComponentFile {
        try await file.save(on: database)

        guard let fileId = file.id,
              let createdFile = try await ComponentFile.find(fileId, on: database) else {
            throw ServerError.defaults.failedToRetrieveCreatedObject
        }

        return createdFile
    }

    func update(_ file: ComponentFile) async throws {
        try await file.update(on: database)
    }

    func delete(componentId: UUID, locale: String) async throws -> Bool {
        guard let file = try await ComponentFile.query(on: database)
            .filter(\.$component.$id == componentId)
            .filter(\.$locale == locale)
            .first() else {
            return false
        }

        try await file.delete(on: database)
        return true
    }
}

protocol ComponentFileRepository: Sendable {
    func findAll(componentId: UUID) async throws -> [ComponentFile]
    func find(componentId: UUID, locale: String) async throws -> ComponentFile?
    func create(_ file: ComponentFile) async throws -> ComponentFile
    func update(_ file: ComponentFile) async throws
    func delete(componentId: UUID, locale: String) async throws -> Bool
}
