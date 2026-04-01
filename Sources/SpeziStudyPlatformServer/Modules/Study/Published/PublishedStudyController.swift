//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import SpeziStudyPlatformAPIServer


extension Controller {
    func postStudiesStudyIdPublish(
        _ input: Operations.PostStudiesStudyIdPublish.Input
    ) async throws -> Operations.PostStudiesStudyIdPublish.Output {
        let studyId = try input.path.studyId.requireId()
        let published = try await publishedStudyService.publish(studyId: studyId)
        return .created(.init(body: .json(try .init(published))))
    }

    func getStudiesStudyIdPublished(
        _ input: Operations.GetStudiesStudyIdPublished.Input
    ) async throws -> Operations.GetStudiesStudyIdPublished.Output {
        let studyId = try input.path.studyId.requireId()
        let published = try await publishedStudyService.listPublished(studyId: studyId)
        return .ok(.init(body: .json(try published.map { try .init($0) })))
    }

    func getParticipantStudies(
        _ input: Operations.GetParticipantStudies.Input
    ) async throws -> Operations.GetParticipantStudies.Output {
        let studies = try await publishedStudyService.browseStudies(code: input.query.code)
        return .ok(.init(body: .json(try studies.map { try .init($0) })))
    }
}
