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
struct HealthDataComponentIntegrationTests {
    @Test
    func createHealthDataComponent() async throws {
        try await TestApp.withApp { app in
            let study = try await StudyFixtures.createStudy(on: app.db)
            let studyId = try study.requireID()

            try await app.test(
                .POST,
                "studies/\(studyId)/components/health-data",
                beforeRequest: { req in
                    try req.encodeJSONBody(createRequestBody(name: "Heart Rate Collection"))
                }
            ) { response in
                #expect(response.status == .created)

                let component = try response.content.decode(
                    Components.Schemas.HealthDataComponentResponse.self
                )
                #expect(component.name == "Heart Rate Collection")
                #expect(component.id.isEmpty == false)
            }
        }
    }

    @Test
    func getHealthDataComponent() async throws {
        try await TestApp.withApp { app in
            let study = try await StudyFixtures.createStudy(on: app.db)
            let studyId = try study.requireID()

            let (component, _) = try await ComponentFixtures.createHealthDataComponent(
                on: app.db,
                studyId: studyId,
                name: "Test Health Data"
            )
            let componentId = try component.requireID()

            try await app.test(
                .GET,
                "studies/\(studyId)/components/health-data/\(componentId)"
            ) { response in
                #expect(response.status == .ok)

                let responseComponent = try response.content.decode(
                    Components.Schemas.HealthDataComponentResponse.self
                )
                #expect(responseComponent.id == componentId.uuidString)
                #expect(responseComponent.name == "Test Health Data")
            }
        }
    }

    @Test
    func getHealthDataComponentNotFound() async throws {
        try await TestApp.withApp { app in
            let study = try await StudyFixtures.createStudy(on: app.db)
            let studyId = try study.requireID()
            let nonExistentId = UUID()

            try await app.test(
                .GET,
                "studies/\(studyId)/components/health-data/\(nonExistentId)"
            ) { response in
                #expect(response.status == .notFound)
            }
        }
    }

    @Test
    func updateHealthDataComponent() async throws {
        try await TestApp.withApp { app in
            let study = try await StudyFixtures.createStudy(on: app.db)
            let studyId = try study.requireID()

            let (component, _) = try await ComponentFixtures.createHealthDataComponent(
                on: app.db,
                studyId: studyId,
                name: "Original Name"
            )
            let componentId = try component.requireID()

            try await app.test(
                .PUT,
                "studies/\(studyId)/components/health-data/\(componentId)",
                beforeRequest: { req in
                    try req.encodeJSONBody(createRequestBody(name: "Updated Name"))
                }
            ) { response in
                #expect(response.status == .ok)

                let updated = try response.content.decode(
                    Components.Schemas.HealthDataComponentResponse.self
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
                "sampleTypes": [
                    "HKQuantityType;HKQuantityTypeIdentifierHeartRate",
                    "HKQuantityType;HKQuantityTypeIdentifierStepCount"
                ],
                "historicalDataCollection": [
                    "enabled": false
                ]
            ]
        ]
    }
}
