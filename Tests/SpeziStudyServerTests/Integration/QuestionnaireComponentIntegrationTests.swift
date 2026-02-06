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
struct QuestionnaireComponentIntegrationTests {
    @Test
    func createQuestionnaireComponent() async throws {
        try await TestApp.withApp { app in
            let group = try await ResearchGroupFixtures.createResearchGroup(on: app.db)
            let study = try await StudyFixtures.createStudy(on: app.db, researchGroupId: try group.requireId())
            let studyId = try study.requireId()

            try await app.test(
                .POST,
                "studies/\(studyId)/components/questionnaire",
                beforeRequest: { req in
                    try req.encodeJSONBody(createRequestBody(name: "Test Questionnaire"))
                }
            ) { response in
                #expect(response.status == .created)

                let component = try response.content.decode(
                    Components.Schemas.QuestionnaireComponentResponse.self
                )
                #expect(component.name == "Test Questionnaire")
                #expect(component.id.isEmpty == false)
            }
        }
    }

    @Test
    func getQuestionnaireComponent() async throws {
        try await TestApp.withApp { app in
            let group = try await ResearchGroupFixtures.createResearchGroup(on: app.db)
            let study = try await StudyFixtures.createStudy(on: app.db, researchGroupId: try group.requireId())
            let studyId = try study.requireId()

            let (component, _) = try await ComponentFixtures.createQuestionnaireComponent(
                on: app.db,
                studyId: studyId,
                name: "Test Questionnaire"
            )
            let componentId = try component.requireId()

            try await app.test(
                .GET,
                "studies/\(studyId)/components/questionnaire/\(componentId)"
            ) { response in
                #expect(response.status == .ok)

                let responseComponent = try response.content.decode(
                    Components.Schemas.QuestionnaireComponentResponse.self
                )
                #expect(responseComponent.id == componentId.uuidString)
                #expect(responseComponent.name == "Test Questionnaire")
            }
        }
    }

    @Test
    func getQuestionnaireComponentNotFound() async throws {
        try await TestApp.withApp { app in
            let group = try await ResearchGroupFixtures.createResearchGroup(on: app.db)
            let study = try await StudyFixtures.createStudy(on: app.db, researchGroupId: try group.requireId())
            let studyId = try study.requireId()
            let nonExistentId = UUID()

            try await app.test(
                .GET,
                "studies/\(studyId)/components/questionnaire/\(nonExistentId)"
            ) { response in
                #expect(response.status == .notFound)
            }
        }
    }

    @Test
    func updateQuestionnaireComponent() async throws {
        try await TestApp.withApp { app in
            let group = try await ResearchGroupFixtures.createResearchGroup(on: app.db)
            let study = try await StudyFixtures.createStudy(on: app.db, researchGroupId: try group.requireId())
            let studyId = try study.requireId()

            let (component, _) = try await ComponentFixtures.createQuestionnaireComponent(
                on: app.db,
                studyId: studyId,
                name: "Original Name"
            )
            let componentId = try component.requireId()

            try await app.test(
                .PUT,
                "studies/\(studyId)/components/questionnaire/\(componentId)",
                beforeRequest: { req in
                    try req.encodeJSONBody(createRequestBody(name: "Updated Name"))
                }
            ) { response in
                #expect(response.status == .ok)

                let updated = try response.content.decode(
                    Components.Schemas.QuestionnaireComponentResponse.self
                )
                #expect(updated.name == "Updated Name")
            }
        }
    }

    private func createRequestBody(name: String) -> [String: Any] {
        [
            "name": name,
            "data": [
                "en-US": [
                    "questionnaire": "{}"
                ]
            ]
        ]
    }
}
