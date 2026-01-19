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

@Suite("ComponentFile Endpoint Tests", .serialized)
struct ComponentFileEndpointTests {
    struct CreateFileRequestBody: Codable {
        let name: String
        let locale: String
        let content: String
        let type: String
    }

    struct UpdateFileRequestBody: Codable {
        let name: String
        let locale: String
        let content: String
        let type: String
    }

    @Test("POST /studies/{id}/components/{componentId}/files creates file")
    func createFileEndpoint() async throws {
        try await TestUtilities.withApp { app in
            // Create a study and component
            let metadata = TestUtilities.createTestMetadata(title: "Test Study", id: UUID())
            let study = Study(metadata: metadata)
            try await study.save(on: app.db)

            let componentId = UUID()
            let componentData = TestUtilities.createTestQuestionnaireComponent(filename: "Test", id: componentId)
            let component = Component(studyId: study.id!, componentData: componentData)
            try await component.save(on: app.db)

            // Make request to create file
            let requestBody = CreateFileRequestBody(
                name: "consent-form",
                locale: "en-US",
                content: "# Consent\n\nI agree...",
                type: "md"
            )

            try await app.test(.POST, "/studies/\(study.id!.uuidString)/components/\(component.id!.uuidString)/files") { req in
                req.headers.contentType = .json
                req.body = .init(data: try TestUtilities.encodeRequestBody(requestBody))
            } afterResponse: { res async throws in
                #expect(res.status == .created)
                let file = try res.content.decode(Components.Schemas.ComponentFile.self)
                #expect(file.name == "consent-form")
                #expect(file.locale == "en-US")
                #expect(file.content == "# Consent\n\nI agree...")
                #expect(file._type == .md)
            }
        }
    }

    @Test("GET /studies/{id}/components/{componentId}/files lists all files")
    func listFilesEndpoint() async throws {
        try await TestUtilities.withApp { app in
            // Create a study and component
            let metadata = TestUtilities.createTestMetadata(title: "Test Study", id: UUID())
            let study = Study(metadata: metadata)
            try await study.save(on: app.db)

            let componentId = UUID()
            let componentData = TestUtilities.createTestQuestionnaireComponent(filename: "Test", id: componentId)
            let component = Component(studyId: study.id!, componentData: componentData)
            try await component.save(on: app.db)

            // Add some files directly
            let file1 = TestUtilities.createTestFile(componentId: component.id!, name: "file1", locale: "en-US")
            let file2 = TestUtilities.createTestFile(componentId: component.id!, name: "file2", locale: "de-DE")
            file1.$component.id = component.id!
            file2.$component.id = component.id!
            try await file1.save(on: app.db)
            try await file2.save(on: app.db)

            // Make request to list files
            try await app.test(.GET, "/studies/\(study.id!.uuidString)/components/\(component.id!.uuidString)/files") { _ in
                // No body needed for GET
            } afterResponse: { res async throws in
                #expect(res.status == .ok)
                let files = try res.content.decode([Components.Schemas.ComponentFile].self)
                #expect(files.count == 2)
                #expect(files.contains { $0.name == "file1" })
                #expect(files.contains { $0.name == "file2" })
            }
        }
    }

    @Test("GET /studies/{id}/components/{componentId}/files/{locale} returns specific file")
    func getFileEndpoint() async throws {
        try await TestUtilities.withApp { app in
            // Create a study and component
            let metadata = TestUtilities.createTestMetadata(title: "Test Study", id: UUID())
            let study = Study(metadata: metadata)
            try await study.save(on: app.db)

            let componentId = UUID()
            let componentData = TestUtilities.createTestQuestionnaireComponent(filename: "Test", id: componentId)
            let component = Component(studyId: study.id!, componentData: componentData)
            try await component.save(on: app.db)

            // Add a file
            let file = TestUtilities.createTestFile(
                componentId: component.id!,
                name: "privacy-policy",
                locale: "en-UK",
                content: "Privacy information...",
                type: "md"
            )
            file.$component.id = component.id!
            try await file.save(on: app.db)
            let addedFile = file

            // Make request to get file
            try await app.test(.GET, "/studies/\(study.id!.uuidString)/components/\(component.id!.uuidString)/files/\(addedFile.locale)") { _ in
                // No body needed for GET
            } afterResponse: { res async throws in
                #expect(res.status == .ok)
                let file = try res.content.decode(Components.Schemas.ComponentFile.self)
                #expect(file.name == "privacy-policy")
                #expect(file.locale == "en-UK")
                #expect(file.content == "Privacy information...")
                #expect(file._type == .md)
            }
        }
    }

    @Test("PUT /studies/{id}/components/{componentId}/files/{locale} replaces file")
    func updateFileEndpoint() async throws {
        try await TestUtilities.withApp { app in
            // Create a study and component
            let metadata = TestUtilities.createTestMetadata(title: "Test Study", id: UUID())
            let study = Study(metadata: metadata)
            try await study.save(on: app.db)

            let componentId = UUID()
            let componentData = TestUtilities.createTestQuestionnaireComponent(filename: "Test", id: componentId)
            let component = Component(studyId: study.id!, componentData: componentData)
            try await component.save(on: app.db)

            // Add a file
            let file = TestUtilities.createTestFile(
                componentId: component.id!,
                name: "original",
                locale: "en-US",
                content: "Original content",
                type: "md"
            )
            file.$component.id = component.id!
            try await file.save(on: app.db)
            let addedFile = file

            // Make request to update file (locale cannot change - it's part of the key)
            let requestBody = UpdateFileRequestBody(
                name: "updated",
                locale: "en-US",
                content: "Updated content",
                type: "json"
            )

            try await app.test(.PUT, "/studies/\(study.id!.uuidString)/components/\(component.id!.uuidString)/files/\(addedFile.locale)") { req in
                req.headers.contentType = .json
                req.body = .init(data: try TestUtilities.encodeRequestBody(requestBody))
            } afterResponse: { res async throws in
                #expect(res.status == .ok)
                let file = try res.content.decode(Components.Schemas.ComponentFile.self)
                #expect(file.name == "updated")
                #expect(file.locale == "en-US")
                #expect(file.content == "Updated content")
                #expect(file._type == .json)
            }
        }
    }

