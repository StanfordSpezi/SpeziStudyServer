//
// This source file is part of the SpeziStudyServer open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Fluent
import Vapor


/// Registers all database migrations.
public func configureMigrations(for app: Application) {
    app.migrations.add(CreateGroups())
    app.migrations.add(CreateStudy())
    app.migrations.add(CreateComponents())
    app.migrations.add(CreateComponentSchedules())
    app.migrations.add(CreateInformationalComponents())
    app.migrations.add(CreateQuestionnaireComponents())
    app.migrations.add(CreateHealthDataComponents())
}
