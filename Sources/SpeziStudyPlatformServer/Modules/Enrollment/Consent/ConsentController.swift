//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import OpenAPIRuntime
import SpeziStudyPlatformAPIServer


extension Controller {
    func getParticipantEnrollmentsEnrollmentIdConsents(
        _ input: Operations.GetParticipantEnrollmentsEnrollmentIdConsents.Input
    ) async throws -> Operations.GetParticipantEnrollmentsEnrollmentIdConsents.Output {
        let enrollmentId = try input.path.enrollmentId.requireId()
        let records = try await consentService.listConsents(enrollmentId: enrollmentId)
        return .ok(.init(body: .json(try records.map { try .init($0) })))
    }

    func postParticipantEnrollmentsEnrollmentIdConsents(
        _ input: Operations.PostParticipantEnrollmentsEnrollmentIdConsents.Input
    ) async throws -> Operations.PostParticipantEnrollmentsEnrollmentIdConsents.Output {
        let enrollmentId = try input.path.enrollmentId.requireId()
        guard case .multipartForm(let multipartBody) = input.body else {
            throw ServerError.badRequest("Request body must be multipart/form-data")
        }

        var userResponses: UserResponses?
        var consentURL: URL?

        for try await part in multipartBody {
            switch part {
            case .consentData(let payload):
                userResponses = UserResponses(payload.payload.body)
            case .consentPDF(let payload):
                _ = try await Data(collecting: payload.payload.body, upTo: 10_000_000)
                consentURL = URL(string: "https://example.com/TODO")
            case .undocumented:
                break
            }
        }

        guard let userResponses, let consentURL else {
            throw ServerError.badRequest("Request must include both consentData and consentPDF parts")
        }

        let record = try await consentService.createConsent(
            enrollmentId: enrollmentId,
            userResponses: userResponses,
            consentURL: consentURL
        )
        return .created(.init(body: .json(try .init(record))))
    }
}
