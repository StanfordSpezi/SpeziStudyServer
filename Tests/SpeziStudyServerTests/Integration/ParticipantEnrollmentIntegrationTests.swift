//
// This source file is part of the SpeziStudyServer open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import SpeziStudyDefinition
@testable import SpeziStudyServer
import Testing
import VaporTesting


@Suite(.serialized)
struct ParticipantEnrollmentIntegrationTests { // swiftlint:disable:this type_body_length
    private static let participantSubject = "enrollment-test-participant"

    // MARK: - Enroll

    @Test
    func enrollReturnsCreated() async throws {
        try await TestApp.withApp(token: .participant(subject: Self.participantSubject)) { app, token in
            let (studyId, _) = try await setUpPublishedStudy(on: app)
            try await ParticipantFixtures.createParticipant(on: app.db, identityProviderId: Self.participantSubject)

            try await app.test(.POST, "\(apiBasePath)/participant/enrollments", beforeRequest: { req in
                req.bearerAuth(token)
                try req.encodeJSONBody(["studyId": studyId.uuidString])
            }) { response in
                #expect(response.status == .created)

                let enrollment = try response.content.decode(Components.Schemas.EnrollmentResponse.self)
                #expect(enrollment.studyId == studyId.uuidString)
                #expect(enrollment.currentRevision == 1)
                #expect(enrollment.withdrawnAt == nil)
            }
        }
    }

    @Test
    func enrollDuplicateReturnsConflict() async throws {
        try await TestApp.withApp(token: .participant(subject: Self.participantSubject)) { app, token in
            let (studyId, _) = try await setUpPublishedStudy(on: app)
            try await ParticipantFixtures.createParticipant(on: app.db, identityProviderId: Self.participantSubject)

            try await app.test(.POST, "\(apiBasePath)/participant/enrollments", beforeRequest: { req in
                req.bearerAuth(token)
                try req.encodeJSONBody(["studyId": studyId.uuidString])
            }) { response in
                #expect(response.status == .created)
            }

            try await app.test(.POST, "\(apiBasePath)/participant/enrollments", beforeRequest: { req in
                req.bearerAuth(token)
                try req.encodeJSONBody(["studyId": studyId.uuidString])
            }) { response in
                #expect(response.status == .conflict)
            }
        }
    }

    @Test
    func enrollNoPublishedStudyReturnsNotFound() async throws {
        try await TestApp.withApp(token: .participant(subject: Self.participantSubject)) { app, token in
            let group = try await GroupFixtures.createGroup(on: app.db)
            let study = try await StudyFixtures.createStudy(on: app.db, groupId: try group.requireId())
            let studyId = try study.requireId()
            try await ParticipantFixtures.createParticipant(on: app.db, identityProviderId: Self.participantSubject)

            try await app.test(.POST, "\(apiBasePath)/participant/enrollments", beforeRequest: { req in
                req.bearerAuth(token)
                try req.encodeJSONBody(["studyId": studyId.uuidString])
            }) { response in
                #expect(response.status == .notFound)
            }
        }
    }

    @Test
    func enrollWithInvitationCode() async throws {
        try await TestApp.withApp(token: .participant(subject: Self.participantSubject)) { app, token in
            let (studyId, study) = try await setUpPublishedStudy(on: app, enrollmentConditions: .requiresInvitation(
                verificationEndpoint: URL(string: "https://example.com")! // swiftlint:disable:this force_unwrapping
            ))
            try await ParticipantFixtures.createParticipant(on: app.db, identityProviderId: Self.participantSubject)

            let code = InvitationCode(studyId: studyId, code: "ENRL-CODE")
            try await code.save(on: app.db)

            try await app.test(.POST, "\(apiBasePath)/participant/enrollments", beforeRequest: { req in
                req.bearerAuth(token)
                try req.encodeJSONBody(["studyId": studyId.uuidString, "invitationCode": "ENRL-CODE"])
            }) { response in
                #expect(response.status == .created)
            }
        }
    }

