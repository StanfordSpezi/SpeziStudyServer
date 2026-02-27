//
// This source file is part of the SpeziStudyServer open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation


extension Components.Schemas.Component {
    init(_ model: Component) throws {
        self.init(
            id: try model.requireId().uuidString,
            _type: model.type.rawValue,
            name: model.name
        )
    }
}
