//
// This source file is part of the SpeziStudyServer open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation


extension Components.Schemas.InvitationCodeResponse {
    init(_ model: InvitationCode) throws {
        self.init(
            id: try model.requireId().uuidString,
            studyId: model.$study.id.uuidString,
            code: model.code,
            used: model.redeemedAt != nil,
            enrollmentId: model.$enrollment.id?.uuidString,
            expiresAt: model.expiresAt
        )
    }
}
