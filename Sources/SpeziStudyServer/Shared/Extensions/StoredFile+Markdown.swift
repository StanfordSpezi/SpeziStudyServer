//
// This source file is part of the SpeziStudyServer open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation

extension StoredFile {
    func processedContent(component: Component) -> String {
        guard type == "md", $component.id != nil else {
            return content
        }

        let id = component.componentData.id.uuidString

        return [
            "---",
            "title: \(name)",
            "id: \(id)",
            "---",
            content
        ].joined(separator: "\n")
    }
}
