# TODO — `05-participant` branch cleanup

## Bug

- [ ] **`deleteCode` does not verify studyId ownership** — `InvitationCodeService.deleteCode(studyId:codeId:)` checks researcher access to `studyId`, but `repository.find(id: codeId)` looks up the code by UUID only. It does not verify `code.$study.id == studyId`. A researcher with access to study A could delete a code belonging to study B if they know the code UUID. Add a `guard code.$study.id == studyId` check after the find, or filter by both fields in the repository query.

- [ ] **`getSchedule` / `replaceSchedule` do not verify schedule belongs to component** — `ComponentScheduleService.getSchedule` calls `requireSchedulableComponent(id: componentId, studyId:)` then `repository.find(id: scheduleId)`, but never checks `schedule.$component.id == componentId`. Same for `replaceSchedule`. A schedule from a different component could be returned/modified if the caller guesses the UUID. Filter by `componentId` in the repository query or add a guard.

- [ ] **HealthData `id: UUID()` in controller create is redundant / misleading** — `ComponentController.postStudiesStudyIdComponentsHealthData` constructs `StudyDefinition.HealthDataCollectionComponent(id: UUID(), schema.data)`, but `ComponentRepository.create` immediately overwrites `id` with a new `UUID()` and syncs `healthData.id` to match. The UUID passed from the controller is discarded silently. Remove the `id: UUID()` from the controller or pass `UUID()` to the service and let it handle it consistently with informational/questionnaire.

## Must Fix

- [ ] **`EnrollmentConditions` schema-to-model mapping has placeholder URL** — `StudyDefinition.EnrollmentConditions.init(_ schema:)` in `StudyMapper.swift:149` hardcodes `URL(string: "https://example.com")!` for `.requiresInvitation(verificationEndpoint:)`. This produces incorrect data when patching a study with `requiresInvitationCode`. Decide whether to drop `verificationEndpoint` from the model or expose it in the OpenAPI schema.

- [ ] **`consentURL` is hardcoded to `https://example.com/TODO`** — `ConsentController.swift:31` always sets a placeholder URL. The consent PDF bytes are read but discarded (`_ = try await Data(collecting: ..., upTo: 10_000_000)`). Consent records in the DB will have a bogus `pdfURL`. Implement file storage (e.g., S3/local) or at minimum return an error indicating the feature is incomplete.

- [ ] **`bundleURL` is hardcoded to `https://example.com/TODO`** — `PublishedStudyService.swift:28`. Every `PublishedStudy` row gets a fake bundle URL. Same need for file storage integration.

- [ ] **`studyRevision` hardcoded to 1 in `buildBundle`** — `StudyBundleService.swift:32` always uses `studyRevision: 1` regardless of actual published revision. Should use `nextRevision` or the published study's revision.

- [ ] **Consent version hardcoded to `1.0.0`** — `StudyBundleService.swift:85` always uses `Version(1, 0, 0)`. Should track consent versions properly (e.g., increment on consent content changes).

## Minor

- [ ] **`getParticipantStudies` lives in `ProfileController`** — The study-browsing endpoint uses `publishedStudyService`, not `profileService`. It's logically a participant study endpoint, not a profile operation. Consider moving to a dedicated participant study controller or renaming the file to something broader (e.g., `ParticipantController`).

- [ ] **`PublishedStudyListItem` uses study ID as item `id`** — `StudyMapper.swift:79` sets `id: model.$study.id.uuidString`. Multiple published revisions of the same study would share the same `id` in a list response. This is likely intentional for the "latest per study" browse endpoint but could confuse clients that treat `id` as unique.

