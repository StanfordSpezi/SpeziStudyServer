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

@Suite("StudyFile Endpoint Tests", .serialized)
struct StudyFileEndpointTests {
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

    @Test("POST /studies/{id}/files creates study file")
    func createStudyFileEndpoint() async throws {
        try await TestUtilities.withApp { app in
            let metadata = TestUtilities.createTestMetadata(title: "Test Study", id: UUID())
            let study = Study(metadata: metadata)
            try await study.save(on: app.db)

            let requestBody = CreateFileRequestBody(
                name: "consent-doc",
                locale: "en-US",
                content: "# Study Consent\n\nPlease read...",
                type: "md"
            )

            try await app.test(.POST, "/studies/\(study.id!.uuidString)/files") { req in
                req.headers.contentType = .json
                req.body = .init(data: try TestUtilities.encodeRequestBody(requestBody))
            } afterResponse: { res async throws in
                #expect(res.status == .created)
                let file = try res.content.decode(Components.Schemas.FileResource.self)
                #expect(file.name == "consent-doc")
                #expect(file.locale == "en-US")
                #expect(file.content == "# Study Consent\n\nPlease read...")
                #expect(file._type == .md)
            }
        }
    }

    @Test("GET /studies/{id}/files lists all study files")
    func listStudyFilesEndpoint() async throws {
        try await TestUtilities.withApp { app in
            let metadata = TestUtilities.createTestMetadata(title: "Test Study", id: UUID())
            let study = Study(metadata: metadata)
            try await study.save(on: app.db)

            let file1 = TestUtilities.createTestStudyFile(studyId: study.id!, name: "file1", locale: "en-US")
            let file2 = TestUtilities.createTestStudyFile(studyId: study.id!, name: "file2", locale: "de-DE")
            try await file1.save(on: app.db)
            try await file2.save(on: app.db)

            try await app.test(.GET, "/studies/\(study.id!.uuidString)/files") { _ in
            } afterResponse: { res async throws in
                #expect(res.status == .ok)
                let files = try res.content.decode([Components.Schemas.FileResource].self)
                #expect(files.count == 2)
                #expect(files.contains { $0.name == "file1" })
                #expect(files.contains { $0.name == "file2" })
            }
        }
    }

    @Test("GET /studies/{id}/files/{locale} returns specific study file")
    func getStudyFileEndpoint() async throws {
        try await TestUtilities.withApp { app in
            let metadata = TestUtilities.createTestMetadata(title: "Test Study", id: UUID())
            let study = Study(metadata: metadata)
            try await study.save(on: app.db)

            let file = TestUtilities.createTestStudyFile(
                studyId: study.id!,
                name: "description",
                locale: "en-US",
                content: "Study description...",
                type: "md"
            )
            try await file.save(on: app.db)

            try await app.test(.GET, "/studies/\(study.id!.uuidString)/files/\(file.locale)") { _ in
            } afterResponse: { res async throws in
                #expect(res.status == .ok)
                let result = try res.content.decode(Components.Schemas.FileResource.self)
                #expect(result.name == "description")
                #expect(result.locale == "en-US")
                #expect(result.content == "Study description...")
                #expect(result._type == .md)
            }
        }
    }

    @Test("PUT /studies/{id}/files/{locale} replaces study file")
    func updateStudyFileEndpoint() async throws {
        try await TestUtilities.withApp { app in
            let metadata = TestUtilities.createTestMetadata(title: "Test Study", id: UUID())
            let study = Study(metadata: metadata)
            try await study.save(on: app.db)

            let file = TestUtilities.createTestStudyFile(
                studyId: study.id!,
                name: "original",
                locale: "en-US",
                content: "Original content",
                type: "md"
            )
            try await file.save(on: app.db)

            let requestBody = UpdateFileRequestBody(
                name: "updated",
                locale: "en-US",
                content: "Updated content",
                type: "json"
            )

            try await app.test(.PUT, "/studies/\(study.id!.uuidString)/files/\(file.locale)") { req in
                req.headers.contentType = .json
                req.body = .init(data: try TestUtilities.encodeRequestBody(requestBody))
            } afterResponse: { res async throws in
                #expect(res.status == .ok)
                let result = try res.content.decode(Components.Schemas.FileResource.self)
                #expect(result.name == "updated")
                #expect(result.locale == "en-US")
                #expect(result.content == "Updated content")
                #expect(result._type == .json)
            }
        }
    }

    @Test("DELETE /studies/{id}/files/{locale} removes study file")
    func deleteStudyFileEndpoint() async throws {
        try await TestUtilities.withApp { app in
            let metadata = TestUtilities.createTestMetadata(title: "Test Study", id: UUID())
            let study = Study(metadata: metadata)
            try await study.save(on: app.db)

            let file = TestUtilities.createTestStudyFile(studyId: study.id!)
            try await file.save(on: app.db)

            try await app.test(.DELETE, "/studies/\(study.id!.uuidString)/files/\(file.locale)") { _ in
            } afterResponse: { res async throws in
                #expect(res.status == .noContent)
            }

            // Verify file is deleted
            let files = try await StoredFile.query(on: app.db)
                .filter(\.$study.$id == study.id!)
                .all()
            #expect(files.isEmpty)
        }
    }

    @Test("Deleting a study cascades to its files")
    func cascadeDeleteStudyFiles() async throws {
        try await TestUtilities.withApp { app in
            let metadata = TestUtilities.createTestMetadata(title: "Test Study", id: UUID())
            let study = Study(metadata: metadata)
            try await study.save(on: app.db)

            let file = TestUtilities.createTestStudyFile(studyId: study.id!, name: "consent", locale: "en-US")
            try await file.save(on: app.db)

            // Verify file exists
            let filesBefore = try await StoredFile.query(on: app.db)
                .filter(\.$study.$id == study.id!)
                .all()
            #expect(filesBefore.count == 1)

            // Delete the study
            try await study.delete(on: app.db)

            // Verify file is gone
            let filesAfter = try await StoredFile.query(on: app.db).all()
            #expect(filesAfter.isEmpty)
        }
    }

    @Test("GET study file with non-existent locale returns 404")
    func getStudyFileNotFound() async throws {
        try await TestUtilities.withApp { app in
            let metadata = TestUtilities.createTestMetadata(title: "Test Study", id: UUID())
            let study = Study(metadata: metadata)
            try await study.save(on: app.db)

            try await app.test(.GET, "/studies/\(study.id!.uuidString)/files/fr-FR") { _ in
            } afterResponse: { res async throws in
                #expect(res.status == .notFound)
            }
        }
    }

    @Test("POST study file to non-existent study returns 404")
    func createStudyFileStudyNotFound() async throws {
        try await TestUtilities.withApp { app in
            let nonExistentStudyId = UUID()

            let requestBody = CreateFileRequestBody(
                name: "test",
                locale: "en-US",
                content: "content",
                type: "md"
            )

            try await app.test(.POST, "/studies/\(nonExistentStudyId.uuidString)/files") { req in
                req.headers.contentType = .json
                req.body = .init(data: try TestUtilities.encodeRequestBody(requestBody))
            } afterResponse: { res async throws in
                #expect(res.status == .notFound)
            }
        }
    }
}
