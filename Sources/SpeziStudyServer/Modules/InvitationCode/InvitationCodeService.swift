//
// This source file is part of the SpeziStudyServer open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import Spezi


final class InvitationCodeService: Module, @unchecked Sendable {
    @Dependency(InvitationCodeRepository.self) var repository: InvitationCodeRepository
    @Dependency(StudyService.self) var studyService: StudyService

    init() {}

    func listCodes(studyId: UUID) async throws -> [InvitationCode] {
        try await studyService.checkHasAccess(to: studyId, role: .researcher)
        return try await repository.listByStudyId(studyId)
    }

    func createCodes(studyId: UUID, count: Int, expiresAt: Date?) async throws -> [InvitationCode] {
        try await studyService.checkHasAccess(to: studyId, role: .researcher)

        let context = try AuthContext.checkIsResearcher()
        var codes: [InvitationCode] = []
        var generatedCodes: Set<String> = []

        for _ in 0..<count {
            let code = try await generateUniqueCode(excluding: &generatedCodes)
            codes.append(InvitationCode(
                studyId: studyId,
                code: code,
                issuedBy: context.subject,
                expiresAt: expiresAt
            ))
        }

        return try await repository.create(codes)
    }

    func deleteCode(studyId: UUID, codeId: UUID) async throws {
        try await studyService.checkHasAccess(to: studyId, role: .researcher)

        guard let code = try await repository.find(id: codeId) else {
            throw ServerError.notFound(resource: "InvitationCode", identifier: codeId.uuidString)
        }

        if code.redeemedAt != nil {
            throw ServerError.conflict("Cannot delete an invitation code that has already been redeemed")
        }

        try await repository.delete(code)
    }

    private func generateUniqueCode(excluding batchCodes: inout Set<String>) async throws -> String {
        for _ in 0..<10 {
            let code = Self.generateCode()
            guard batchCodes.insert(code).inserted else {
                continue
            }
            if try await repository.codeExists(code) {
                batchCodes.remove(code)
                continue
            }
            return code
        }
        throw ServerError.internalServerError("Failed to generate a unique invitation code")
    }

    private static func generateCode() -> String {
        let characters = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
        let raw = (0..<8).map { _ in characters.randomElement()! }
        return "\(String(raw[0..<4]))-\(String(raw[4..<8]))"
    }
}
