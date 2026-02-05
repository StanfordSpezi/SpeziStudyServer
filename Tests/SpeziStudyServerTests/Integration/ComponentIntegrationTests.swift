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
struct ComponentIntegrationTests {
    @Test
    func listComponentsEmpty() async throws {
        try await TestApp.withApp { app in
            let study = try await StudyFixtures.createStudy(on: app.db)
            let studyId = try study.requireID()

            try await app.test(.GET, "studies/\(studyId)/components") { response in
                #expect(response.status == .ok)

                let components = try response.content.decode([Components.Schemas.Component].self)
                #expect(components.isEmpty)
            }
        }
    }

    @Test
    func listComponentsWithData() async throws {
        try await TestApp.withApp { app in
            let study = try await StudyFixtures.createStudy(on: app.db)
            let studyId = try study.requireID()

            try await ComponentFixtures.createHealthDataComponent(on: app.db, studyId: studyId)
            try await ComponentFixtures.createQuestionnaireComponent(on: app.db, studyId: studyId)
            try await ComponentFixtures.createInformationalComponent(on: app.db, studyId: studyId)

            try await app.test(.GET, "studies/\(studyId)/components") { response in
                #expect(response.status == .ok)

                let components = try response.content.decode([Components.Schemas.Component].self)
                #expect(components.count == 3)
            }
        }
    }

    @Test
    func listComponentsStudyNotFound() async throws {
        try await TestApp.withApp { app in
            let nonExistentId = UUID()

            try await app.test(.GET, "studies/\(nonExistentId)/components") { response in
                #expect(response.status == .notFound)
            }
        }
    }

    @Test
    func deleteComponent() async throws {
        try await TestApp.withApp { app in
            let study = try await StudyFixtures.createStudy(on: app.db)
            let studyId = try study.requireID()

            let (component, _) = try await ComponentFixtures.createHealthDataComponent(
                on: app.db,
                studyId: studyId
            )
            let componentId = try component.requireID()

            try await app.test(.DELETE, "studies/\(studyId)/components/\(componentId)") { response in
                #expect(response.status == .noContent)
            }

            // Verify deletion
            try await app.test(.GET, "studies/\(studyId)/components") { response in
                let components = try response.content.decode([Components.Schemas.Component].self)
                #expect(components.isEmpty)
            }
        }
    }

    @Test
    func deleteComponentNotFound() async throws {
        try await TestApp.withApp { app in
            let study = try await StudyFixtures.createStudy(on: app.db)
            let studyId = try study.requireID()
            let nonExistentId = UUID()

            try await app.test(.DELETE, "studies/\(studyId)/components/\(nonExistentId)") { response in
                #expect(response.status == .notFound)
            }
        }
    }

    @Test
    func deleteStudyCascadesComponents() async throws {
        try await TestApp.withApp { app in
            let study = try await StudyFixtures.createStudy(on: app.db)
            let studyId = try study.requireID()

            try await ComponentFixtures.createHealthDataComponent(on: app.db, studyId: studyId)

            // Delete the study
            try await app.test(.DELETE, "studies/\(studyId)") { response in
                #expect(response.status == .noContent)
            }

            // Components should be gone (cascade delete)
            let remainingComponents = try await Component.query(on: app.db).all()
            #expect(remainingComponents.isEmpty)
        }
    }
}
