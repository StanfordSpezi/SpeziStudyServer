//
// This source file is part of the SpeziStudyServer open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Fluent
import Foundation
import SQLKit
import Spezi


final class ProfileRepository: Module, Sendable {
    let database: any Database

    init(database: any Database) {
        self.database = database
    }

    func findByIdentityProviderId(_ id: String) async throws -> Participant? {
        try await Participant.query(on: database)
            .filter(\.$identityProviderId == id)
            .first()
    }

    func create(_ participant: Participant) async throws -> Participant {
        try await participant.save(on: database)

        guard let created = try await Participant.find(try participant.requireId(), on: database) else {
            throw ServerError.failedToRetrieveCreatedObject
        }

        return created
    }

    func update(_ participant: Participant) async throws {
        try await participant.update(on: database)
    }

    func listPublicPublishedStudies() async throws -> [PublishedStudy] {
        try await latestPublishedStudiesQuery()
            .filter(\.$visibility == .public)
            .all()
    }

    func findPublishedStudyByInvitationCode(_ code: String) async throws -> PublishedStudy? {
        guard let invitationCode = try await findInvitationCode(code) else {
            return nil
        }

        return try await latestPublishedStudiesQuery()
            .filter(\.$study.$id == invitationCode.$study.id)
            .first()
    }

    func findInvitationCode(_ code: String) async throws -> InvitationCode? {
        try await InvitationCode.query(on: database)
            .filter(\.$code == code)
            .filter(\.$redeemedAt == nil)
            .group(.or) { group in
                group.filter(\.$expiresAt == nil)
                group.filter(\.$expiresAt > Date())
            }
            .first()
    }

    /// Returns a query for published studies filtered to only the latest revision per study.
    private func latestPublishedStudiesQuery() -> QueryBuilder<PublishedStudy> {
        PublishedStudy.query(on: database)
            .filter(.custom(SQLRaw("""
                "revision" = (
                    SELECT MAX("revision")
                    FROM "published_studies"
                    WHERE "study_id" = "published_studies"."study_id"
                )
                """)))
    }
}
