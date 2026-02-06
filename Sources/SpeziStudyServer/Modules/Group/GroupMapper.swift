//
// This source file is part of the SpeziStudyServer open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation


extension Components.Schemas.GroupResponse {
    init(_ model: Group) throws {
        guard let id = model.id else {
            throw ServerError.Defaults.unexpectedError
        }

        self.init(
            id: id.uuidString,
            name: model.name,
            icon: model.icon
        )
    }
}
