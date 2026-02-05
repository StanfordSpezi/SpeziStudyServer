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
struct InformationalComponentIntegrationTests {
    @Test
    func createInformationalComponent() async throws {
        try await TestApp.withApp { app in
            let study = try await StudyFixtures.createStudy(on: app.db)
            let studyId = try study.requireID()

            try await app.test(
                .POST,
                "studies/\(studyId)/components/informational",
                beforeRequest: { req in
                    try req.encodeJSONBody(createRequestBody(name: "Test Article"))
                }
            ) { response in
                #expect(response.status == .created)

                let component = try response.content.decode(
                    Components.Schemas.InformationalComponentResponse.self
                )
                #expect(component.name == "Test Article")
                #expect(component.id.isEmpty == false)
            }
        }
    }

    @Test
    func getInformationalComponent() async throws {
        try await TestApp.withApp { app in
            let study = try await StudyFixtures.createStudy(on: app.db)
            let studyId = try study.requireID()

            let (component, _) = try await ComponentFixtures.createInformationalComponent(
                on: app.db,
                studyId: studyId,
                name: "Test Article"
            )
            let componentId = try component.requireID()

            try await app.test(
                .GET,
                "studies/\(studyId)/components/informational/\(componentId)"
            ) { response in
                #expect(response.status == .ok)

                let responseComponent = try response.content.decode(
                    Components.Schemas.InformationalComponentResponse.self
                )
                #expect(responseComponent.id == componentId.uuidString)
                #expect(responseComponent.name == "Test Article")
            }
        }
    }

    @Test
    func getInformationalComponentNotFound() async throws {
        try await TestApp.withApp { app in
            let study = try await StudyFixtures.createStudy(on: app.db)
            let studyId = try study.requireID()
            let nonExistentId = UUID()

            try await app.test(
                .GET,
                "studies/\(studyId)/components/informational/\(nonExistentId)"
            ) { response in
                #expect(response.status == .notFound)
            }
        }
    }

    @Test
    func updateInformationalComponent() async throws {
        try await TestApp.withApp { app in
            let study = try await StudyFixtures.createStudy(on: app.db)
            let studyId = try study.requireID()

            let (component, _) = try await ComponentFixtures.createInformationalComponent(
                on: app.db,
                studyId: studyId,
                name: "Original Name"
            )
            let componentId = try component.requireID()

            try await app.test(
                .PUT,
                "studies/\(studyId)/components/informational/\(componentId)",
                beforeRequest: { req in
                    try req.encodeJSONBody(createRequestBody(name: "Updated Name"))
                }
            ) { response in
                #expect(response.status == .ok)

                let updated = try response.content.decode(
                    Components.Schemas.InformationalComponentResponse.self
                )
                #expect(updated.name == "Updated Name")
            }
        }
    }

    // MARK: - Helpers

    private func createRequestBody(name: String) -> [String: Any] {
        [
            "name": name,
            "data": [
                "en-US": [
                    "title": "Title",
                    "content": "Content"
                ]
            ]
        ]
    }
}
