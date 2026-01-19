//
// This source file is part of the SpeziStudyServer open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SpeziStudyDefinition

extension StudyDefinition.Component {
    var fileRef: StudyBundle.FileReference? {
        switch self {
        case .informational(let component):
            return component.fileRef
        case .questionnaire(let component):
            return component.fileRef
        case .healthDataCollection, .timedWalkingTest, .customActiveTask:
            return nil
        }
    }
}
