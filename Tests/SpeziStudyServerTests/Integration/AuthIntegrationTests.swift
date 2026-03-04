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


@Suite(.serialized)
struct AuthIntegrationTests {
    private struct Endpoint: Sendable {
        let method: HTTPMethod
        let path: String
        let body: Data?
        let minRole: AuthContext.GroupRole
        let successStatus: HTTPStatus

        init( // swiftlint:disable:next function_default_parameter_at_end
            method: HTTPMethod, path: String, body: Data? = nil, minRole: AuthContext.GroupRole, successStatus: HTTPStatus
        ) {
            self.method = method
            self.path = path
            self.body = body
            self.minRole = minRole
            self.successStatus = successStatus
        }
    }

    // MARK: - Endpoint Definitions

    private static func allEndpoints(groupId: UUID, studyId: UUID, componentId: UUID) -> [Endpoint] {
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

        return [
            // Groups (GET /groups is excluded — it returns an empty list, not 403)
            .init(method: .GET, path: "\(apiBasePath)/groups/\(groupId)", minRole: .researcher, successStatus: .ok),

            // Studies
            .init(method: .GET, path: "\(apiBasePath)/studies/\(studyId)", minRole: .researcher, successStatus: .ok),
            .init(method: .GET, path: "\(apiBasePath)/groups/\(groupId)/studies", minRole: .researcher, successStatus: .ok),
            .init(method: .PATCH, path: "\(apiBasePath)/studies/\(studyId)", body: jsonData(patchBody()), minRole: .researcher, successStatus: .ok),
            .init(method: .POST, path: "\(apiBasePath)/groups/\(groupId)/studies", body: jsonData(studyBody()), minRole: .admin, successStatus: .created),
            .init(method: .DELETE, path: "\(apiBasePath)/studies/\(studyId)", minRole: .admin, successStatus: .noContent),

            // Components
            .init(method: .GET, path: "\(apiBasePath)/studies/\(studyId)/components", minRole: .researcher, successStatus: .ok),
            .init(method: .GET, path: "\(apiBasePath)/studies/\(studyId)/components/informational/\(componentId)", minRole: .researcher, successStatus: .ok),
            .init(method: .GET, path: "\(apiBasePath)/studies/\(studyId)/components/questionnaire/\(componentId)", minRole: .researcher, successStatus: .ok),
            .init(method: .GET, path: "\(apiBasePath)/studies/\(studyId)/components/health-data/\(componentId)", minRole: .researcher, successStatus: .ok),
            .init(method: .POST, path: "\(apiBasePath)/studies/\(studyId)/components/informational", body: informational, minRole: .researcher, successStatus: .created),
            .init(method: .POST, path: "\(apiBasePath)/studies/\(studyId)/components/questionnaire", body: questionnaire, minRole: .researcher, successStatus: .created),
            .init(method: .POST, path: "\(apiBasePath)/studies/\(studyId)/components/health-data", body: healthData, minRole: .researcher, successStatus: .created),
            .init(method: .PUT, path: "\(apiBasePath)/studies/\(studyId)/components/informational/\(componentId)", body: informational, minRole: .researcher, successStatus: .ok),
            .init(method: .PUT, path: "\(apiBasePath)/studies/\(studyId)/components/questionnaire/\(componentId)", body: questionnaire, minRole: .researcher, successStatus: .ok),
            .init(method: .PUT, path: "\(apiBasePath)/studies/\(studyId)/components/health-data/\(componentId)", body: healthData, minRole: .researcher, successStatus: .ok),
            .init(method: .DELETE, path: "\(apiBasePath)/studies/\(studyId)/components/\(componentId)", minRole: .researcher, successStatus: .noContent)
        ]
    }

    private static func jsonData(_ dict: [String: Any]) -> Data? {
        try? JSONSerialization.data(withJSONObject: dict)
    }

    private static func jsonData(_ value: some Encodable) -> Data? {
        try? JSONEncoder().encode(value)
    }

    private static func studyBody(title: String = "X") -> [String: Any] {
        [
            "title": title,
            "icon": "heart"
        ] as [String: Any]
    }

    private static func patchBody() -> [String: Any] {
        [
            "details": ["en-US": ["title": "Updated"] as [String: Any]] as [String: Any]
        ] as [String: Any]
    }

    // MARK: - Auth Tests

    @Test
    func unauthenticatedReturns401() async throws {
        try await withFixtures(groups: nil) { app, token, endpoints in
            for endpoint in endpoints {
                try await self.expectStatus(.unauthorized, for: endpoint, token: token, on: app)
            }
        }
    }

    @Test
    func wrongGroupReturns403() async throws {
        try await withFixtures(groups: ["/Other Group/admin"]) { app, token, endpoints in
            for endpoint in endpoints {
                try await self.expectStatus(.forbidden, for: endpoint, token: token, on: app)
            }
        }
    }

    @Test
    func researcherDeniedAdminActions() async throws {
        try await withFixtures(groups: ["/Test Group/researcher"]) { app, token, endpoints in
            for endpoint in endpoints where endpoint.minRole > .researcher {
                try await self.expectStatus(.forbidden, for: endpoint, token: token, on: app)
            }
        }
    }

    @Test
    func researcherAllowedActions() async throws {
        try await withFixtures(groups: ["/Test Group/researcher"]) { app, token, endpoints in
            for endpoint in endpoints where endpoint.minRole <= .researcher && !endpoint.path.contains("/components") {
                try await self.expectStatus(endpoint.successStatus, for: endpoint, token: token, on: app)
            }
        }
    }

    @Test
    func adminAllowedActions() async throws {
        try await withFixtures(groups: ["/Test Group/admin"]) { app, token, endpoints in
            for endpoint in endpoints where endpoint.minRole == .admin && !endpoint.path.contains("/components") {
                try await self.expectStatus(endpoint.successStatus, for: endpoint, token: token, on: app)
            }
        }
    }

    // MARK: - Helpers

    private func withFixtures( // swiftlint:disable:next discouraged_optional_collection
        groups: [String]?,
        _ test: @escaping @Sendable (Application, String?, [Endpoint]) async throws -> Void
    ) async throws {
        try await TestApp.withApp(groups: groups) { app, token in
            let group = try await GroupFixtures.createGroup(on: app.db)
            let groupId = try group.requireId()
            let study = try await StudyFixtures.createStudy(on: app.db, groupId: groupId)
            let studyId = try study.requireId()
            let (component, _) = try await ComponentFixtures.createHealthDataComponent(on: app.db, studyId: studyId)
            let componentId = try component.requireId()
            try await test(app, token, Self.allEndpoints(groupId: groupId, studyId: studyId, componentId: componentId))
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
            #expect(response.status == expected, "Expected \(expected.code) for \(endpoint.method) /\(endpoint.path)")
        }
    }
}