    @Test
    func enrollWithoutRequiredCodeReturnsBadRequest() async throws {
        try await TestApp.withApp(token: .participant(subject: Self.participantSubject)) { app, token in
            let (studyId, _) = try await setUpPublishedStudy(on: app, enrollmentConditions: .requiresInvitation(
                // TODO:
                verificationEndpoint: URL(string: "https://example.com")! // swiftlint:disable:this force_unwrapping
            ))
            try await ParticipantFixtures.createParticipant(on: app.db, identityProviderId: Self.participantSubject)

            try await app.test(.POST, "\(apiBasePath)/participant/enrollments", beforeRequest: { req in
                req.bearerAuth(token)
                try req.encodeJSONBody(["studyId": studyId.uuidString])
            }) { response in
                #expect(response.status == .badRequest)
            }
        }
    }

    // MARK: - List Enrollments

    @Test
    func listEnrollmentsEmpty() async throws {
        try await TestApp.withApp(token: .participant(subject: Self.participantSubject)) { app, token in
            try await ParticipantFixtures.createParticipant(on: app.db, identityProviderId: Self.participantSubject)

            try await app.test(.GET, "\(apiBasePath)/participant/enrollments", beforeRequest: { req in
                req.bearerAuth(token)
            }) { response in
                #expect(response.status == .ok)

                let enrollments = try response.content.decode([Components.Schemas.EnrollmentResponse].self)
                #expect(enrollments.isEmpty)
            }
        }
    }

    @Test
    func listEnrollmentsReturnsAll() async throws {
        try await TestApp.withApp(token: .participant(subject: Self.participantSubject)) { app, token in
            let (studyId, _) = try await setUpPublishedStudy(on: app)
            try await ParticipantFixtures.createParticipant(on: app.db, identityProviderId: Self.participantSubject)

            try await app.test(.POST, "\(apiBasePath)/participant/enrollments", beforeRequest: { req in
                req.bearerAuth(token)
                try req.encodeJSONBody(["studyId": studyId.uuidString])
            }) { _ in }

            try await app.test(.GET, "\(apiBasePath)/participant/enrollments", beforeRequest: { req in
                req.bearerAuth(token)
            }) { response in
                #expect(response.status == .ok)

                let enrollments = try response.content.decode([Components.Schemas.EnrollmentResponse].self)
                #expect(enrollments.count == 1)
            }
        }
    }

    // MARK: - Withdraw

    @Test
    func withdrawReturnsOk() async throws {
        try await TestApp.withApp(token: .participant(subject: Self.participantSubject)) { app, token in
            let (studyId, _) = try await setUpPublishedStudy(on: app)
            try await ParticipantFixtures.createParticipant(on: app.db, identityProviderId: Self.participantSubject)

            var enrollmentId: String = ""
            try await app.test(.POST, "\(apiBasePath)/participant/enrollments", beforeRequest: { req in
                req.bearerAuth(token)
                try req.encodeJSONBody(["studyId": studyId.uuidString])
            }) { response in
                let enrollment = try response.content.decode(Components.Schemas.EnrollmentResponse.self)
                enrollmentId = enrollment.id
            }

            try await app.test(.POST, "\(apiBasePath)/participant/enrollments/\(enrollmentId)/withdraw", beforeRequest: { req in
                req.bearerAuth(token)
            }) { response in
                #expect(response.status == .ok)

                let enrollment = try response.content.decode(Components.Schemas.EnrollmentResponse.self)
                #expect(enrollment.withdrawnAt != nil)
            }
        }
    }

    @Test
    func withdrawAlreadyWithdrawnReturnsConflict() async throws {
        try await TestApp.withApp(token: .participant(subject: Self.participantSubject)) { app, token in
            let (studyId, _) = try await setUpPublishedStudy(on: app)
            try await ParticipantFixtures.createParticipant(on: app.db, identityProviderId: Self.participantSubject)

            var enrollmentId: String = ""
            try await app.test(.POST, "\(apiBasePath)/participant/enrollments", beforeRequest: { req in
                req.bearerAuth(token)
                try req.encodeJSONBody(["studyId": studyId.uuidString])
            }) { response in
                let enrollment = try response.content.decode(Components.Schemas.EnrollmentResponse.self)
                enrollmentId = enrollment.id
            }

            try await app.test(.POST, "\(apiBasePath)/participant/enrollments/\(enrollmentId)/withdraw", beforeRequest: { req in
                req.bearerAuth(token)
            }) { _ in }

            try await app.test(.POST, "\(apiBasePath)/participant/enrollments/\(enrollmentId)/withdraw", beforeRequest: { req in
                req.bearerAuth(token)
            }) { response in
                #expect(response.status == .conflict)
            }
        }
    }

