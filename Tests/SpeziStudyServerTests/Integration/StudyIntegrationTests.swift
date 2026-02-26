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
        try await TestApp.withApp { app, token in
            let group = try await GroupFixtures.createGroup(on: app.db)
            let groupId = try group.requireId()

            try await app.test(.POST, "\(apiBasePath)/groups/\(groupId)/studies", beforeRequest: { req in
                req.bearerAuth(token)
                try req.encodeJSONBody(createStudyRequestBody(title: "New Study"))
            }) { response in
                #expect(response.status == .created)

                let study = try response.content.decode(Components.Schemas.StudyResponse.self)
                #expect(study.id.isEmpty == false)
                #expect(study.details[.enUS]?.title == "New Study")
                #expect(study.locales == ["en-US"])
                #expect(study.icon == "heart")
                #expect(study.consent.isEmpty)
            }
        }
    }

    @Test
    func createStudyGroupNotFound() async throws {
        try await TestApp.withApp { app, token in
            let nonExistentId = UUID()

            try await app.test(.POST, "\(apiBasePath)/groups/\(nonExistentId)/studies", beforeRequest: { req in
                req.bearerAuth(token)
                try req.encodeJSONBody(createStudyRequestBody(title: "New Study"))
            }) { response in
                #expect(response.status == .notFound)
            }
        }
    }

    @Test
    func getStudy() async throws {
        try await TestApp.withApp { app, token in
            let group = try await GroupFixtures.createGroup(on: app.db)
            let groupId = try group.requireId()
            let study = try await StudyFixtures.createStudy(on: app.db, groupId: groupId, title: "Test Study")
            let studyId = try study.requireId()

            try await app.test(.GET, "\(apiBasePath)/studies/\(studyId)", beforeRequest: { req in
                req.bearerAuth(token)
            }) { response in
                #expect(response.status == .ok)

                let responseStudy = try response.content.decode(Components.Schemas.StudyResponse.self)
                #expect(responseStudy.id == studyId.uuidString)
                #expect(responseStudy.details[.enUS]?.title == "Test Study")
                #expect(responseStudy.locales == ["en-US"])
                #expect(responseStudy.icon == "heart")
                #expect(responseStudy.consent.isEmpty)
            }
        }
    }

    @Test
    func getStudyNotFound() async throws {
        try await TestApp.withApp { app, token in
            let nonExistentId = UUID()

            try await app.test(.GET, "\(apiBasePath)/studies/\(nonExistentId)", beforeRequest: { req in
                req.bearerAuth(token)
            }) { response in
                #expect(response.status == .notFound)
            }
        }
    }

    @Test
    func patchStudyTitle() async throws {
        try await TestApp.withApp { app, token in
            let group = try await GroupFixtures.createGroup(on: app.db)
            let groupId = try group.requireId()
            let study = try await StudyFixtures.createStudy(on: app.db, groupId: groupId, title: "Original Title")
            let studyId = try study.requireId()

            let patchBody: [String: Any] = [
                "details": [
                    "en-US": [
                        "title": "Updated Title"
                    ] as [String: Any]
                ] as [String: Any]
            ]

            try await app.test(.PATCH, "\(apiBasePath)/studies/\(studyId)", beforeRequest: { req in
                req.bearerAuth(token)
                try req.encodeJSONBody(patchBody)
            }) { response in
                #expect(response.status == .ok)

                let responseStudy = try response.content.decode(Components.Schemas.StudyResponse.self)
                #expect(responseStudy.details[.enUS]?.title == "Updated Title")
                #expect(responseStudy.locales == ["en-US"])
                #expect(responseStudy.icon == "heart")
                #expect(responseStudy.consent.isEmpty)
            }
        }
    }

    @Test
    func patchStudyDetails() async throws {
        try await TestApp.withApp { app, token in
            let group = try await GroupFixtures.createGroup(on: app.db)
            let groupId = try group.requireId()
            let study = try await StudyFixtures.createStudy(on: app.db, groupId: groupId, title: "Test Study")
            let studyId = try study.requireId()

            let patchBody: [String: Any] = [
                "details": [
                    "en-US": [
                        "shortTitle": "TS",
                        "explanationText": "A test study explanation"
                    ] as [String: Any]
                ] as [String: Any]
            ]

            try await app.test(.PATCH, "\(apiBasePath)/studies/\(studyId)", beforeRequest: { req in
                req.bearerAuth(token)
                try req.encodeJSONBody(patchBody)
            }) { response in
                #expect(response.status == .ok)

                let responseStudy = try response.content.decode(Components.Schemas.StudyResponse.self)
                #expect(responseStudy.details[.enUS]?.shortTitle == "TS")
                #expect(responseStudy.details[.enUS]?.explanationText == "A test study explanation")
                #expect(responseStudy.details[.enUS]?.shortExplanationText.isEmpty == true)
                #expect(responseStudy.locales == ["en-US"])
                #expect(responseStudy.icon == "heart")
                #expect(responseStudy.consent.isEmpty)
            }
        }
    }

    @Test
    func patchStudyConsent() async throws {
        try await TestApp.withApp { app, token in
            let group = try await GroupFixtures.createGroup(on: app.db)
            let groupId = try group.requireId()
            let study = try await StudyFixtures.createStudy(on: app.db, groupId: groupId, title: "Consent Study")
            let studyId = try study.requireId()

            let patchBody: [String: Any] = [
                "consent": [
                    "en-US": "# Informed Consent\n\nBy participating in this study, you agree to..."
                ] as [String: Any]
            ]

            try await app.test(.PATCH, "\(apiBasePath)/studies/\(studyId)", beforeRequest: { req in
                req.bearerAuth(token)
                try req.encodeJSONBody(patchBody)
            }) { response in
                #expect(response.status == .ok)

                let responseStudy = try response.content.decode(Components.Schemas.StudyResponse.self)
                #expect(responseStudy.consent[.enUS] == "# Informed Consent\n\nBy participating in this study, you agree to...")
                #expect(responseStudy.details[.enUS]?.title == "Consent Study")
                #expect(responseStudy.locales == ["en-US"])
                #expect(responseStudy.icon == "heart")
            }

            // Verify consent persists on GET
            try await app.test(.GET, "\(apiBasePath)/studies/\(studyId)", beforeRequest: { req in
                req.bearerAuth(token)
            }) { response in
                #expect(response.status == .ok)

                let responseStudy = try response.content.decode(Components.Schemas.StudyResponse.self)
                #expect(responseStudy.consent[.enUS] == "# Informed Consent\n\nBy participating in this study, you agree to...")
            }
        }
    }

    @Test
    func deleteStudy() async throws {
        try await TestApp.withApp { app, token in
            let group = try await GroupFixtures.createGroup(on: app.db)
            let groupId = try group.requireId()
            let study = try await StudyFixtures.createStudy(on: app.db, groupId: groupId)
            let studyId = try study.requireId()

            try await app.test(.DELETE, "\(apiBasePath)/studies/\(studyId)", beforeRequest: { req in
                req.bearerAuth(token)
            }) { response in
                #expect(response.status == .noContent)
            }

            try await app.test(.GET, "\(apiBasePath)/studies/\(studyId)", beforeRequest: { req in
                req.bearerAuth(token)
            }) { response in
                #expect(response.status == .notFound)
            }
        }
    }

    @Test
    func deleteStudyNotFound() async throws {
        try await TestApp.withApp { app, token in
            let nonExistentId = UUID()

            try await app.test(.DELETE, "\(apiBasePath)/studies/\(nonExistentId)", beforeRequest: { req in
                req.bearerAuth(token)
            }) { response in
                #expect(response.status == .notFound)
            }
        }
    }

    @Test
    func listStudiesInGroup() async throws {
        try await TestApp.withApp(groups: ["/Group 1/admin", "/Group 2/admin"]) { app, token in
            let group1 = try await GroupFixtures.createGroup(on: app.db, name: "Group 1")
            let group1Id = try group1.requireId()
            let group2 = try await GroupFixtures.createGroup(on: app.db, name: "Group 2")
            let group2Id = try group2.requireId()

            try await StudyFixtures.createStudy(on: app.db, groupId: group1Id, title: "Study A")
            try await StudyFixtures.createStudy(on: app.db, groupId: group1Id, title: "Study B")
            try await StudyFixtures.createStudy(on: app.db, groupId: group2Id, title: "Study C")

            try await app.test(.GET, "\(apiBasePath)/groups/\(group1Id)/studies", beforeRequest: { req in
                req.bearerAuth(token)
            }) { response in
                #expect(response.status == .ok)

                let studies = try response.content.decode([Components.Schemas.StudyListItem].self)
                #expect(studies.count == 2)
            }

            try await app.test(.GET, "\(apiBasePath)/groups/\(group2Id)/studies", beforeRequest: { req in
                req.bearerAuth(token)
            }) { response in
                #expect(response.status == .ok)

                let studies = try response.content.decode([Components.Schemas.StudyListItem].self)
                #expect(studies.count == 1)
            }
        }
    }

    private func createStudyRequestBody(title: String) -> [String: Any] {
        [
            "title": title,
            "icon": "heart"
        ] as [String: Any]
    }
}