- [ ] **`PublishedStudyService.browseStudies` accesses `InvitationCodeRepository` directly** — Bypasses `InvitationCodeService` layer and calls `invitationCodeRepository.findValid(code:)` directly. Other cross-module interactions go through the service layer. Consider using `InvitationCodeService` for consistency (may need a new method that doesn't require a specific `studyId`).

- [ ] **`PublishedStudyService.publish` double-checks access** — Calls `studyService.checkHasAccess(to:role: .admin)`, then calls `studyBundleService.buildMetadata(from:)` which internally calls `studyService.checkHasAccess(to:role: .researcher)` again. Not a bug (admin >= researcher), but the redundant check is unnecessary work. Consider a `buildMetadata` overload that skips the access check (or mark it internal-only).

- [ ] **`buildMetadata` discards file resources in `publish`** — `PublishedStudyService.publish` calls `buildMetadata(from:)` and uses `let (metadata, _)`, discarding the consent files. This is intentional since `publish` doesn't build the bundle, but it means `buildMetadata` does wasted work generating consent file content.

- [ ] **`force_unwrapping` on `createdAt!` in mappers** — `EnrollmentMapper.swift:19` and `StudyMapper.swift:71` force-unwrap `model.createdAt!`. Safe in practice (rows always have `created_at` set by Fluent) but risky if mappers are ever used on unsaved models. Consider using a `guard let` with an `internalServerError`.

- [ ] **`configureServices` ordering not grouped** — In `configure.swift:56-77`, services and repositories are interleaved without clear grouping. Consider grouping all services first, then all repositories, for readability.

## Code Style

- [ ] **Trailing whitespace** — `PublishedStudyService.swift:26` and `StudyBundleService.swift:47,86` have trailing whitespace on blank/statement lines. Run a formatter pass.

- [ ] **`@unknown default` in Weekday mapping** — `ComponentScheduleMapper` maps unknown weekday values to `.monday` silently. This could mask bugs. Consider throwing `ServerError.internalServerError("Unknown weekday")` instead.

- [ ] **openapi.yaml cleanup** — The uncommitted diff removes ~200 lines of `StudyMetadata`, `StudyMetadataIcon`, `StudyMetadataParticipationCriterion`, `StudyMetadataEnrollmentConditions`, and `FileReference` schemas. These were unused since the metadata is stored as opaque JSON and served as `additionalProperties: true`. Make sure to commit this cleanup.

- [ ] **`import FluentKit` instead of `import Fluent`** — `ProfileService.swift:11` imports `FluentKit` directly for `DatabaseError.isConstraintFailure`. `ParticipantEnrollmentService.swift:9` does the same thing but imports `Fluent` instead. Standardize on `import Fluent` since the rest of the codebase uses that.

- [ ] **Unused `import SpeziLocalization`** — `ProfileMapper.swift:10` imports `SpeziLocalization` but no types from that module are used in the file. Remove it.

## Inconsistency

- [ ] **Enrollment model field ordering** — `Enrollment.swift:36` declares `withdrawnAt` after the `@Timestamp` fields (`createdAt`/`updatedAt`), and `participationData` even further below. Other models (e.g., `InvitationCode.swift:22`) consistently place optional date fields *before* timestamps and regular fields before those. Reorder to: `currentRevision`, `withdrawnAt`, `participationData`, then timestamps, then `@Children`.

- [ ] **PublishedStudy mappings live in `StudyMapper.swift` instead of their own file** — `StudyMapper.swift:63-83` contains `PublishedStudyResponse` and `PublishedStudyListItem` extensions. Every other module has its own mapper file (`ProfileMapper`, `InvitationCodeMapper`, `EnrollmentMapper`, `EnrollmentConsentMapper`). Create `PublishedStudyMapper.swift` in `Modules/Study/Published/` and move these extensions there.

- [ ] **Auth enforcement pattern varies across participant services** — Some services call `AuthContext.checkIsParticipant()` directly (e.g., `InvitationCodeService.validateCode`, `PublishedStudyService.browseStudies`), while others go through `profileService.getProfile()` which internally calls `checkIsParticipant()` (e.g., `ParticipantEnrollmentService.enroll`, `listParticipantEnrollments`). The `getProfile()` approach also fetches the participant model. Both work, but the inconsistency makes it harder to reason about "who does the auth check". Consider standardizing: either always use `profileService.getProfile()` when you need the participant, or always do an explicit `checkIsParticipant()` + separate profile lookup.

- [ ] **Error messages not consistent** — Some use structured `ServerError.notFound(resource:identifier:)` (e.g., `ProfileService`, `ComponentService`), while others use freeform strings (e.g., `ParticipantEnrollmentService`: `"Already enrolled in this study..."`, `InvitationCodeService`: `"Cannot delete an invitation code that has already been redeemed"`). The structured pattern is cleaner; consider migrating all to use it where applicable.

- [ ] **Repository `find` patterns vary** — `ComponentRepository.find(id:studyId:)` filters by both ID and studyId (good, prevents cross-study access). `InvitationCodeRepository.find(id:)` only filters by UUID (causes the deleteCode bug above). `ComponentScheduleRepository.find(id:)` only filters by UUID (causes the schedule cross-component issue). Consider consistently filtering by parent ID in repository lookups where the parent context is available.

- [ ] **Constraint failure handling inconsistency** — `ProfileService.createProfile` and `ParticipantEnrollmentService.enroll` catch `DatabaseError.isConstraintFailure` and convert to `.conflict`. Other create operations (e.g., `InvitationCodeRepository.create`, `ConsentRepository.createConsentRecord`) don't handle constraint failures. This is fine if unique constraints only exist where handled, but if `EnrollmentConsent`'s `(enrollment_id, revision)` unique constraint is hit, it would bubble as an unhandled 500.

- [ ] **`ProfileService.createProfile` has redundant pre-check** — It does `findByIdentityProviderId` to check for existing profile, then also catches constraint failures in the `do/catch`. The pre-check is a TOCTOU race (another request could create between check and insert). The constraint catch alone is sufficient. Either remove the pre-check (rely on the DB constraint) or remove the catch (rely on the pre-check, accepting the race). Keeping both is defensive but redundant.

## Migration

- [ ] **`CreateParticipants` places `.unique()` between field definitions** — `CreateParticipants.swift:17` puts `.unique(on: "identity_provider_id")` immediately after the `identity_provider_id` field, before remaining fields. All other migrations (`CreateInvitationCodes`, `CreateEnrollments`, `CreateEnrollmentConsents`, `CreatePublishedStudies`) place `.unique()` after `.timestamps()` and before `.create()`. Move the unique constraint to after `.timestamps()` for consistency.

- [ ] **Missing index on `enrollment_consents.enrollment_id`** — `ConsentRepository.listConsentRecords(enrollmentId:)` queries by `enrollment_id`, but `CreateEnrollmentConsents` has no index on that column. Other migrations consistently add indexes on FK columns used for querying (e.g., `idx_enrollments_study_id`, `idx_enrollments_participant_id`, `idx_invitation_codes_study_id`, `idx_component_schedules_component_id`). Add `idx_enrollment_consents_enrollment_id`.

- [ ] **`participation_data` required but always empty** — `CreateEnrollments.swift:22` creates `participation_data` as `.json, .required`, and the `ParticipationData` struct is an empty `init() {}`. The field is never populated with meaningful data in any service. Consider making it `.optional` in the migration (with a nullable model field) until it has actual content, or document its intended purpose.

## OpenAPI Spec

- [ ] **`ConsentRecordResponse.pdfURL` missing `format: uri`** — `openapi.yaml` defines `pdfURL` as `type: string` without `format: uri`, but `PublishedStudyResponse.bundleURL` has `format: uri`. Add `format: uri` to `pdfURL` for consistency.

- [ ] **429 `TooManyRequests` response on all participant endpoints but no rate limiting** — Every participant endpoint references `TooManyRequests` with a `Retry-After` header, but no rate-limiting middleware exists in the codebase. Either implement rate limiting or remove the 429 references until it's ready.

## Test Gap

- [ ] **No test for expired JWT tokens** — `TestApp` always creates JWTs with 1-hour expiry. There's no test proving the middleware rejects tokens with `exp` in the past. Add a test that signs a JWT with an expired `exp` claim and expects 401.

- [ ] **No test for wrong-signature JWT** — Auth tests cover missing token and garbage string token, but don't test a properly structured JWT signed with the wrong key. Add a test signing with a different HMAC secret to verify the middleware rejects it.

- [ ] **No test for enrolling with expired or already-redeemed invitation code** — `ParticipantEnrollmentIntegrationTests` tests valid-code and missing-code scenarios, but doesn't test expired codes or codes that another participant already redeemed. The `InvitationCode.filterNotExpired()` and `findValid()` redeem-guard logic aren't exercised through integration tests.

- [ ] **`EnrollmentConsent` unique constraint `(enrollment_id, revision)` not tested** — If a participant submits consent twice for the same enrollment revision, the constraint would be hit but no service-level handling converts it to a friendly error. Either add a constraint failure catch in `ConsentService` (like `ProfileService` does) or add a test proving the 500 is acceptable.

## Keycloak / Docker

- [ ] **Realm export missing `spezi-web-study-platform` client** — `tools/bruno/collection.bru` changed `keycloakClientId` to `spezi-web-study-platform` (OAuth2 authorization_code flow), but `docker/keycloak/realm-export.json` only defines the `spezi-study-server` client. Local dev OAuth2 flow will fail because the client doesn't exist in Keycloak. Add a second client definition for `spezi-web-study-platform` (public, standardFlowEnabled: true, PKCE required) to the realm export.

## Bruno Collection

- [ ] **"Create Profile" request body missing required fields** — `tools/bruno/Participant/Create Profile.bru` only includes `firstName`, `lastName`, `dateOfBirth`, `region`, `languages`. The `ParticipantProfileInput` schema requires `email`, `gender`, `phoneNumber`, and `language` (singular, not `languages`). The request will fail with 400. Fix the example body to include all required fields.

- [ ] **"Update Profile" request body missing required fields** — `tools/bruno/Participant/Update Profile.bru` only includes `dateOfBirth`, `region`, `languages`. PUT replaces the full profile, so all required fields are needed: `firstName`, `lastName`, `email`, `gender`, `phoneNumber`, `language`. Same `languages` vs `language` issue.

- [ ] **"Submit Consent" uses JSON body but endpoint expects multipart/form-data** — `tools/bruno/Participant/Submit Consent.bru` sends `{"consentType":"study","accepted":true}` as JSON. The OpenAPI spec defines the endpoint as `multipart/form-data` with `consentData` (JSON part) + `consentPDF` (binary part). The request won't work as-is. Change to multipart body with both parts, or add a note that this is a placeholder.

- [ ] **Duplicate sequence number in Participant folder** — Both `Update Profile.bru` (seq: 5) and `Browse Studies.bru` (seq: 5) have `seq: 5`. Bruno orders by sequence, so display order is ambiguous. Give one of them a different number (e.g., Update Profile → seq: 3).
