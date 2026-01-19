//
// This source file is part of the SpeziStudyServer open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//
import Foundation
import SpeziStudyDefinition

struct ComponentService: Sendable {
    let studyRepository: any StudyRepository
    let componentRepository: any ComponentRepository

    func listComponents(studyId: UUID) async throws -> [Components.Schemas.StudyComponent] {
        if try await studyRepository.find(id: studyId) == nil {
            throw ServerError.notFound(resource: "Study", identifier: studyId.uuidString)
        }

        let components = try await componentRepository.findAll(studyId: studyId)

        // Component data already has ID embedded from database
        return try ComponentMapper.toDTO(components.map { $0.componentData })
    }

    func getComponent(id: UUID, studyId: UUID) async throws -> Components.Schemas.StudyComponent {
        if try await studyRepository.find(id: studyId) == nil {
            throw ServerError.notFound(resource: "Study", identifier: studyId.uuidString)
        }

        guard let component = try await componentRepository.find(id: id, studyId: studyId) else {
            throw ServerError.notFound(resource: "Component", identifier: id.uuidString)
        }

        // Component data already has ID embedded from database
        return try ComponentMapper.toDTO(component.componentData)
    }

    func createComponent(studyId: UUID, dto: Components.Schemas.StudyComponent) async throws -> Components.Schemas.StudyComponent {
        if try await studyRepository.find(id: studyId) == nil {
            throw ServerError.notFound(resource: "Study", identifier: studyId.uuidString)
        }

        // Create placeholder component to get database ID
        let placeholderData = try ComponentMapper.toModel(dto, id: UUID())
        let component = Component(studyId: studyId, componentData: placeholderData)
        let createdComponent = try await componentRepository.create(component)

        guard let tableId = createdComponent.id else {
            throw ServerError.internalError(message: "Component missing database ID after save")
        }

        // Now inject the real database ID
        let componentData = try ComponentMapper.toModel(dto, id: tableId)
        createdComponent.componentData = componentData
        try await componentRepository.update(createdComponent)

        return try ComponentMapper.toDTO(componentData)
    }

    func updateComponent(id: UUID, studyId: UUID, dto: Components.Schemas.StudyComponent) async throws -> Components.Schemas.StudyComponent {
        if try await studyRepository.find(id: studyId) == nil {
            throw ServerError.notFound(resource: "Study", identifier: studyId.uuidString)
        }

        guard let component = try await componentRepository.find(id: id, studyId: studyId) else {
            throw ServerError.notFound(resource: "Component", identifier: id.uuidString)
        }

        // Inject the ID from the URL path
        let updatedComponentData = try ComponentMapper.toModel(dto, id: id)
        component.componentData = updatedComponentData
        try await componentRepository.update(component)

        return try ComponentMapper.toDTO(updatedComponentData)
    }

    func deleteComponent(id: UUID, studyId: UUID) async throws {
        if try await studyRepository.find(id: studyId) == nil {
            throw ServerError.notFound(resource: "Study", identifier: studyId.uuidString)
        }

        let deleted = try await componentRepository.delete(id: id, studyId: studyId)
        if !deleted {
            throw ServerError.notFound(resource: "Component", identifier: id.uuidString)
        }
    }
}
