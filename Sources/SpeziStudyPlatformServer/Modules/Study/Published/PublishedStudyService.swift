//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Fluent
import Foundation
import Spezi


final class PublishedStudyService: Module, @unchecked Sendable {
    @Dependency(PublishedStudyRepository.self) var repository
    @Dependency(StudyService.self) var studyService
    @Dependency(StudyBundleService.self) var studyBundleService
    @Dependency(InvitationCodeRepository.self) var invitationCodeRepository

    func publish(studyId: UUID) async throws -> PublishedStudy {
        try await studyService.checkHasAccess(to: studyId, role: .admin)

        let study = try await studyService.getStudy(id: studyId)
        
        let maxRevision = try await repository.maxRevision(forStudyId: studyId)
        let nextRevision = (maxRevision ?? 0) + 1

        let (metadata, _) = try await studyBundleService.buildMetadata(from: study)

        _ = try await studyBundleService.buildBundle(studyId: studyId, revision: nextRevision)
        guard let bundleURL = URL(string: "https://example.com/TODO") else {
            throw ServerError.internalServerError("Failed to construct bundle URL")
        }
        let published = PublishedStudy(
            studyId: studyId,
            revision: nextRevision,
            visibility: study.visibility,
            enrollmentCondition: study.enrollmentCondition,
            bundleURL: bundleURL,
            metadata: metadata
        )

        do {
            return try await repository.create(published)
        } catch where (error as? any DatabaseError)?.isConstraintFailure == true {
            throw ServerError.conflict("Study revision \(nextRevision) already exists")
        }
    }

    func listPublished(studyId: UUID) async throws -> [PublishedStudy] {
        try await studyService.checkHasAccess(to: studyId, role: .researcher)
        return try await repository.listByStudyId(studyId)
    }

    func browseStudies(code: String?) async throws -> [PublishedStudy] {
        try AuthContext.checkIsParticipant()

        if let code {
            guard let invitationCode = try await invitationCodeRepository.findValid(code: code) else {
                return []
            }
            guard let published = try await repository.findLatestPublished(forStudyId: invitationCode.$study.id) else {
                return []
            }
            return [published]
        }

        return try await repository.listLatestPublicStudies()
    }
}
