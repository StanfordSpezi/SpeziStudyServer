//
// This source file is part of the SpeziStudyServer open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//
import Fluent
import Foundation
import SpeziStudyDefinition

struct DatabaseStudyRepository: StudyRepository {
    let database: any Database

    func create(_ study: Study) async throws -> Study {
        try await study.save(on: database)

        guard let createdStudy = try await Study.query(on: database)
            .filter(\.$id == study.id!)
            .first() else {
            throw ServerError.defaults.failedToRetrieveCreatedObject
        }

        return createdStudy
    }

    func find(id: UUID) async throws -> Study? {
        try await Study.find(id, on: database)
    }

    func findWithComponents(id: UUID) async throws -> Study? {
        try await Study.query(on: database)
            .filter(\.$id == id)
            .with(\.$components)
            .first()
    }

    func findWithComponentsAndFiles(id: UUID) async throws -> Study {
        guard let study = try await Study.query(on: database)
            .filter(\.$id == id)
            .with(\.$components)
            .first() else {
            throw ServerError.notFound(resource: "Study", identifier: id.uuidString)
        }

        for component in study.components {
            try await component.$componentFiles.load(on: database)
            try await component.$schedules.load(on: database)
        }

        return study
    }

    func listIds() async throws -> [UUID] {
        try await Study.query(on: database).all(\.$id)
    }

    func listAll() async throws -> [Study] {
        try await Study.query(on: database).all()
    }

    func update(id: UUID, metadata: StudyDefinition.Metadata) async throws -> Study? {
        guard let study = try await Study.find(id, on: database) else {
            return nil
        }

        study.metadata = metadata
        try await study.save(on: database)
        return study
    }

    func delete(id: UUID) async throws -> Bool {
        guard let study = try await Study.find(id, on: database) else {
            return false
        }

        try await study.delete(on: database)
        return true
    }
}

protocol StudyRepository: Sendable {
    func create(_ study: Study) async throws -> Study
    func find(id: UUID) async throws -> Study?
    func findWithComponents(id: UUID) async throws -> Study?
    func findWithComponentsAndFiles(id: UUID) async throws -> Study
    func listIds() async throws -> [UUID]
    func listAll() async throws -> [Study]
    func update(id: UUID, metadata: StudyDefinition.Metadata) async throws -> Study?
    func delete(id: UUID) async throws -> Bool
}
