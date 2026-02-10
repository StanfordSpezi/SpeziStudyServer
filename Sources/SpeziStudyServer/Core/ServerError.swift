//
// This source file is part of the SpeziStudyServer open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import HTTPTypes
import OpenAPIRuntime


enum ServerError: Error, Sendable {
    case invalidUUID(String)
    case validation(message: String)
    case notFound(resource: String, identifier: String)
    case unauthorized(message: String)
    case forbidden(message: String)
    case internalError(message: String)

    enum Defaults {
        static let jsonBodyRequired = ServerError.validation(message: "Request body must be JSON")
        static let failedToRetrieveCreatedObject = ServerError.internalError(message: "Failed to retrieve created object")
        static let failedToListResources = ServerError.internalError(message: "Failed to list resources")
        static let failedToConvertResponse = ServerError.internalError(message: "Failed to convert response")
        static let unexpectedError = ServerError.internalError(message: "An unexpected error occurred")
        static let invalidRequestBody = ServerError.validation(message: "Invalid request body format")
        static let missingToken = ServerError.unauthorized(message: "Missing Authorization header")
        static let invalidToken = ServerError.unauthorized(message: "Invalid or expired token")
        static let forbidden = ServerError.forbidden(message: "Insufficient permissions")
        static let endpointNotImplemented = ServerError.internalError(message: "Endpoint not implemented.")
    }
}

extension ServerError {
    var title: String {
        switch self {
        case .invalidUUID:
            return "Invalid UUID"
        case .validation:
            return "Validation Error"
        case .notFound:
            return "Not Found"
        case .unauthorized:
            return "Unauthorized"
        case .forbidden:
            return "Forbidden"
        case .internalError:
            return "Internal Server Error"
        }
    }

    var status: HTTPResponse.Status {
        switch self {
        case .invalidUUID, .validation:
            return 400
        case .notFound:
            return 404
        case .unauthorized:
            return 401
        case .forbidden:
            return 403
        case .internalError:
            return 500
        }
    }

    var detail: String {
        switch self {
        case let .invalidUUID(value):
            return "Invalid UUID format: '\(value)'"
        case let .validation(message):
            return message
        case let .notFound(resource, identifier):
            return "\(resource) with identifier '\(identifier)' was not found"
        case let .unauthorized(message):
            return message
        case let .forbidden(message):
            return message
        case let .internalError(message):
            return message
        }
    }
    
    var httpResponse: (HTTPResponse, HTTPBody?) {
        let problemDetails = Components.Schemas.ProblemDetails(title: title, status: status.code, detail: detail)
        
        var headerFields = HTTPFields()
        headerFields[.contentType] = "application/problem+json; charset=utf-8"

        let body: HTTPBody?
        if let data = try? JSONEncoder().encode(problemDetails) {
            body = HTTPBody(data)
        } else {
            body = nil
        }


        return (HTTPResponse(status: self.status, headerFields: headerFields), body)
    }
}
