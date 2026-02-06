//
// This source file is part of the SpeziStudyServer open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation


enum GroupMapper {
    static func toDTO(_ model: Group) throws -> Components.Schemas.GroupResponse {
        guard let id = model.id else {
            throw ServerError.Defaults.unexpectedError
        }

        return Components.Schemas.GroupResponse(
            id: id.uuidString,
            name: model.name,
            icon: model.icon
        )
    }
}