    @Test("DELETE /studies/{id}/components/{componentId}/files/{locale} removes file")
    func deleteFileEndpoint() async throws {
        try await TestUtilities.withApp { app in
            // Create a study and component
            let metadata = TestUtilities.createTestMetadata(title: "Test Study", id: UUID())
            let study = Study(metadata: metadata)
            try await study.save(on: app.db)

            let componentId = UUID()
            let componentData = TestUtilities.createTestQuestionnaireComponent(filename: "Test", id: componentId)
            let component = Component(studyId: study.id!, componentData: componentData)
            try await component.save(on: app.db)

            // Add a file
            let file = TestUtilities.createTestFile(componentId: component.id!)
            file.$component.id = component.id!
            try await file.save(on: app.db)
            let addedFile = file

            // Make request to delete file
            try await app.test(.DELETE, "/studies/\(study.id!.uuidString)/components/\(component.id!.uuidString)/files/\(addedFile.locale)") { _ in
                // No body needed for DELETE
            } afterResponse: { res async throws in
                #expect(res.status == .noContent)
            }

            // Verify file is deleted
            let files = try await ComponentFile.query(on: app.db)
                .filter(\.$component.$id == component.id!)
                .all()
            #expect(files.isEmpty)
        }
    }

    @Test("POST file with invalid locale returns 400")
    func createFileInvalidLocale() async throws {
        try await TestUtilities.withApp { app in
            // Create a study and component
            let metadata = TestUtilities.createTestMetadata(title: "Test Study", id: UUID())
            let study = Study(metadata: metadata)
            try await study.save(on: app.db)

            let componentId = UUID()
            let componentData = TestUtilities.createTestQuestionnaireComponent(filename: "Test", id: componentId)
            let component = Component(studyId: study.id!, componentData: componentData)
            try await component.save(on: app.db)

            // Make request with invalid locale
            let requestBody = CreateFileRequestBody(
                name: "test",
                locale: "invalid_locale",
                content: "content",
                type: "md"
            )

            try await app.test(.POST, "/studies/\(study.id!.uuidString)/components/\(component.id!.uuidString)/files") { req in
                req.headers.contentType = .json
                req.body = .init(data: try TestUtilities.encodeRequestBody(requestBody))
            } afterResponse: { res async throws in
                #expect(res.status == .badRequest)
            }
        }
    }

    @Test("GET file with non-existent ID returns 404")
    func getFileNotFound() async throws {
        try await TestUtilities.withApp { app in
            // Create a study and component
            let metadata = TestUtilities.createTestMetadata(title: "Test Study", id: UUID())
            let study = Study(metadata: metadata)
            try await study.save(on: app.db)

            let componentId = UUID()
            let componentData = TestUtilities.createTestQuestionnaireComponent(filename: "Test", id: componentId)
            let component = Component(studyId: study.id!, componentData: componentData)
            try await component.save(on: app.db)

            let nonExistentlocale = "fr-FR"

            // Make request with non-existent locale
            try await app.test(.GET, "/studies/\(study.id!.uuidString)/components/\(component.id!.uuidString)/files/\(nonExistentlocale)") { _ in
                // No body needed for GET
            } afterResponse: { res async throws in
                #expect(res.status == .notFound)
            }
        }
    }

    @Test("POST file to non-existent component returns 404")
    func createFileComponentNotFound() async throws {
        try await TestUtilities.withApp { app in
            // Create a study only
            let metadata = TestUtilities.createTestMetadata(title: "Test Study", id: UUID())
            let study = Study(metadata: metadata)
            try await study.save(on: app.db)

            let nonExistentComponentId = UUID()

            // Make request with non-existent component ID
            let requestBody = CreateFileRequestBody(
                name: "test",
                locale: "en-US",
                content: "content",
                type: "md"
            )

            try await app.test(.POST, "/studies/\(study.id!.uuidString)/components/\(nonExistentComponentId.uuidString)/files") { req in
                req.headers.contentType = .json
                req.body = .init(data: try TestUtilities.encodeRequestBody(requestBody))
            } afterResponse: { res async throws in
                #expect(res.status == .notFound)
            }
        }
    }

    @Test("GET files for non-existent study returns 404")
    func listFilesStudyNotFound() async throws {
        try await TestUtilities.withApp { app in
            let nonExistentStudyId = UUID()
            let nonExistentComponentId = UUID()

            // Make request with non-existent study ID
            try await app.test(.GET, "/studies/\(nonExistentStudyId.uuidString)/components/\(nonExistentComponentId.uuidString)/files") { _ in
                // No body needed for GET
            } afterResponse: { res async throws in
                #expect(res.status == .notFound)
            }
        }
    }
}
