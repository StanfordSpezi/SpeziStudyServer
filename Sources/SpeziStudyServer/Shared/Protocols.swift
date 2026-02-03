//
// This source file is part of the SpeziStudyServer open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//
import SpeziVapor
import OpenAPIVapor

protocol VaporModule: Module, Sendable {}

protocol SpeziAPIProtocol: APIProtocol {
    var spezi: SpeziVapor { get }
}
