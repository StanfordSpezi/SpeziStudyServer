//
// This source file is part of the SpeziStudyServer open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

extension Components.Schemas.ProblemDetails {
    init(_ serverError: ServerError) {
        self.init(title: serverError.title, status: serverError.status.code, detail: serverError.detail)
    }
}
