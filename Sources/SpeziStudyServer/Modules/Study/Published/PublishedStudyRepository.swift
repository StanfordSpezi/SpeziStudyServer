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


final class PublishedStudyRepository: Module, Sendable {
    let database: any Database

    init(database: any Database) {
        self.database = database
    }

    func listByStudyId(_ studyId: UUID) async throws -> [PublishedStudy] {
        try await PublishedStudy.query(on: database)
            .filter(\.$study.$id == studyId)
            .all()
    }

    func maxRevision(forStudyId studyId: UUID) async throws -> Int? {
        try await PublishedStudy.query(on: database)
            .filter(\.$study.$id == studyId)
            .max(\.$revision)
    }

    func create(_ publishedStudy: PublishedStudy) async throws -> PublishedStudy {
        try await publishedStudy.save(on: database)

        guard let created = try await PublishedStudy.find(try publishedStudy.requireId(), on: database) else {
            throw ServerError.failedToRetrieveCreatedObject
        }

        return created
    }
}
