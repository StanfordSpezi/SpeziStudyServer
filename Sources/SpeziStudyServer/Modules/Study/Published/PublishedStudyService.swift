//
// This source file is part of the SpeziStudyServer open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import Spezi


final class PublishedStudyService: Module, @unchecked Sendable {
    @Dependency(PublishedStudyRepository.self) var repository
    @Dependency(StudyService.self) var studyService
    @Dependency(StudyBundleService.self) var studyBundleService

    init() {}

    func publish(studyId: UUID) async throws -> PublishedStudy {
        try await studyService.checkHasAccess(to: studyId, role: .admin)

        let study = try await studyService.getStudy(id: studyId)
        let nextRevision = (try await repository.maxRevision(forStudyId: studyId) ?? 0) + 1

        let (metadata, _) = try await studyBundleService.buildMetadata(from: study)
        
        // TODO: Upload bundle and store real URL
        let bundleURL = URL(string: "https://example.com/TODO")! // swiftlint:disable:this force_unwrapping
        let published = PublishedStudy(
            studyId: studyId,
            revision: nextRevision,
            visibility: .public,
            bundleURL: bundleURL,
            metadata: metadata
        )

        return try await repository.create(published)
    }

    func listPublished(studyId: UUID) async throws -> [PublishedStudy] {
        try await studyService.checkHasAccess(to: studyId, role: .researcher)
        return try await repository.listByStudyId(studyId)
    }
}
