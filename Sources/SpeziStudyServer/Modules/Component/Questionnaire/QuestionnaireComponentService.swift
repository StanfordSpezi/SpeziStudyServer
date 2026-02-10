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


final class QuestionnaireComponentService: Module, @unchecked Sendable {
    @Dependency(StudyService.self) var studyService: StudyService
    @Dependency(QuestionnaireComponentRepository.self) var repository: QuestionnaireComponentRepository
    @Dependency(ComponentRepository.self) var componentRepository: ComponentRepository

    func getComponent(studyId: UUID, id: UUID) async throws -> QuestionnaireComponent {
        try await studyService.requireStudyAccess(id: studyId)

        guard let registry = try await componentRepository.find(id: id, studyId: studyId) else {
            throw ServerError.notFound(resource: "QuestionnaireComponent", identifier: id.uuidString)
        }

        guard registry.type == .questionnaire else {
            throw ServerError.notFound(resource: "QuestionnaireComponent", identifier: id.uuidString)
        }

        guard let component = try await repository.find(id: id) else {
            throw ServerError.notFound(resource: "QuestionnaireComponent", identifier: id.uuidString)
        }

        return component
    }

    func createComponent(
        studyId: UUID,
        name: String,
        content: LocalizedDictionary<QuestionnaireContent>
    ) async throws -> QuestionnaireComponent {
        try await studyService.requireStudyAccess(id: studyId)

        // Create registry entry first
        let registry = try await componentRepository.create(
            studyId: studyId,
            type: .questionnaire,
            name: name
        )

        // Create specialized component data with same ID
        return try await repository.create(componentId: try registry.requireId(), data: content)
    }

    func updateComponent(
        studyId: UUID,
        id: UUID,
        name: String,
        content: LocalizedDictionary<QuestionnaireContent>
    ) async throws -> QuestionnaireComponent {
        try await studyService.requireStudyAccess(id: studyId)

        guard let registry = try await componentRepository.find(id: id, studyId: studyId) else {
            throw ServerError.notFound(resource: "QuestionnaireComponent", identifier: id.uuidString)
        }

        guard registry.type == .questionnaire else {
            throw ServerError.notFound(resource: "QuestionnaireComponent", identifier: id.uuidString)
        }

        guard let component = try await repository.find(id: id) else {
            throw ServerError.notFound(resource: "QuestionnaireComponent", identifier: id.uuidString)
        }

        // Update registry entry name
        registry.name = name
        try await componentRepository.update(registry)

        // Update component data
        component.data = content
        try await repository.update(component)

        return component
    }
}
