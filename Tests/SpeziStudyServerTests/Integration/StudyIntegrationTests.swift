//
// This source file is part of the SpeziStudyServer open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
@testable import SpeziStudyServer
import Testing
import VaporTesting


@Suite(.serialized)
struct StudyIntegrationTests {
    @Test
    func createStudy() async throws {
        try await TestApp.withApp { app in
            let group = try await GroupFixtures.createGroup(on: app.db)
            let groupId = try group.requireId()

            try await app.test(.POST, "groups/\(groupId)/studies", beforeRequest: { req in
                try req.encodeJSONBody(createStudyRequestBody(title: "New Study"))
            }) { response in
                #expect(response.status == .created)

                let study = try response.content.decode(Components.Schemas.StudyResponse.self)
                #expect(study.id.isEmpty == false)
            }
        }
    }

    @Test
    func createStudyGroupNotFound() async throws {
        try await TestApp.withApp { app in
            let nonExistentId = UUID()

            try await app.test(.POST, "groups/\(nonExistentId)/studies", beforeRequest: { req in
                try req.encodeJSONBody(createStudyRequestBody(title: "New Study"))
            }) { response in
                #expect(response.status == .notFound)
            }
        }
    }

    @Test
    func getStudy() async throws {
        try await TestApp.withApp { app in
            let group = try await GroupFixtures.createGroup(on: app.db)
            let groupId = try group.requireId()
            let study = try await StudyFixtures.createStudy(on: app.db, groupId: groupId, title: "Test Study")
            let studyId = try study.requireId()

            try await app.test(.GET, "studies/\(studyId)") { response in
                #expect(response.status == .ok)

                let responseStudy = try response.content.decode(Components.Schemas.StudyResponse.self)
                #expect(responseStudy.id == studyId.uuidString)
            }
        }
    }

    @Test
    func getStudyNotFound() async throws {
        try await TestApp.withApp { app in
            let nonExistentId = UUID()

            try await app.test(.GET, "studies/\(nonExistentId)") { response in
                #expect(response.status == .notFound)
            }
        }
    }

    @Test
    func updateStudy() async throws {
        try await TestApp.withApp { app in
            let group = try await GroupFixtures.createGroup(on: app.db)
            let groupId = try group.requireId()
            let study = try await StudyFixtures.createStudy(on: app.db, groupId: groupId, title: "Original Title")
            let studyId = try study.requireId()

            try await app.test(.PUT, "studies/\(studyId)", beforeRequest: { req in
                try req.encodeJSONBody(createStudyRequestBody(title: "Updated Title", id: studyId))
            }) { response in
                #expect(response.status == .ok)
            }
        }
    }

    @Test
    func deleteStudy() async throws {
        try await TestApp.withApp { app in
            let group = try await GroupFixtures.createGroup(on: app.db)
            let groupId = try group.requireId()
            let study = try await StudyFixtures.createStudy(on: app.db, groupId: groupId)
            let studyId = try study.requireId()

            try await app.test(.DELETE, "studies/\(studyId)") { response in
                #expect(response.status == .noContent)
            }

            try await app.test(.GET, "studies/\(studyId)") { response in
                #expect(response.status == .notFound)
            }
        }
    }

    @Test
    func deleteStudyNotFound() async throws {
        try await TestApp.withApp { app in
            let nonExistentId = UUID()

            try await app.test(.DELETE, "studies/\(nonExistentId)") { response in
                #expect(response.status == .notFound)
            }
        }
    }

    @Test
    func listStudiesInGroup() async throws {
        try await TestApp.withApp { app in
            let group1 = try await GroupFixtures.createGroup(on: app.db, name: "Group 1")
            let group1Id = try group1.requireId()
            let group2 = try await GroupFixtures.createGroup(on: app.db, name: "Group 2")
            let group2Id = try group2.requireId()

            try await StudyFixtures.createStudy(on: app.db, groupId: group1Id, title: "Study A")
            try await StudyFixtures.createStudy(on: app.db, groupId: group1Id, title: "Study B")
            try await StudyFixtures.createStudy(on: app.db, groupId: group2Id, title: "Study C")

            try await app.test(.GET, "groups/\(group1Id)/studies") { response in
                #expect(response.status == .ok)

                let studies = try response.content.decode([Components.Schemas.StudyResponse].self)
                #expect(studies.count == 2)
            }

            try await app.test(.GET, "groups/\(group2Id)/studies") { response in
                #expect(response.status == .ok)

                let studies = try response.content.decode([Components.Schemas.StudyResponse].self)
                #expect(studies.count == 1)
            }
        }
    }

    private func createStudyRequestBody(title: String, id: UUID? = nil) -> [String: Any] {
        var metadata: [String: Any] = [
            "title": ["en-US": title],
            "shortTitle": ["en-US": "Test"],
            "explanationText": ["en-US": "Explanation text"],
            "shortExplanationText": ["en-US": "Short explanation"],
            "participationCriterion": [
                "all": ["_0": [[String: Any]]()]
            ],
            "enrollmentConditions": [
                "none": [String: Any]()
            ]
        ]
        if let id {
            metadata["id"] = id.uuidString
        }
        return ["metadata": metadata]
    }
}
