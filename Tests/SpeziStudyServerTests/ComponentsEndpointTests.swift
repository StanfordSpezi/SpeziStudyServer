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
    @Test("POST /studies/{id}/components creates component")
    func createComponent() async throws {
        try await TestUtilities.withApp { app in
            let metadata = TestUtilities.createTestMetadata(title: "Test Study", id: UUID())
            let study = Study(metadata: metadata)
            try await study.save(on: app.db)
            
            let componentData = TestUtilities.createTestQuestionnaireComponent(filename: "consent")
            
            try await app.test(.POST, "/studies/\(study.id!.uuidString)/components") { req in
                req.headers.contentType = .json
                req.body = .init(data: try JSONEncoder().encode(componentData))
            } afterResponse: { res async throws in
                #expect(res.status == .created)
            }

            let components = try await Component.query(on: app.db)
                .filter(\.$study.$id == study.id!)
                .all()
            #expect(components.count == 1)
        }
    }


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
                let components = try res.content.decode([Components.Schemas.StudyComponent].self)
                #expect(components.isEmpty)
            }
        }
    }

    @Test("GET /studies/{id}/components lists all components")
    func listComponents() async throws {
        try await TestUtilities.withApp { app in
            // Create a study
            let metadata = TestUtilities.createTestMetadata(title: "Test Study", id: UUID())
            let study = Study(metadata: metadata)
            try await study.save(on: app.db)

            // Add components directly
            let componentData1 = TestUtilities.createTestQuestionnaireComponent(filename: "q1", id: UUID())
            let componentData2 = TestUtilities.createTestQuestionnaireComponent(filename: "q2", id: UUID())
            let component1 = Component(studyId: study.id!, componentData: componentData1)
            let component2 = Component(studyId: study.id!, componentData: componentData2)
            try await component1.save(on: app.db)
            try await component2.save(on: app.db)

            // Make request to list components
            try await app.test(.GET, "/studies/\(study.id!.uuidString)/components") { _ in
                // No body needed for GET
            } afterResponse: { res async throws in
                #expect(res.status == .ok)
                let components = try res.content.decode([Components.Schemas.StudyComponent].self)
                #expect(components.count == 2)
            }
        }
    }

    @Test("GET /studies/{id}/components/{componentId} returns specific component")
    func getComponent() async throws {
        try await TestUtilities.withApp { app in
            // Create a study
            let metadata = TestUtilities.createTestMetadata(title: "Test Study", id: UUID())
            let study = Study(metadata: metadata, id: nil)
            try await study.save(on: app.db)

            // Add a component
            let componentData = TestUtilities.createTestQuestionnaireComponent(filename: "test", id: UUID())
            let component = Component(studyId: study.id!, componentData: componentData)
            try await component.save(on: app.db)

            // Make request to get component
            try await app.test(.GET, "/studies/\(study.id!.uuidString)/components/\(component.id!.uuidString)") { _ in
                // No body needed for GET
            } afterResponse: { res async throws in
                #expect(res.status == .ok)
                let returnedComponent = try res.content.decode(Components.Schemas.StudyComponent.self)
                #expect(returnedComponent.additionalProperties.value["questionnaire"] != nil)
            }
        }
    }

    @Test("PUT /studies/{id}/components/{componentId} replaces component")
    func updateComponent() async throws {
        try await TestUtilities.withApp { app in
            // Create a study
            let metadata = TestUtilities.createTestMetadata(title: "Test Study", id: UUID())
            let study = Study(metadata: metadata, id: nil)
            try await study.save(on: app.db)

            // Add a component
            let componentData = TestUtilities.createTestQuestionnaireComponent(filename: "original", id: UUID())
            let component = Component(studyId: study.id!, componentData: componentData)
            try await component.save(on: app.db)

            // Update the component
            let updatedComponentData = TestUtilities.createTestQuestionnaireComponent(filename: "updated", id: component.id!)

            try await app.test(.PUT, "/studies/\(study.id!.uuidString)/components/\(component.id!.uuidString)") { req in
                req.headers.contentType = .json
                req.body = .init(data: try TestUtilities.encodeRequestBody(updatedComponentData))
            } afterResponse: { res async throws in
                #expect(res.status == .ok)
                let returnedComponent = try res.content.decode(Components.Schemas.StudyComponent.self)
                #expect(returnedComponent.additionalProperties.value["questionnaire"] != nil)
            }

            // Verify the update persisted
            let updatedComponent = try await Component.find(component.id!, on: app.db)
            #expect(updatedComponent != nil)
        }
    }

    @Test("PUT non-existent component returns 404")
    func updateComponentNotFound() async throws {
        try await TestUtilities.withApp { app in
            // Create a study
            let metadata = TestUtilities.createTestMetadata(title: "Test Study", id: UUID())
            let study = Study(metadata: metadata, id: nil)
            try await study.save(on: app.db)

            let nonExistentComponentId = UUID()
            let componentData = TestUtilities.createTestQuestionnaireComponent(filename: "test", id: nonExistentComponentId)

            try await app.test(.PUT, "/studies/\(study.id!.uuidString)/components/\(nonExistentComponentId.uuidString)") { req in
                req.headers.contentType = .json
                req.body = .init(data: try TestUtilities.encodeRequestBody(componentData))
            } afterResponse: { res async throws in
                #expect(res.status == .notFound)
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

            // Add a component
            let componentData = TestUtilities.createTestQuestionnaireComponent(filename: "test", id: UUID())
            let component = Component(studyId: study.id!, componentData: componentData)
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

    @Test("GET non-existent component returns 404")
    func getComponentNotFound() async throws {
        try await TestUtilities.withApp { app in
            // Create a study
            let metadata = TestUtilities.createTestMetadata(title: "Test Study", id: UUID())
            let study = Study(metadata: metadata, id: nil)
            try await study.save(on: app.db)

            let nonExistentComponentId = UUID()

            try await app.test(.GET, "/studies/\(study.id!.uuidString)/components/\(nonExistentComponentId.uuidString)") { _ in
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
