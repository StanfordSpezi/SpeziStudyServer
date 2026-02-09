//
// This source file is part of the SpeziStudyServer open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

@testable import SpeziStudyServer
import Testing


@Suite
struct AuthContextTests {
    // MARK: - GroupRole Hierarchy

    @Test
    func adminIsGreaterThanResearcher() {
        #expect(AuthContext.GroupRole.admin > .researcher)
    }

    @Test
    func researcherIsLessThanAdmin() {
        #expect(AuthContext.GroupRole.researcher < .admin)
    }

    @Test
    func sameRolesAreEqual() {
        #expect(AuthContext.GroupRole.admin == .admin)
        #expect(AuthContext.GroupRole.researcher == .researcher)
    }

    // MARK: - Group Membership Parsing

    @Test
    func parsesValidGroupPaths() {
        let context = AuthContext(roles: [], groups: ["/MyGroup/admin", "/OtherGroup/researcher"])
        let memberships = context.groupMemberships

        #expect(memberships["MyGroup"] == .admin)
        #expect(memberships["OtherGroup"] == .researcher)
    }

    @Test(arguments: [
        "/GroupOnly",               // missing role segment
        "/Group/unknown",           // unrecognized role
        "",                         // empty string
        "no-leading-slash/admin",   // no leading slash
        "/Group/admin/extra",       // trailing segment
        "/",                        // slash only
    ])
    func ignoresInvalidGroupPath(path: String) {
        let context = AuthContext(roles: [], groups: [path])
        #expect(context.groupMemberships.isEmpty, "Expected no memberships for path: \(path)")
    }

    @Test
    func parsesGroupNameWithSpaces() {
        let context = AuthContext(roles: [], groups: ["/Stanford Biodesign Digital Health/admin"])
        let memberships = context.groupMemberships

        #expect(memberships["Stanford Biodesign Digital Health"] == .admin)
    }

    // MARK: - requireCurrent

    @Test
    func requireCurrentThrowsWhenNoContext() {
        #expect(throws: ServerError.self) {
            try AuthContext.requireCurrent()
        }
    }

    // MARK: - requireGroupAccess

    @Test
    func requireGroupAccessSucceedsForMember() throws {
        let context = AuthContext(roles: [], groups: ["/MyGroup/researcher"])
        try context.requireGroupAccess(groupName: "MyGroup")
    }

    @Test
    func requireGroupAccessFailsForNonMember() {
        let context = AuthContext(roles: [], groups: ["/MyGroup/admin"])

        #expect(throws: ServerError.self) {
            try context.requireGroupAccess(groupName: "OtherGroup")
        }
    }

    @Test
    func requireGroupAccessFailsWhenRoleInsufficient() {
        let context = AuthContext(roles: [], groups: ["/MyGroup/researcher"])

        #expect(throws: ServerError.self) {
            try context.requireGroupAccess(groupName: "MyGroup", role: .admin)
        }
    }

    @Test
    func requireGroupAccessSucceedsWhenAdminMeetsResearcherRequirement() throws {
        let context = AuthContext(roles: [], groups: ["/MyGroup/admin"])
        try context.requireGroupAccess(groupName: "MyGroup", role: .researcher)
    }

    @Test
    func requireGroupAccessSucceedsForExactRole() throws {
        let context = AuthContext(roles: [], groups: ["/MyGroup/admin"])
        try context.requireGroupAccess(groupName: "MyGroup", role: .admin)
    }

    @Test
    func emptyGroupsAlwaysDenied() {
        let context = AuthContext(roles: [], groups: [])

        #expect(throws: ServerError.self) {
            try context.requireGroupAccess(groupName: "AnyGroup")
        }
    }
}
