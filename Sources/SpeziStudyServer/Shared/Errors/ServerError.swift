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
    case internalError(message: String)
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
        case let .internalError(message):
            return message
        }
    }
    
    var httpResponse: (HTTPResponse, HTTPBody?) {
        let problemDetails = Components.Schemas.ProblemDetails(self)
        
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
