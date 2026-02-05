//
// This source file is part of the SpeziStudyServer open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//
import Foundation


extension ServerError {
    enum Defaults {
        static let jsonBodyRequired = ServerError.validation(message: "Request body must be JSON")
        static let failedToRetrieveCreatedObject = ServerError.internalError(message: "Failed to retrieve created object")
        static let failedToListResources = ServerError.internalError(message: "Failed to list resources")
        static let failedToConvertResponse = ServerError.internalError(message: "Failed to convert response")
        static let unexpectedError = ServerError.internalError(message: "An unexpected error occurred")
        static let invalidRequestBody = ServerError.validation(message: "Invalid request body format")
        static let endpointNotImplemented = ServerError.internalError(message: "Endpoint not implemented.")
    }
}
