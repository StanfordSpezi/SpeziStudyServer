//
// This source file is part of the SpeziStudyServer open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import SpeziHealthKit
import SpeziLocalization
@testable import SpeziStudyServer
import Testing
import VaporTesting


private let dummyUUID = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!

private enum EndpointRole: Sendable {
    /// Requires the researcher realm role. `minRole` controls the required group-level role.
    case researcher(minRole: AuthContext.GroupRole, requiresGroupAccess: Bool)
    /// Requires the participant realm role.
    case participant
}

private struct Endpoint: Sendable {
    let method: HTTPMethod
    let path: String
    let body: Data?
    let role: EndpointRole
    let successStatus: HTTPStatus

    var isParticipant: Bool {
        if case .participant = role {
            return true
        }
        return false
    }

    var requiresGroupAccess: Bool {
        if case .researcher(_, let requiresGroupAccess) = role {
            return requiresGroupAccess
        }
        return false
    }

    var minRole: AuthContext.GroupRole {
        if case .researcher(let minRole, _) = role {
            return minRole
        }
        return .researcher
    }
}

@Suite(.serialized)
struct AuthIntegrationTests {
    // MARK: - Static Helpers

    private static func researcher(
        _ method: HTTPMethod,
        _ path: String,
        body: Data? = nil,
        minRole: AuthContext.GroupRole = .researcher, // swiftlint:disable:this function_default_parameter_at_end
        successStatus: HTTPStatus,
        requiresGroupAccess: Bool = true
    ) -> Endpoint {
        Endpoint(
            method: method,
            path: path,
            body: body,
            role: .researcher(minRole: minRole, requiresGroupAccess: requiresGroupAccess),
            successStatus: successStatus
        )
    }

    private static func participant(
        _ method: HTTPMethod,
        _ path: String,
        body: Data? = nil, // swiftlint:disable:this function_default_parameter_at_end
        successStatus: HTTPStatus
    ) -> Endpoint {
        Endpoint(method: method, path: path, body: body, role: .participant, successStatus: successStatus)
    }


    // swiftlint:disable:next function_body_length
    private static func allEndpoints(
        groupId: UUID,
        studyId: UUID,
        componentId: UUID,
        scheduleId: UUID
    ) -> [Endpoint] {
        let informational = jsonData(Components.Schemas.InformationalComponentInput(
            name: "X",
            data: .init([.enUS: InformationalContent(title: "T", lede: nil, content: "C")])
        ))
        let questionnaire = jsonData(Components.Schemas.QuestionnaireComponentInput(
            name: "X",
            data: .init([.enUS: QuestionnaireContent(questionnaire: "{}")])
        ))
        let healthData = jsonData(Components.Schemas.HealthDataComponentInput(
            name: "X",
            data: .init(sampleTypes: [.quantity(.heartRate)], historicalDataCollection: .init())
        ))
        let scheduleBody = jsonData(scheduleBody())
        let dummyId = dummyUUID
        let base = apiBasePath

        return [
            // Groups
            researcher(.GET, "\(base)/groups", successStatus: .ok, requiresGroupAccess: false),
            researcher(.GET, "\(base)/groups/\(groupId)", successStatus: .ok),

            // Studies
            researcher(.GET, "\(base)/studies/\(studyId)/bundle", successStatus: .ok),
            researcher(.GET, "\(base)/studies/\(studyId)", successStatus: .ok),
            researcher(.GET, "\(base)/groups/\(groupId)/studies", successStatus: .ok),
            researcher(.PATCH, "\(base)/studies/\(studyId)", body: jsonData(patchBody()), successStatus: .ok),
            researcher(.POST, "\(base)/groups/\(groupId)/studies", body: jsonData(studyBody()), minRole: .admin, successStatus: .created),

            // Invitation Codes
            researcher(.GET, "\(base)/studies/\(studyId)/invitation-codes", successStatus: .ok),
            researcher(.POST, "\(base)/studies/\(studyId)/invitation-codes", body: jsonData(["count": 1] as [String: Any]), successStatus: .created),
            researcher(.DELETE, "\(base)/studies/\(studyId)/invitation-codes/\(dummyId)", successStatus: .notFound),

            // Studies — destructive + not yet implemented
            researcher(.DELETE, "\(base)/studies/\(studyId)", minRole: .admin, successStatus: .noContent),
            researcher(.POST, "\(base)/studies/\(studyId)/publish", minRole: .admin, successStatus: .notImplemented, requiresGroupAccess: false),
            researcher(.GET, "\(base)/studies/\(studyId)/published", successStatus: .notImplemented, requiresGroupAccess: false),
            researcher(.GET, "\(base)/studies/\(studyId)/enrollments", successStatus: .notImplemented, requiresGroupAccess: false),

            // Components
            researcher(.GET, "\(base)/studies/\(studyId)/components", successStatus: .ok),
            researcher(.GET, "\(base)/studies/\(studyId)/components/informational/\(componentId)", successStatus: .ok),
            researcher(.GET, "\(base)/studies/\(studyId)/components/questionnaire/\(componentId)", successStatus: .ok),
            researcher(.GET, "\(base)/studies/\(studyId)/components/health-data/\(componentId)", successStatus: .ok),
            researcher(.POST, "\(base)/studies/\(studyId)/components/informational", body: informational, successStatus: .created),
            researcher(.POST, "\(base)/studies/\(studyId)/components/questionnaire", body: questionnaire, successStatus: .created),
            researcher(.POST, "\(base)/studies/\(studyId)/components/health-data", body: healthData, successStatus: .created),
            researcher(.PUT, "\(base)/studies/\(studyId)/components/informational/\(componentId)", body: informational, successStatus: .ok),
            researcher(.PUT, "\(base)/studies/\(studyId)/components/questionnaire/\(componentId)", body: questionnaire, successStatus: .ok),
            researcher(.PUT, "\(base)/studies/\(studyId)/components/health-data/\(componentId)", body: healthData, successStatus: .ok),
            researcher(.DELETE, "\(base)/studies/\(studyId)/components/\(componentId)", successStatus: .noContent),

            // Component Schedules
            researcher(.GET, "\(base)/studies/\(studyId)/components/\(componentId)/schedules", successStatus: .ok),
            researcher(.POST, "\(base)/studies/\(studyId)/components/\(componentId)/schedules", body: scheduleBody, successStatus: .created),
            researcher(.GET, "\(base)/studies/\(studyId)/components/\(componentId)/schedules/\(scheduleId)", successStatus: .ok),
            researcher(.PUT, "\(base)/studies/\(studyId)/components/\(componentId)/schedules/\(scheduleId)", body: scheduleBody, successStatus: .ok),
            researcher(.DELETE, "\(base)/studies/\(studyId)/components/\(componentId)/schedules/\(scheduleId)", successStatus: .noContent),

            // Participant — profile & studies (fixture pre-created by participantAllowedActions)
            participant(.POST, "\(base)/participant/profile", body: jsonData(["firstName": "Jane"]), successStatus: .conflict),
            participant(.GET, "\(base)/participant/profile", successStatus: .ok),
            participant(.PUT, "\(base)/participant/profile", body: jsonData(["dateOfBirth": "2000-01-01"]), successStatus: .ok),
            participant(.GET, "\(base)/participant/studies", successStatus: .ok),
            participant(.POST, "\(base)/participant/enrollments", body: jsonData(["studyId": studyId.uuidString]), successStatus: .notImplemented),
            participant(.GET, "\(base)/participant/enrollments", successStatus: .notImplemented),
            participant(.POST, "\(base)/participant/enrollments/\(dummyId)/withdraw", successStatus: .notImplemented),
            participant(.GET, "\(base)/participant/enrollments/\(dummyId)/consents", successStatus: .notImplemented),
            participant(
                .POST,
                "\(base)/participant/enrollments/\(dummyId)/consents",
                body: jsonData(["consentURL": "https://example.com", "consentData": [:] as [String: Any]] as [String: Any]),
                successStatus: .notImplemented
            )
        ]
    }

