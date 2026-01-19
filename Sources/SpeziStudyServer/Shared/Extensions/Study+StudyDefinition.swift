//
// This source file is part of the SpeziStudyServer open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SpeziStudyDefinition

extension Study {
    var definition: StudyDefinition {
        StudyDefinition(
            studyRevision: 1,
            metadata: metadata,
            components: components.map { $0.componentData },
            componentSchedules: components.flatMap { component in
                component.schedules.map { $0.scheduleData }
            }
        )
    }
}
