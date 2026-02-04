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
import ZIPFoundation

@Suite("Studies Endpoint Tests", .serialized)
struct StudiesEndpointTests {
    struct CreateStudyRequestBody: Codable {
        let metadata: StudyDefinition.Metadata
    }

    struct UpdateStudyRequestBody: Codable {
        let metadata: StudyDefinition.Metadata
    }

    @Test("POST /studies creates a study with metadata")
    func createStudy() async throws {
        try await TestUtilities.withApp { app in
            let metadata = TestUtilities.createTestMetadata(title: "New Study", id: UUID())
            let requestBody = CreateStudyRequestBody(metadata: metadata)

            try await app.test(.POST, "/studies") { req in
                req.headers.contentType = .json
                req.body = .init(data: try TestUtilities.encodeRequestBody(requestBody))
            } afterResponse: { res async throws in
                #expect(res.status == .created)
                let study = try res.content.decode(Components.Schemas.StudyResponse.self)
                #expect(study.metadata.additionalProperties.value["title"] as? String == "New Study")
            }
        }
    }

    @Test("GET /studies returns empty array when no studies exist")
    func listStudiesEmpty() async throws {
        try await TestUtilities.withApp { app in
            try await app.test(.GET, "/studies") { _ in
                // No body needed for GET
            } afterResponse: { res async throws in
                #expect(res.status == .ok)
                let studyIds = try res.content.decode([String].self)
                #expect(studyIds.isEmpty)
            }
        }
    }

    @Test("GET /studies lists all study IDs")
    func listStudies() async throws {
        try await TestUtilities.withApp { app in
            // Create studies directly
            let metadata1 = TestUtilities.createTestMetadata(title: "Study 1", id: UUID())
            let metadata2 = TestUtilities.createTestMetadata(title: "Study 2", id: UUID())
            let study1 = Study(metadata: metadata1, id: nil)
            let study2 = Study(metadata: metadata2, id: nil)
            try await study1.save(on: app.db)
            try await study2.save(on: app.db)

            // Make request to list studies
            try await app.test(.GET, "/studies") { _ in
                // No body needed for GET
            } afterResponse: { res async throws in
                #expect(res.status == .ok)
                let studies = try res.content.decode([Components.Schemas.StudyResponse].self)
                #expect(studies.count == 2)
            }
        }
    }

    @Test("GET /studies/{id} returns study metadata only")
    func getStudy() async throws {
        try await TestUtilities.withApp { app in
            // Create a study
            let metadata = TestUtilities.createTestMetadata(title: "Test Study", id: UUID())
            let study = Study(metadata: metadata, id: nil)
            try await study.save(on: app.db)

            // Make request to get study
            try await app.test(.GET, "/studies/\(study.id!.uuidString)") { _ in
                // No body needed for GET
            } afterResponse: { res async throws in
                #expect(res.status == .ok)
                let returnedStudy = try res.content.decode(Components.Schemas.StudyResponse.self)
                #expect(returnedStudy.id == study.id!.uuidString)
                #expect(returnedStudy.metadata.additionalProperties.value["title"] as? String == "Test Study")
            }
        }
    }

    @Test("PUT /studies/{id} updates study metadata")
    func updateStudy() async throws {
        try await TestUtilities.withApp { app in
            // Create a study
            let metadata = TestUtilities.createTestMetadata(title: "Original Title", id: UUID())
            let study = Study(metadata: metadata, id: nil)
            try await study.save(on: app.db)

            // Update the study metadata
            let updatedMetadata = TestUtilities.createTestMetadata(title: "Updated Title", id: study.id!)
            let requestBody = UpdateStudyRequestBody(metadata: updatedMetadata)

            try await app.test(.PUT, "/studies/\(study.id!.uuidString)") { req in
                req.headers.contentType = .json
                req.body = .init(data: try TestUtilities.encodeRequestBody(requestBody))
            } afterResponse: { res async throws in
                #expect(res.status == .ok)
                let returnedStudy = try res.content.decode(Components.Schemas.StudyResponse.self)
                #expect(returnedStudy.metadata.additionalProperties.value["title"] as? String == "Updated Title")
            }

            // Verify the update persisted
            let updatedStudyFromDB = try await Study.find(study.id!, on: app.db)
            #expect(updatedStudyFromDB?.metadata.title["en"] == "Updated Title")
        }
    }

    @Test("PUT non-existent study returns 404")
    func updateStudyNotFound() async throws {
        try await TestUtilities.withApp { app in
            let nonExistentId = UUID()
            let metadata = TestUtilities.createTestMetadata(title: "Test", id: nonExistentId)
            let requestBody = UpdateStudyRequestBody(metadata: metadata)

            try await app.test(.PUT, "/studies/\(nonExistentId.uuidString)") { req in
                req.headers.contentType = .json
                req.body = .init(data: try TestUtilities.encodeRequestBody(requestBody))
            } afterResponse: { res async throws in
                #expect(res.status == .notFound)
            }
        }
    }

    @Test("GET non-existent study returns 404")
    func getStudyNotFound() async throws {
        try await TestUtilities.withApp { app in
            let nonExistentId = UUID()

            try await app.test(.GET, "/studies/\(nonExistentId.uuidString)") { _ in
                // No body needed for GET
            } afterResponse: { res async throws in
                #expect(res.status == .notFound)
            }
        }
    }

    @Test("DELETE /studies/{id} removes study")
    func deleteStudy() async throws {
        try await TestUtilities.withApp { app in
            // Create a study
            let metadata = TestUtilities.createTestMetadata(title: "Test Study", id: UUID())
            let study = Study(metadata: metadata, id: nil)
            try await study.save(on: app.db)

            // Make request to delete study
            try await app.test(.DELETE, "/studies/\(study.id!.uuidString)") { _ in
                // No body needed for DELETE
            } afterResponse: { res async throws in
                #expect(res.status == .noContent)
            }

            // Verify study is deleted
            let deletedStudy = try await Study.find(study.id!, on: app.db)
            #expect(deletedStudy == nil)
        }
    }

    @Test("DELETE non-existent study returns 404")
    func deleteStudyNotFound() async throws {
        try await TestUtilities.withApp { app in
            let nonExistentId = UUID()

            try await app.test(.DELETE, "/studies/\(nonExistentId.uuidString)") { _ in
                // No body needed for DELETE
            } afterResponse: { res async throws in
                #expect(res.status == .notFound)
            }
        }
    }

    @Test("DELETE study also deletes components (cascade)")
    func deleteStudyCascadesComponents() async throws {
        try await TestUtilities.withApp { app in
            // Create a study with components
            let metadata = TestUtilities.createTestMetadata(title: "Test Study", id: UUID())
            let study = Study(metadata: metadata, id: nil)
            try await study.save(on: app.db)

            let component = Component(studyId: study.id!, type: "questionnaire", name: "Test Component")
            try await component.save(on: app.db)

            // Make request to delete study
            try await app.test(.DELETE, "/studies/\(study.id!.uuidString)") { _ in
                // No body needed for DELETE
            } afterResponse: { res async throws in
                #expect(res.status == .noContent)
            }

            // Verify components are also deleted
            let components = try await Component.query(on: app.db)
                .filter(\.$study.$id == study.id!)
                .all()
            #expect(components.isEmpty)
        }
    }

    // NOTE: Download tests are skipped until questionnaire validation is fixed.
    // @Test("GET /download/{id} returns downloadable ZIP file")
    // @Test("GET /download/{id} for non-existent study returns 404")
}