    private static func normalizedRoutes(from app: Application) -> Set<String> {
        let healthRoute = "GET /\(apiBasePath)/health"
        return Set(
            app.routes.all.compactMap { route -> String? in
                let path = route.path
                    .map { component -> String in
                        switch component {
                        case .parameter:
                            return "*"
                        case .constant(let value):
                            return value
                        default:
                            return String(describing: component)
                        }
                    }
                    .joined(separator: "/")
                let normalized = "\(route.method.rawValue) /\(path)"
                return normalized == healthRoute ? nil : normalized
            }
        )
    }

    private static func normalizedTestedRoutes() -> Set<String> {
        Set(
            allEndpoints(groupId: dummyUUID, studyId: dummyUUID, componentId: dummyUUID, scheduleId: dummyUUID)
                .map { "\($0.method.rawValue) /\($0.path.replacingOccurrences(of: dummyUUID.uuidString, with: "*"))" }
        )
    }

    // MARK: - Auth Tests

    @Test
    func unauthenticatedReturns401() async throws {
        try await withFixtures(token: .none) { app, token, endpoints in
            for endpoint in endpoints {
                try await self.expectStatus(.unauthorized, for: endpoint, token: token, on: app)
            }
        }
    }

    @Test
    func wrongGroupReturns403() async throws {
        try await withFixtures(token: .researcher(groups: ["/Other Group/admin"])) { app, token, endpoints in
            for endpoint in endpoints where endpoint.requiresGroupAccess {
                try await self.expectStatus(.forbidden, for: endpoint, token: token, on: app)
            }
        }
    }

    @Test
    func researcherDeniedAdminActions() async throws {
        try await withFixtures(token: .researcher(groups: ["/Test Group/researcher"])) { app, token, endpoints in
            for endpoint in endpoints where endpoint.requiresGroupAccess && endpoint.minRole > .researcher {
                try await self.expectStatus(.forbidden, for: endpoint, token: token, on: app)
            }
        }
    }

