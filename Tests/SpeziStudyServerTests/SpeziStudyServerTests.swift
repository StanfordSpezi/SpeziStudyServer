//
// This source file is part of the SpeziStudyServer open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

@testable import SpeziStudyServer
import Testing


@Test
func testSpeziStudyServer() throws {
    let studyServer = SpeziStudyServer()
    #expect(studyServer.stanford == "Stanford University")
}
