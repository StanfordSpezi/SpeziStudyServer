//
// This source file is part of the SpeziStudyServer open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Fluent


extension SchemaBuilder {
    @discardableResult
    func timestamps() -> Self {
        field("created_at", .datetime)
            .field("updated_at", .datetime)
    }
}