    @Test
    func researcherAllowedActions() async throws {
        try await withFixtures(token: .researcher(groups: ["/Test Group/researcher"])) { app, token, endpoints in
            for endpoint in endpoints where endpoint.requiresGroupAccess && endpoint.minRole <= .researcher
                && !endpoint.path.contains("/components") {
                try await self.expectStatus(endpoint.successStatus, for: endpoint, token: token, on: app)
            }
        }
    }

    @Test
    func adminAllowedActions() async throws {
        try await withFixtures(token: .researcher(groups: ["/Test Group/admin"])) { app, token, endpoints in
            for endpoint in endpoints where endpoint.requiresGroupAccess && endpoint.minRole == .admin
                && !endpoint.path.contains("/components") {
                try await self.expectStatus(endpoint.successStatus, for: endpoint, token: token, on: app)
            }
        }
    }

    @Test
    func participantDeniedResearcherEndpoints() async throws {
        try await TestApp.withApp(token: .participant(subject: "participant-test-user")) { app, token in
            let endpoints = Self.allEndpoints(groupId: dummyUUID, studyId: dummyUUID, componentId: dummyUUID, scheduleId: dummyUUID)

            for endpoint in endpoints where !endpoint.isParticipant {
                try await self.expectStatus(.forbidden, for: endpoint, token: token, on: app)
            }
        }
    }

    @Test
    func researcherDeniedParticipantEndpoints() async throws {
        try await TestApp.withApp { app, token in
            let endpoints = Self.allEndpoints(groupId: dummyUUID, studyId: dummyUUID, componentId: dummyUUID, scheduleId: dummyUUID)

            for endpoint in endpoints where endpoint.isParticipant {
                try await self.expectStatus(.forbidden, for: endpoint, token: token, on: app)
            }
        }
    }

    @Test
    func participantAllowedActions() async throws {
        try await withFixtures(token: .participant(subject: "participant-test-user")) { app, token, endpoints in
            for endpoint in endpoints where endpoint.isParticipant {
                try await self.expectStatus(endpoint.successStatus, for: endpoint, token: token, on: app)
            }
        }
    }

    @Test
    func allAPIEndpointsCoveredByAuthTests() async throws {
        try await TestApp.withApp { app, _ in
            let registeredRoutes = Self.normalizedRoutes(from: app)
            let testedRoutes = Self.normalizedTestedRoutes()

            let missing = registeredRoutes.subtracting(testedRoutes)
            let extra = testedRoutes.subtracting(registeredRoutes)

            #expect(missing.isEmpty, "Routes missing from auth tests: \(missing.sorted())")
            #expect(extra.isEmpty, "Auth tests reference non-existent routes: \(extra.sorted())")
        }
    }

    // MARK: - Instance Helpers

    private func withFixtures(
        token tokenConfig: TestApp.Token,
        _ test: @escaping @Sendable (Application, String?, [Endpoint]) async throws -> Void
    ) async throws {
        try await TestApp.withApp(token: tokenConfig) { app, token in
            let group = try await GroupFixtures.createGroup(on: app.db)
            let groupId = try group.requireId()
            let study = try await StudyFixtures.createStudy(on: app.db, groupId: groupId)
            let studyId = try study.requireId()
            let component = try await ComponentFixtures.createHealthDataComponent(on: app.db, studyId: studyId)
            let componentId = try component.requireId()
            let schedule = try await ComponentFixtures.createSchedule(on: app.db, componentId: componentId)
            let scheduleId = try schedule.requireId()

            if case .participant(let subject) = tokenConfig {
                try await ParticipantFixtures.createParticipant(on: app.db, identityProviderId: subject)
            }

            try await test(app, token, Self.allEndpoints(
                groupId: groupId,
                studyId: studyId,
                componentId: componentId,
                scheduleId: scheduleId
            ))
        }
    }

    private func expectStatus(
        _ expected: HTTPStatus,
        for endpoint: Endpoint,
        token: String?,
        on app: Application
    ) async throws {
        try await app.test(endpoint.method, endpoint.path, beforeRequest: { req in
            req.bearerAuth(token)
            if let body = endpoint.body {
                req.headers.contentType = .json
                req.body = .init(data: body)
            }
        }) { response in
            #expect(response.status == expected, "Expected \(expected.code) for \(endpoint.method.rawValue) \(endpoint.path), got \(response.status.code)")
        }
    }
}


// MARK: - File-Private Helpers

private func jsonData(_ dict: [String: Any]) -> Data? {
    try? JSONSerialization.data(withJSONObject: dict)
}

private func jsonData(_ value: some Encodable) -> Data? {
    try? JSONEncoder().encode(value)
}

private func studyBody(title: String = "X") -> [String: Any] {
    ["title": title, "icon": "heart"] as [String: Any]
}

private func patchBody() -> [String: Any] {
    ["details": ["en-US": ["title": "Updated"] as [String: Any]] as [String: Any]] as [String: Any]
}

private func scheduleBody() -> [String: Any] {
    [
        "scheduleDefinition": [
            "type": "repeated",
            "pattern": ["type": "daily", "hour": 9] as [String: Any]
        ] as [String: Any],
        "completionPolicy": "anytime",
        "notification": false
    ] as [String: Any]
}
