//
// This source file is part of the SpeziStudyServer open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//
import Fluent
import SpeziStudyDefinition
@testable import SpeziStudyServer
import Testing
import VaporTesting

@Suite("Components Endpoint Tests", .serialized)
struct ComponentsEndpointTests {
    @Test("GET /studies/{id}/components returns empty array for study with no components")
    func listEmptyComponents() async throws {
        try await TestUtilities.withApp { app in
            // Create a study
            let metadata = TestUtilities.createTestMetadata(title: "Test Study", id: UUID())
            let study = Study(metadata: metadata)
            try await study.save(on: app.db)

            // Make request to list components
            try await app.test(.GET, "/studies/\(study.id!.uuidString)/components") { _ in
                // No body needed for GET
            } afterResponse: { res async throws in
                #expect(res.status == .ok)
                let components = try res.content.decode([Components.Schemas.Component].self)
                #expect(components.isEmpty)
            }
        }
    }

    @Test("GET /studies/{id}/components lists all components with name and type")
    func listComponents() async throws {
        try await TestUtilities.withApp { app in
            // Create a study
            let metadata = TestUtilities.createTestMetadata(title: "Test Study", id: UUID())
            let study = Study(metadata: metadata)
            try await study.save(on: app.db)

            // Add components directly to the registry
            let component1 = Component(studyId: study.id!, type: "questionnaire", name: "Component 1")
            let component2 = Component(studyId: study.id!, type: "informational", name: "Component 2")
            try await component1.save(on: app.db)
            try await component2.save(on: app.db)

            // Make request to list components
            try await app.test(.GET, "/studies/\(study.id!.uuidString)/components") { _ in
                // No body needed for GET
            } afterResponse: { res async throws in
                #expect(res.status == .ok)
                let components = try res.content.decode([Components.Schemas.Component].self)
                #expect(components.count == 2)
                // Verify that components have both name and type
                #expect(components.contains { $0.name == "Component 1" && $0._type == "questionnaire" })
                #expect(components.contains { $0.name == "Component 2" && $0._type == "informational" })
            }
        }
    }

    @Test("DELETE /studies/{id}/components/{componentId} removes component")
    func deleteComponent() async throws {
        try await TestUtilities.withApp { app in
            // Create a study
            let metadata = TestUtilities.createTestMetadata(title: "Test Study", id: UUID())
            let study = Study(metadata: metadata, id: nil)
            try await study.save(on: app.db)

            // Add a component to the registry
            let component = Component(studyId: study.id!, type: "questionnaire", name: "Test Component")
            try await component.save(on: app.db)

            // Make request to delete component
            try await app.test(.DELETE, "/studies/\(study.id!.uuidString)/components/\(component.id!.uuidString)") { _ in
                // No body needed for DELETE
            } afterResponse: { res async throws in
                #expect(res.status == .noContent)
            }

            // Verify component is deleted
            let components = try await Component.query(on: app.db)
                .filter(\.$study.$id == study.id!)
                .all()
            #expect(components.isEmpty)
        }
    }

    @Test("GET components for non-existent study returns 404")
    func listComponentsStudyNotFound() async throws {
        try await TestUtilities.withApp { app in
            let nonExistentId = UUID()

            try await app.test(.GET, "/studies/\(nonExistentId.uuidString)/components") { _ in
                // No body needed for GET
            } afterResponse: { res async throws in
                #expect(res.status == .notFound)
            }
        }
    }

    @Test("DELETE non-existent component returns 404")
    func deleteComponentNotFound() async throws {
        try await TestUtilities.withApp { app in
            // Create a study
            let metadata = TestUtilities.createTestMetadata(title: "Test Study", id: UUID())
            let study = Study(metadata: metadata, id: nil)
            try await study.save(on: app.db)

            let nonExistentComponentId = UUID()

            try await app.test(.DELETE, "/studies/\(study.id!.uuidString)/components/\(nonExistentComponentId.uuidString)") { _ in
                // No body needed for DELETE
            } afterResponse: { res async throws in
                #expect(res.status == .notFound)
            }
        }
    }
}
