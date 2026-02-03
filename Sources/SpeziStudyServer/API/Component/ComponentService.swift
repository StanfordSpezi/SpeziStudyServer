//
// This source file is part of the SpeziStudyServer open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//
import Foundation

final class ComponentService: VaporModule, @unchecked Sendable {
    @Dependency(StudyService.self) var studyService: StudyService
    @Dependency(DatabaseInformationalComponentRepository.self) var informationalRepository: DatabaseInformationalComponentRepository
    @Dependency(DatabaseQuestionnaireComponentRepository.self) var questionnaireRepository: DatabaseQuestionnaireComponentRepository
    @Dependency(DatabaseHealthDataComponentRepository.self) var healthDataRepository: DatabaseHealthDataComponentRepository

    func listComponents(studyId: UUID) async throws -> [Components.Schemas.Component] {
        try await studyService.validateExists(id: studyId)

        var components: [Components.Schemas.Component] = []

        for component in try await informationalRepository.findAll(studyId: studyId) {
            if let id = component.id {
                components.append(Components.Schemas.Component(id: id.uuidString, _type: "informational"))
            }
        }

        for component in try await questionnaireRepository.findAll(studyId: studyId) {
            if let id = component.id {
                components.append(Components.Schemas.Component(id: id.uuidString, _type: "questionnaire"))
            }
        }

        for component in try await healthDataRepository.findAll(studyId: studyId) {
            if let id = component.id {
                components.append(Components.Schemas.Component(id: id.uuidString, _type: "healthDataCollection"))
            }
        }

        return components
    }

    func validateExists(studyId: UUID, componentId: UUID) async throws {
        if try await informationalRepository.find(id: componentId, studyId: studyId) != nil {
            return
        }

        if try await questionnaireRepository.find(id: componentId, studyId: studyId) != nil {
            return
        }

        if try await healthDataRepository.find(id: componentId, studyId: studyId) != nil {
            return
        }

        throw ServerError.notFound(resource: "Component", identifier: componentId.uuidString)
    }

    func deleteComponent(studyId: UUID, componentId: UUID) async throws {
        try await studyService.validateExists(id: studyId)

        if try await informationalRepository.delete(id: componentId, studyId: studyId) {
            return
        }

        if try await questionnaireRepository.delete(id: componentId, studyId: studyId) {
            return
        }

        if try await healthDataRepository.delete(id: componentId, studyId: studyId) {
            return
        }

        throw ServerError.notFound(resource: "Component", identifier: componentId.uuidString)
    }
}
