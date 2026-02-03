//
// This source file is part of the SpeziStudyServer open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SpeziLocalization
import SpeziStudyDefinition

extension Study {
    func assembleFiles() throws -> [StudyBundle.FileResourceInput] {
        var fileInputs: [StudyBundle.FileResourceInput] = []

        for component in components {
            guard let fileRef = component.componentData.fileRef else {
                continue
            }

            for file in component.files {
                guard let localizationKey = LocalizationKey(file.locale) else {
                    throw ServerError.validation(message: "Invalid locale format: \(file.locale)")
                }

                let input = try StudyBundle.FileResourceInput(
                    fileRef: fileRef,
                    localization: localizationKey,
                    contents: file.processedContent(component: component)
                )
                fileInputs.append(input)
            }
        }

        return fileInputs
    }
}
