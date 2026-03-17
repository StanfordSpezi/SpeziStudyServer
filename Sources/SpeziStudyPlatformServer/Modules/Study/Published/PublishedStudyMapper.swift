//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation


extension Components.Schemas.PublishedStudyResponse {
    init(_ model: PublishedStudy) throws {
        self.init(
            id: try model.requireId().uuidString,
            studyId: model.$study.id.uuidString,
            revision: Int(model.revision),
            visibility: model.visibility,
            bundleURL: model.bundleURL.absoluteString,
            publishedAt: model.createdAt!  // swiftlint:disable:this force_unwrapping
        )
    }
}

extension Components.Schemas.PublishedStudyListItem {
    init(_ model: PublishedStudy) throws {
        self.init(
            studyId: model.$study.id.uuidString,
            metadata: model.metadata
        )
    }
}