    @Test
    func withdrawNotFoundReturnsNotFound() async throws {
        try await TestApp.withApp(token: .participant(subject: Self.participantSubject)) { app, token in
            try await ParticipantFixtures.createParticipant(on: app.db, identityProviderId: Self.participantSubject)

            try await app.test(.POST, "\(apiBasePath)/participant/enrollments/\(UUID())/withdraw", beforeRequest: { req in
                req.bearerAuth(token)
            }) { response in
                #expect(response.status == .notFound)
            }
        }
    }

    // MARK: - Cross-Participant Access

    @Test
    func otherParticipantCannotWithdrawEnrollment() async throws {
        let otherSubject = "other-participant"
        try await TestApp.withApp(token: .participant(subject: otherSubject)) { app, token in
            let (studyId, _) = try await setUpPublishedStudy(on: app)

            let participantA = try await ParticipantFixtures.createParticipant(on: app.db, identityProviderId: Self.participantSubject)
            let enrollment = Enrollment(participantId: try participantA.requireId(), studyId: studyId, currentRevision: 1)
            try await enrollment.save(on: app.db)
            let enrollmentId = try enrollment.requireId()

            try await ParticipantFixtures.createParticipant(on: app.db, identityProviderId: otherSubject)

            try await app.test(.POST, "\(apiBasePath)/participant/enrollments/\(enrollmentId)/withdraw", beforeRequest: { req in
                req.bearerAuth(token)
            }) { response in
                #expect(response.status == .notFound)
            }
        }
    }

    @Test
    func otherParticipantCannotListConsents() async throws {
        let otherSubject = "other-participant"
        try await TestApp.withApp(token: .participant(subject: otherSubject)) { app, token in
            let (studyId, _) = try await setUpPublishedStudy(on: app)

            let participantA = try await ParticipantFixtures.createParticipant(on: app.db, identityProviderId: Self.participantSubject)
            let enrollment = Enrollment(participantId: try participantA.requireId(), studyId: studyId, currentRevision: 1)
            try await enrollment.save(on: app.db)
            let enrollmentId = try enrollment.requireId()

            try await ParticipantFixtures.createParticipant(on: app.db, identityProviderId: otherSubject)

            try await app.test(.GET, "\(apiBasePath)/participant/enrollments/\(enrollmentId)/consents", beforeRequest: { req in
                req.bearerAuth(token)
            }) { response in
                #expect(response.status == .notFound)
            }
        }
    }

    // MARK: - Consents

    @Test
    func listConsentsEmpty() async throws {
        try await TestApp.withApp(token: .participant(subject: Self.participantSubject)) { app, token in
            let (studyId, _) = try await setUpPublishedStudy(on: app)
            try await ParticipantFixtures.createParticipant(on: app.db, identityProviderId: Self.participantSubject)

            var enrollmentId: String = ""
            try await app.test(.POST, "\(apiBasePath)/participant/enrollments", beforeRequest: { req in
                req.bearerAuth(token)
                try req.encodeJSONBody(["studyId": studyId.uuidString])
            }) { response in
                let enrollment = try response.content.decode(Components.Schemas.EnrollmentResponse.self)
                enrollmentId = enrollment.id
            }

            try await app.test(.GET, "\(apiBasePath)/participant/enrollments/\(enrollmentId)/consents", beforeRequest: { req in
                req.bearerAuth(token)
            }) { response in
                #expect(response.status == .ok)

                let consents = try response.content.decode([Components.Schemas.ConsentRecordResponse].self)
                #expect(consents.isEmpty)
            }
        }
    }

