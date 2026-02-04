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
        // TODO: Convert specialized component data to StudyDefinition.Component
        // This requires creating file references for informational and questionnaire components
        // and properly mapping health data components.
        // For now, components are not included in the bundle export.
        StudyDefinition(
            studyRevision: 1,
            metadata: metadata,
            components: [],
            componentSchedules: components.flatMap { component in
                component.schedules.map { $0.scheduleData }
            }
        )
    }
}
