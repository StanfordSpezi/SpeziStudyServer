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
    private static let researcherRole = "spezistudyplatform-researcher"
    private static let participantRole = "spezistudyplatform-participant"

    private func makeContext(roles: [String] = [researcherRole], groups: [String] = []) -> AuthContext {
        AuthContext(subject: "test", roles: roles, groups: groups, researcherRole: Self.researcherRole, participantRole: Self.participantRole)
    }

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
        let context = makeContext(groups: ["/MyGroup/admin", "/OtherGroup/researcher"])
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
        "/"                         // slash only
    ])
    func ignoresInvalidGroupPath(path: String) {
        let context = makeContext(groups: [path])
        #expect(context.groupMemberships.isEmpty, "Expected no memberships for path: \(path)")
    }

    @Test
    func parsesGroupNameWithSpaces() {
        let context = makeContext(groups: ["/Stanford Biodesign Digital Health/admin"])
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

    // MARK: - requireResearcher / requireParticipant

    @Test
    func requireResearcherSucceedsWithResearcherRole() throws {
        let context = makeContext(roles: [Self.researcherRole])
        try context.requireResearcher()
    }

    @Test
    func requireResearcherFailsWithParticipantRole() {
        let context = makeContext(roles: [Self.participantRole])
        #expect(throws: ServerError.self) {
            try context.requireResearcher()
        }
    }

    @Test
    func requireResearcherFailsWithNoRoles() {
        let context = makeContext(roles: [])
        #expect(throws: ServerError.self) {
            try context.requireResearcher()
        }
    }

    @Test
    func requireParticipantSucceedsWithParticipantRole() throws {
        let context = makeContext(roles: [Self.participantRole])
        try context.requireParticipant()
    }

    @Test
    func requireParticipantFailsWithResearcherRole() {
        let context = makeContext(roles: [Self.researcherRole])
        #expect(throws: ServerError.self) {
            try context.requireParticipant()
        }
    }

    @Test
    func requireParticipantFailsWithNoRoles() {
        let context = makeContext(roles: [])
        #expect(throws: ServerError.self) {
            try context.requireParticipant()
        }
    }

    // MARK: - requireGroupAccess

    @Test
    func requireGroupAccessSucceedsForMember() throws {
        let context = makeContext(groups: ["/MyGroup/researcher"])
        try context.checkHasAccess(groupName: "MyGroup", role: .researcher)
    }

    @Test
    func requireGroupAccessFailsForNonMember() {
        let context = makeContext(groups: ["/MyGroup/admin"])

        #expect(throws: ServerError.self) {
            try context.checkHasAccess(groupName: "OtherGroup", role: .researcher)
        }
    }

    @Test
    func requireGroupAccessFailsWhenRoleInsufficient() {
        let context = makeContext(groups: ["/MyGroup/researcher"])

        #expect(throws: ServerError.self) {
            try context.checkHasAccess(groupName: "MyGroup", role: .admin)
        }
    }

    @Test
    func requireGroupAccessSucceedsWhenAdminMeetsResearcherRequirement() throws {
        let context = makeContext(groups: ["/MyGroup/admin"])
        try context.checkHasAccess(groupName: "MyGroup", role: .researcher)
    }

    @Test
    func requireGroupAccessSucceedsForExactRole() throws {
        let context = makeContext(groups: ["/MyGroup/admin"])
        try context.checkHasAccess(groupName: "MyGroup", role: .admin)
    }

    @Test
    func emptyGroupsAlwaysDenied() {
        let context = makeContext()

        #expect(throws: ServerError.self) {
            try context.checkHasAccess(groupName: "AnyGroup", role: .researcher)
        }
    }
}