    @Test
    func createConsentReturnsCreated() async throws {
        try await TestApp.withApp(token: .participant(subject: Self.participantSubject)) { app, token in
            let (studyId, _) = try await setUpPublishedStudy(on: app)
            try await ParticipantFixtures.createParticipant(on: app.db, identityProviderId: Self.participantSubject)

            var enrollmentId: String = ""
            try await app.test(.POST, "\(apiBasePath)/participant/enrollments", beforeRequest: { req in
                req.bearerAuth(token)
                try req.encodeJSONBody(["studyId": studyId.uuidString])
            }) { response in
                let enrollment = try response.content.decode(Components.Schemas.EnrollmentResponse.self)
                enrollmentId = enrollment.id
            }

            try await app.test(.POST, "\(apiBasePath)/participant/enrollments/\(enrollmentId)/consents", beforeRequest: { req in
                req.bearerAuth(token)
                try req.encodeMultipartConsentBody(consentData: consentDataJSON(
                    toggles: ["agree_data_use": true],
                    givenName: "Jane",
                    familyName: "Doe"
                ))
            }) { response in
                #expect(response.status == .created)

                let consent = try response.content.decode(Components.Schemas.ConsentRecordResponse.self)
                #expect(consent.enrollmentId == enrollmentId)
                #expect(consent.revision == 1)
                #expect(consent.consentData.revision == 1)
                #expect(consent.consentData.userResponses.toggles?.additionalProperties["agree_data_use"] == true)
                #expect(!consent.pdfURL.isEmpty)
            }
        }
    }

    @Test
    func listConsentsReturnsAll() async throws {
        try await TestApp.withApp(token: .participant(subject: Self.participantSubject)) { app, token in
            let (studyId, _) = try await setUpPublishedStudy(on: app)
            try await ParticipantFixtures.createParticipant(on: app.db, identityProviderId: Self.participantSubject)

            var enrollmentId: String = ""
            try await app.test(.POST, "\(apiBasePath)/participant/enrollments", beforeRequest: { req in
                req.bearerAuth(token)
                try req.encodeJSONBody(["studyId": studyId.uuidString])
            }) { response in
                let enrollment = try response.content.decode(Components.Schemas.EnrollmentResponse.self)
                enrollmentId = enrollment.id
            }

            try await app.test(.POST, "\(apiBasePath)/participant/enrollments/\(enrollmentId)/consents", beforeRequest: { req in
                req.bearerAuth(token)
                try req.encodeMultipartConsentBody(consentData: consentDataJSON())
            }) { _ in }

            try await app.test(.GET, "\(apiBasePath)/participant/enrollments/\(enrollmentId)/consents", beforeRequest: { req in
                req.bearerAuth(token)
            }) { response in
                #expect(response.status == .ok)

                let consents = try response.content.decode([Components.Schemas.ConsentRecordResponse].self)
                #expect(consents.count == 1)
            }
        }
    }

    // MARK: - Helpers

    @discardableResult
    private func setUpPublishedStudy(
        on app: Application,
        enrollmentConditions: StudyDefinition.EnrollmentConditions = .none
    ) async throws -> (UUID, Study) {
        let group = try await GroupFixtures.createGroup(on: app.db)
        let study = Study(
            groupId: try group.requireId(),
            locales: [.enUS],
            icon: "heart",
            details: .init([.enUS: StudyDetailContent(title: "Test Study")]),
            enrollmentConditions: enrollmentConditions
        )
        try await study.save(on: app.db)
        let studyId = try study.requireId()
        try await PublishedStudyFixtures.createPublishedStudy(on: app.db, studyId: studyId, enrollmentConditions: enrollmentConditions)
        return (studyId, study)
    }

    private func consentDataJSON(
        toggles: [String: Bool] = [:],
        selects: [String: String] = [:],
        givenName: String = "Jane",
        familyName: String = "Doe"
    ) -> [String: Any] {
        [
            "toggles": toggles,
            "selects": selects,
            "signatures": [
                "primary": [
                    "name": ["givenName": givenName, "familyName": familyName],
                    "signature": "",
                    "size": [0, 0]
                ] as [String: Any]
            ] as [String: Any]
        ] as [String: Any]
    }
}
