//
// This source file is part of the SpeziStudyServer open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import SpeziScheduler
import SpeziStudyDefinition
@testable import SpeziStudyServer
import Testing


@Suite
struct ComponentScheduleMapperTests {
    private typealias CSTime = StudyDefinition.ComponentSchedule.Time
    private typealias NotifConfig = StudyDefinition.ComponentSchedule.NotificationsConfig

    // MARK: - AllowedCompletionPolicy

    @Test(arguments: [
        (SpeziScheduler.AllowedCompletionPolicy.sameDay, Components.Schemas.AllowedCompletionPolicy.sameDay),
        (.afterStart, .afterStart),
        (.sameDayAfterStart, .sameDayAfterStart),
        (.duringEvent, .duringEvent),
        (.anytime, .anytime)
    ])
    func allowedCompletionPolicyRoundTrip(
        model: SpeziScheduler.AllowedCompletionPolicy,
        expected: Components.Schemas.AllowedCompletionPolicy
    ) {
        let schema = Components.Schemas.AllowedCompletionPolicy(model)
        #expect(schema == expected)
        let back = SpeziScheduler.AllowedCompletionPolicy(schema)
        #expect(back == model)
    }

    // MARK: - ScheduleTime / ComponentSchedule.Time

    @Test
    func scheduleTimeModelToSchema() {
        let model = CSTime(hour: 14, minute: 30, second: 15)
        let schema = Components.Schemas.ScheduleTime(model)
        #expect(schema.hour == 14)
        #expect(schema.minute == 30)
        #expect(schema.second == 15)
    }

    @Test
    func scheduleTimeSchemaToModel() {
        let schema = Components.Schemas.ScheduleTime(hour: 9, minute: nil, second: nil)
        let model = CSTime(schema)
        #expect(model.hour == 9)
        #expect(model.minute == 0)
        #expect(model.second == 0)
    }

    @Test
    func scheduleTimeDefaultsOmitted() {
        let model = CSTime(hour: 8, minute: 0, second: 0)
        let schema = Components.Schemas.ScheduleTime(model)
        #expect(schema.minute == nil)
        #expect(schema.second == nil)
    }

    // MARK: - Weekday

    @Test(arguments: [
        (Locale.Weekday.monday, Components.Schemas.WeeklyRepetition.WeekdayPayload.monday),
        (.tuesday, .tuesday),
        (.wednesday, .wednesday),
        (.thursday, .thursday),
        (.friday, .friday),
        (.saturday, .saturday),
        (.sunday, .sunday)
    ])
    func weekdayRoundTrip(model: Locale.Weekday, expected: Components.Schemas.WeeklyRepetition.WeekdayPayload) {
        let schema = Components.Schemas.WeeklyRepetition.WeekdayPayload(model)
        #expect(schema == expected)
        let back = Locale.Weekday(schema)
        #expect(back == model)
    }

    // MARK: - StudyLifecycleEvent

    @Test
    func studyLifecycleEventEnrollment() {
        let schema = Components.Schemas.StudyLifecycleEvent(StudyLifecycleEvent.enrollment)
        if case .enrollment = schema {} else { Issue.record("Expected enrollment") }
        let back = StudyLifecycleEvent(schema)
        #expect(back == .enrollment)
    }

    @Test
    func studyLifecycleEventActivation() {
        let schema = Components.Schemas.StudyLifecycleEvent(StudyLifecycleEvent.activation)
        if case .activation = schema {} else { Issue.record("Expected activation") }
        let back = StudyLifecycleEvent(schema)
        #expect(back == .activation)
    }

    @Test
    func studyLifecycleEventUnenrollment() {
        let schema = Components.Schemas.StudyLifecycleEvent(StudyLifecycleEvent.unenrollment)
        if case .unenrollment = schema {} else { Issue.record("Expected unenrollment") }
        let back = StudyLifecycleEvent(schema)
        #expect(back == .unenrollment)
    }

    @Test
    func studyLifecycleEventStudyEnd() {
        let schema = Components.Schemas.StudyLifecycleEvent(StudyLifecycleEvent.studyEnd)
        if case .studyEnd = schema {} else { Issue.record("Expected studyEnd") }
        let back = StudyLifecycleEvent(schema)
        #expect(back == .studyEnd)
    }

    @Test
    func studyLifecycleEventCompletedTask() {
        let componentId = UUID()
        let schema = Components.Schemas.StudyLifecycleEvent(.completedTask(componentId: componentId))
        if case .completedTask(let value) = schema {
            #expect(value.componentId == componentId.uuidString)
        } else {
            Issue.record("Expected completedTask")
        }
        let back = StudyLifecycleEvent(schema)
        #expect(back == .completedTask(componentId: componentId))
    }

    // MARK: - NotificationThread

    @Test
    func notificationThreadGlobal() {
        let schema = Components.Schemas.NotificationThread(SpeziScheduler.NotificationThread.global)
        if case .global = schema {} else { Issue.record("Expected global") }
        let back = SpeziScheduler.NotificationThread(schema)
        #expect(back == .global)
    }

    @Test
    func notificationThreadTask() {
        let schema = Components.Schemas.NotificationThread(SpeziScheduler.NotificationThread.task)
        if case .task = schema {} else { Issue.record("Expected task") }
        let back = SpeziScheduler.NotificationThread(schema)
        #expect(back == .task)
    }

    @Test
    func notificationThreadNone() {
        let schema = Components.Schemas.NotificationThread(SpeziScheduler.NotificationThread.none)
        if case .none = schema {} else { Issue.record("Expected none") }
        let back = SpeziScheduler.NotificationThread(schema)
        #expect(back == .none)
    }

    @Test
    func notificationThreadCustom() {
        let schema = Components.Schemas.NotificationThread(.custom("my-thread"))
        if case .custom(let value) = schema {
            #expect(value.identifier == "my-thread")
        } else {
            Issue.record("Expected custom")
        }
        let back = SpeziScheduler.NotificationThread(schema)
        #expect(back == .custom("my-thread"))
    }

    // MARK: - NotificationsConfig

    @Test
    func notificationsConfigDisabled() {
        let schema = Components.Schemas.NotificationsConfig(NotifConfig.disabled)
        if case .disabled = schema {} else { Issue.record("Expected disabled") }
        let back = NotifConfig(schema)
        if case .disabled = back {} else { Issue.record("Expected disabled") }
    }

    @Test
    func notificationsConfigEnabledWithTime() {
        let model = NotifConfig.enabled(
            thread: .task,
            time: NotificationTime(hour: 9, minute: 30, second: 0)
        )
        let schema = Components.Schemas.NotificationsConfig(model)
        if case .enabled(let value) = schema {
            if case .task = value.thread {} else { Issue.record("Expected task thread") }
            #expect(value.time?.hour == 9)
            #expect(value.time?.minute == 30)
        } else {
            Issue.record("Expected enabled")
        }
        let back = NotifConfig(schema)
        if case .enabled(let thread, let time) = back {
            #expect(thread == .task)
            #expect(time?.hour == 9)
        } else {
            Issue.record("Expected enabled")
        }
    }

    @Test
    func notificationsConfigEnabledWithoutTime() {
        let model = NotifConfig.enabled(thread: .global, time: nil)
        let schema = Components.Schemas.NotificationsConfig(model)
        if case .enabled(let value) = schema {
            #expect(value.time == nil)
        } else {
            Issue.record("Expected enabled")
        }
    }
}
