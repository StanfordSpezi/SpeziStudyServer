//
// This source file is part of the SpeziStudyServer open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Fluent
import Foundation
import Spezi


final class InvitationCodeRepository: Module, Sendable {
    let database: any Database

    init(database: any Database) {
        self.database = database
    }

    func listByStudyId(_ studyId: UUID) async throws -> [InvitationCode] {
        try await InvitationCode.query(on: database)
            .filter(\.$study.$id == studyId)
            .all()
    }

    func codeExists(_ code: String) async throws -> Bool {
        try await InvitationCode.query(on: database)
            .filter(\.$code == code)
            .count() > 0
    }

    func find(id: UUID) async throws -> InvitationCode? {
        try await InvitationCode.find(id, on: database)
    }

    func create(_ codes: [InvitationCode]) async throws -> [InvitationCode] {
        for code in codes {
            try await code.save(on: database)
        }

        let ids = try codes.map { try $0.requireId() }
        return try await InvitationCode.query(on: database)
            .filter(\.$id ~~ ids)
            .all()
    }

    func delete(_ code: InvitationCode) async throws {
        try await code.delete(on: database)
    }

    func redeemInvitationCode(_ code: String, studyId: UUID) async throws {
        let invitationCode = try await InvitationCode.query(on: database)
            .filter(\.$code == code)
            .filter(\.$study.$id == studyId)
            .filter(\.$redeemedAt == nil)
            .group(.or) { group in
                group.filter(\.$expiresAt == nil)
                group.filter(\.$expiresAt > Date())
            }
            .first()

        guard let invitationCode else {
            throw ServerError.badRequest("Invalid or expired invitation code")
        }

        invitationCode.redeemedAt = Date()
        try await invitationCode.save(on: database)
    }

    func linkInvitationCode(_ code: String, toEnrollmentId enrollmentId: UUID, studyId: UUID) async throws {
        guard let invitationCode = try await InvitationCode.query(on: database)
            .filter(\.$code == code)
            .filter(\.$study.$id == studyId)
            .first() else {
            return
        }

        invitationCode.$enrollment.id = enrollmentId
        try await invitationCode.save(on: database)
    }
}
