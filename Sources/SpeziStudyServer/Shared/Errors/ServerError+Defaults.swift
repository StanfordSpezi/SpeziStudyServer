//
// This source file is part of the SpeziStudyServer open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//
import Foundation


extension ServerError {
    struct Defaults {
        let jsonBodyRequired = ServerError.validation(message: "Request body must be JSON")
        let failedToRetrieveCreatedObject = ServerError.internalError(message: "Failed to retrieve created object")
        let failedToListResources = ServerError.internalError(message: "Failed to list resources")
        let failedToConvertResponse = ServerError.internalError(message: "Failed to convert response")
        let unexpectedError = ServerError.internalError(message: "An unexpected error occurred")
    }

    static let defaults = Defaults()
}
