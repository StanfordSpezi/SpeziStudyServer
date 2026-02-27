//
// This source file is part of the SpeziStudyServer open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation


extension Components.Schemas.QuestionnaireComponentResponse {
    init(_ model: QuestionnaireComponent, name: String) throws {
        self.init(
            id: try model.requireId().uuidString,
            name: name,
            data: model.data
        )
    }
}
