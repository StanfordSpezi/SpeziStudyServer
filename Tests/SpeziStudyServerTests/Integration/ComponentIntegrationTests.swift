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
            let group = try await ResearchGroupFixtures.createResearchGroup(on: app.db)
            let study = try await StudyFixtures.createStudy(on: app.db, researchGroupId: try group.requireId())
            let studyId = try study.requireId()

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
            let group = try await ResearchGroupFixtures.createResearchGroup(on: app.db)
            let study = try await StudyFixtures.createStudy(on: app.db, researchGroupId: try group.requireId())
            let studyId = try study.requireId()

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
            let group = try await ResearchGroupFixtures.createResearchGroup(on: app.db)
            let study = try await StudyFixtures.createStudy(on: app.db, researchGroupId: try group.requireId())
            let studyId = try study.requireId()

            let (component, _) = try await ComponentFixtures.createHealthDataComponent(
                on: app.db,
                studyId: studyId
            )
            let componentId = try component.requireId()

            try await app.test(.DELETE, "studies/\(studyId)/components/\(componentId)") { response in
                #expect(response.status == .noContent)
            }

            try await app.test(.GET, "studies/\(studyId)/components") { response in
                let components = try response.content.decode([Components.Schemas.Component].self)
                #expect(components.isEmpty)
            }
        }
    }

    @Test
    func deleteComponentNotFound() async throws {
        try await TestApp.withApp { app in
            let group = try await ResearchGroupFixtures.createResearchGroup(on: app.db)
            let study = try await StudyFixtures.createStudy(on: app.db, researchGroupId: try group.requireId())
            let studyId = try study.requireId()
            let nonExistentId = UUID()

            try await app.test(.DELETE, "studies/\(studyId)/components/\(nonExistentId)") { response in
                #expect(response.status == .notFound)
            }
        }
    }

    @Test
    func deleteStudyCascadesComponents() async throws {
        try await TestApp.withApp { app in
            let group = try await ResearchGroupFixtures.createResearchGroup(on: app.db)
            let study = try await StudyFixtures.createStudy(on: app.db, researchGroupId: try group.requireId())
            let studyId = try study.requireId()

            try await ComponentFixtures.createHealthDataComponent(on: app.db, studyId: studyId)

            try await app.test(.DELETE, "studies/\(studyId)") { response in
                #expect(response.status == .noContent)
            }

            let remainingComponents = try await Component.query(on: app.db).all()
            #expect(remainingComponents.isEmpty)
        }
    }
}
