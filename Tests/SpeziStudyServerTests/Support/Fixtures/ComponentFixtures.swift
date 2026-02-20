//
// This source file is part of the SpeziStudyServer open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Fluent
import Foundation
import SpeziHealthKit
import SpeziLocalization
import SpeziScheduler
import SpeziStudyDefinition
@testable import SpeziStudyServer


enum ComponentFixtures {
    @discardableResult
    static func createHealthDataComponent(
        on database: any Database,
        studyId: UUID,
        name: String = "Test Health Data"
    ) async throws -> (Component, HealthDataComponent) {
        let component = Component(
            studyId: studyId,
            type: .healthDataCollection,
            name: name
        )
        try await component.save(on: database)

        let componentId = try component.requireId()
        let healthData = HealthDataComponent(
            componentId: componentId,
            data: .init(
                id: componentId,
                sampleTypes: SampleTypesCollection([
                    SampleTypeProxy.quantity(.heartRate),
                    SampleTypeProxy.quantity(.stepCount)
                ]),
                optionalSampleTypes: SampleTypesCollection(),
                historicalDataCollection: .disabled
            )
        )
        try await healthData.save(on: database)

        return (component, healthData)
    }

    @discardableResult
    static func createQuestionnaireComponent(
        on database: any Database,
        studyId: UUID,
        name: String = "Test Questionnaire"
    ) async throws -> (Component, QuestionnaireComponent) {
        let component = Component(
            studyId: studyId,
            type: .questionnaire,
            name: name
        )
        try await component.save(on: database)

        let componentId = try component.requireId()
        let questionnaire = QuestionnaireComponent(
            componentId: componentId,
            data: .init([.enUS: QuestionnaireContent(questionnaire: "{}")])
        )
        try await questionnaire.save(on: database)

        return (component, questionnaire)
    }

    @discardableResult
    static func createInformationalComponent(
        on database: any Database,
        studyId: UUID,
        name: String = "Test Informational"
    ) async throws -> (Component, InformationalComponent) {
        let component = Component(
            studyId: studyId,
            type: .informational,
            name: name
        )
        try await component.save(on: database)

        let componentId = try component.requireId()
        let informational = InformationalComponent(
            componentId: componentId,
            data: .init([.enUS: InformationalContent(title: "Test", lede: nil, content: "Content")])
        )
        try await informational.save(on: database)

        return (component, informational)
    }

    @discardableResult
    static func createSchedule(
        on database: any Database,
        componentId: UUID,
        scheduleDefinition: StudyDefinition.ComponentSchedule.ScheduleDefinition = .repeated(
            .daily(interval: 1, hour: 9, minute: 0, second: 0),
            offset: DateComponents()
        ),
        completionPolicy: AllowedCompletionPolicy = .anytime,
        notifications: StudyDefinition.ComponentSchedule.NotificationsConfig = .disabled
    ) async throws -> ComponentSchedule {
        let data = StudyDefinition.ComponentSchedule(
            id: UUID(),
            componentId: componentId,
            scheduleDefinition: scheduleDefinition,
            completionPolicy: completionPolicy,
            notifications: notifications
        )
        let schedule = ComponentSchedule(componentId: componentId, scheduleData: data)
        try await schedule.save(on: database)
        return schedule
    }
}
