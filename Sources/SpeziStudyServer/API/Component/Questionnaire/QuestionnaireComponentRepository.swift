//
// This source file is part of the SpeziStudyServer open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//
import Fluent
import Foundation
import SpeziLocalization

final class DatabaseQuestionnaireComponentRepository: QuestionnaireComponentRepository {
    let database: any Database

    init(database: any Database) {
        self.database = database
    }

    func findAll(studyId: UUID) async throws -> [QuestionnaireComponent] {
        try await QuestionnaireComponent.query(on: database)
            .filter(\.$study.$id == studyId)
            .all()
    }

    func find(id: UUID, studyId: UUID) async throws -> QuestionnaireComponent? {
        // swiftlint:disable:next first_where
        try await QuestionnaireComponent.query(on: database)
            .filter(\.$id == id)
            .filter(\.$study.$id == studyId)
            .first()
    }

    func create(
        studyId: UUID,
        data: LocalizedDictionary<QuestionnaireContent>
    ) async throws -> QuestionnaireComponent {
        let component = QuestionnaireComponent(studyId: studyId, data: data)
        try await component.save(on: database)
        return component
    }

    func update(_ component: QuestionnaireComponent) async throws {
        try await component.update(on: database)
    }

    func delete(id: UUID, studyId: UUID) async throws -> Bool {
        guard let component = try await find(id: id, studyId: studyId) else {
            return false
        }
        try await component.delete(on: database)
        return true
    }
}

protocol QuestionnaireComponentRepository: VaporModule {
    func findAll(studyId: UUID) async throws -> [QuestionnaireComponent]
    func find(id: UUID, studyId: UUID) async throws -> QuestionnaireComponent?
    func create(studyId: UUID, data: LocalizedDictionary<QuestionnaireContent>) async throws -> QuestionnaireComponent
    func update(_ component: QuestionnaireComponent) async throws
    func delete(id: UUID, studyId: UUID) async throws -> Bool
}
