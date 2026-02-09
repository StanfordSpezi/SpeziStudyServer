//
// This source file is part of the SpeziStudyServer open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation


struct AuthContext: Sendable {
    enum GroupRole: String, Sendable, Comparable {
        case researcher
        case admin

        private var level: Int {
            switch self {
            case .researcher: 0
            case .admin: 1
            }
        }

        static func < (lhs: GroupRole, rhs: GroupRole) -> Bool {
            lhs.level < rhs.level
        }
    }

    let roles: [String]
    let groups: [String]

    @TaskLocal static var current: AuthContext?

    static func requireCurrent() throws -> AuthContext {
        guard let context = current else {
            throw ServerError.Defaults.missingToken
        }
        return context
    }

    /// Parses JWT group paths (e.g., "/Stanford Biodesign Digital Health/admin") into a membership map.
    var groupMemberships: [String: GroupRole] {
        var memberships: [String: GroupRole] = [:]
        for path in groups {
            guard path.hasPrefix("/") else { continue }
            let parts = path.dropFirst().split(separator: "/", maxSplits: 1)
            guard parts.count == 2,
                  let role = GroupRole(rawValue: String(parts[1])) else {
                continue
            }
            memberships[String(parts[0])] = role
        }
        return memberships
    }

    func requireGroupAccess(groupName: String, role: GroupRole = .researcher) throws {
        guard let memberRole = groupMemberships[groupName], memberRole >= role else {
            throw ServerError.Defaults.forbidden
        }
    }
}
