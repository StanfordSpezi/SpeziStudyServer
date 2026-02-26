<!--

This source file is part of the SpeziStudyServer open source project

SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)

SPDX-License-Identifier: MIT

-->

# SpeziStudyServer

A Vapor-based server for managing clinical research studies, built as part of the Spezi ecosystem.

## Project Structure

```
Sources/SpeziStudyServer/
├── openapi.yaml                  # API specification
├── openapi-generator-config.yaml # Generator config
├── App/                          # Application bootstrap
│   ├── entrypoint.swift          # @main entry point
│   └── configure.swift           # App configuration, DI, routes, migrations
│
├── Modules/                      # Feature modules
│   ├── Controller.swift          # Root APIProtocol implementation + service accessors
│   ├── Group/                    # Group management (synced from Keycloak)
│   │   ├── GroupController.swift
│   │   ├── GroupService.swift
│   │   ├── GroupRepository.swift
│   │   └── GroupMapper.swift
│   ├── Study/                    # Study management
│   │   ├── StudyController.swift
│   │   ├── StudyService.swift
│   │   ├── StudyRepository.swift
│   │   └── StudyMapper.swift
│   ├── Component/                # Component operations
│   │   ├── ComponentController.swift
│   │   ├── ComponentService.swift
│   │   ├── ComponentRepository.swift
│   │   ├── ComponentMapper.swift
│   │   ├── HealthData/           # Health data collection (Controller/Service/Repository/Mapper)
│   │   ├── Informational/        # Informational content (Controller/Service/Repository/Mapper)
│   │   └── Questionnaire/        # Questionnaires (Controller/Service/Repository/Mapper)
│   └── ComponentSchedule/        # Schedule management (Controller/Service/Repository/Mapper)
│
├── Models/                       # Fluent database models
│   ├── Group.swift
│   ├── Study.swift               # StudyDetailContent (title, shortTitle, etc.), StudyPatch
│   ├── Component.swift
│   ├── ComponentType.swift       # Enum: informational, questionnaire, healthDataCollection
│   ├── ComponentSchedule.swift
│   ├── InformationalComponent.swift
│   ├── QuestionnaireComponent.swift
│   └── HealthDataComponent.swift
│
├── Migrations/                   # Fluent database migrations + Migrations.swift (registration)
│
└── Core/                         # Shared infrastructure
    ├── AuthContext.swift              # Auth domain type (roles, group memberships)
    ├── DatabaseConfiguration.swift    # Injectable DB config
    ├── ServerError.swift              # Error enum with RFC 7807 ProblemDetails
    ├── Extensions/
    │   ├── Encodable+Recode.swift
    │   ├── Model+RequireID.swift
    │   └── String+RequireID.swift
    ├── Keycloak/
    │   ├── KeycloakConfiguration.swift  # Environment-based config struct
    │   ├── KeycloakJWTPayload.swift     # JWT payload with roles/groups
    │   └── KeycloakClient.swift        # Group fetching & access token
    └── Middleware/
        ├── AuthMiddleware.swift          # JWT validation + AuthContext
        └── ErrorMiddleware.swift
```

## Architecture

### Module-Based Architecture

Each module (feature) contains its own:

1. **Controller** - HTTP request handling, input validation, response mapping. Controllers use `Components.Schemas.*` types. **Controllers must NEVER perform authorization checks** — all auth/access control logic belongs in the Service layer.
2. **Service** - Business logic, orchestration, and **authorization checks** (e.g., `requireGroupAccess`, filtering by user context). **Services must NEVER use `Components.Schemas.*` types.** They only work with domain models (Fluent models and plain Swift types). All conversion between API schemas and domain types happens in the Controller/Mapper layer.
3. **Repository** - Database access via Fluent ORM. Repositories only work with Fluent models.
4. **Mapper** - Conversion between API schemas and domain types. This is the boundary between the API layer and the domain layer. Mappers follow strict naming conventions:
   - **Schema → Domain**: `DomainType.init(_ schema: Components.Schemas.X)`
   - **Domain → Schema**: `Components.Schemas.X.init(_ model: DomainType)`

### Dependency Injection

Uses Spezi's dependency injection system:

```swift
final class StudyService: Module, @unchecked Sendable {
    @Dependency(StudyRepository.self) var repository: StudyRepository
}
```

Dependencies are registered in `App/configure.swift` via shared `configureServices(for:)`:

```swift
await app.spezi.configure {
    // Services
    GroupService()
    StudyService()
    ComponentService()
    // Repositories
    GroupRepository(database: app.db)
    StudyRepository(database: app.db)
    ComponentRepository(database: app.db)
}
```

### Configuration

`App/configure.swift` contains the startup functions and shared helpers:

- `configure(_:)` - Registers database and migrations. Safe for all commands (serve, migrate).
- `boot(_:)` - Serve-specific setup: Keycloak sync, JWKS, routes. Only called when serving, not for `migrate`.
- `configureServices(for:)` - Shared Spezi DI setup
- `configureRoutes(for:middlewares:)` - OpenAPI handler registration + /health endpoint

`Migrations/Migrations.swift` contains `configureMigrations(for:)` — shared migration registration used by both `configure()` and tests.

Database configuration is injectable via `DatabaseConfiguration`:

```swift
// Production (PostgreSQL from environment)
try await configure(app, database: .production)

// Testing (in-memory SQLite)
try await configure(app, database: .testing)
```

### Authentication (Keycloak)

JWT-based auth via Keycloak:

- JWKS fetched from Keycloak on startup for JWT validation
- `AuthMiddleware` implements `ServerMiddleware` (OpenAPIRuntime, not Vapor middleware)
- `AuthContext` with `@TaskLocal static var current` — set by middleware, read by handlers
- `GroupRole` enum (`researcher` < `admin`) with comparison for RBAC
- Groups synced from Keycloak Admin API on startup via `GroupService.syncGroups()`

Middleware stack: `ErrorMiddleware` → `AuthMiddleware`, registered in `configureRoutes(for:middlewares:)`.

### Component Types

Studies contain multiple component types, each with their own table:

- **InformationalComponent** - Static informational content
- **QuestionnaireComponent** - Survey/questionnaire definitions
- **HealthDataComponent** - Health data collection configuration

### OpenAPI Code Generation

API types are generated from `Sources/SpeziStudyServer/openapi.yaml` using swift-openapi-generator.

- Spec: `openapi.yaml` at target root
- Config: `openapi-generator-config.yaml` at target root
- Generated types: `Components.Schemas.*`, `Operations.*`
- Regenerate after schema changes: `swift build`

## Study API Patterns

### Study Creation (POST)

Study creation uses a simplified input — just `title` (plain string) and `icon`. The server defaults `locales` to `["en-US"]` and wraps the title into `details["en-US"].title`:

```json
POST /groups/{groupId}/studies
{
  "title": "My Heart Counts",
  "icon": "heart"
}
```

Full details, locales, and participationCriterion are set via PATCH after creation.

### Study Details

`StudyDetailContent` contains all per-locale study fields: `title`, `shortTitle`, `explanationText`, `shortExplanationText`. These are stored in a `LocalizationsDictionary<StudyDetailContent>` keyed by locale.

### Study List (GET)

`StudyListItem` returns a flat `id` + `title` string (en-US preferred, falls back to first available locale).

## StudyDefinition JSON Format

The server uses SpeziStudyDefinition types which encode with specific JSON patterns:

### Localized Strings

`LocalizationsDictionary` encodes as locale-keyed objects:

```json
{
  "details": {
    "en-US": {
      "title": "My Study Title",
      "shortTitle": "MST",
      "explanationText": "Study description here",
      "shortExplanationText": "Short desc"
    }
  }
}
```

### Participation Criterion

Uses a discriminated union with `type` property — no Swift enum `_0` syntax on the API surface:

```json
{
  "participationCriterion": {
    "type": "all",
    "criteria": [
      { "type": "ageAtLeast", "age": 18 },
      { "type": "isFromRegion", "region": "US" }
    ]
  }
}
```

Internally stored as `StudyDefinition.ParticipationCriterion` (Swift enum). The mapper in `StudyMapper.swift` converts between the API schema and the domain type.

### Health Data Sample Types

Sample types encode as `Type;Identifier` strings:

```json
{
  "sampleTypes": [
    "HKQuantityType;HKQuantityTypeIdentifierHeartRate",
    "HKQuantityType;HKQuantityTypeIdentifierStepCount",
    "HKCategoryType;HKCategoryTypeIdentifierSleepAnalysis"
  ]
}
```

### Schedule Definitions

```json
{
  "scheduleDefinition": {
    "once": {
      "_0": {
        "event": {
          "_0": { "activation": {} },
          "offsetInDays": 1,
          "time": { "hour": 9, "minute": 0, "second": 0 }
        }
      }
    }
  }
}
```

## Conventions

### Swift API Design Guidelines

Follow the official Swift API Design Guidelines: https://www.swift.org/documentation/api-design-guidelines/

Key points:
- Clarity at the point of use is the most important goal
- Prefer method and property names that make use sites form grammatical English phrases
- Name functions and methods according to their side-effects (mutating vs non-mutating)
- Use terminology consistently throughout the codebase

### File Organization

- One controller/service/repository per file
- Each module folder contains all related files
- Shared code goes in `Core/`

### Naming

- Fluent models: `Study`, `Component`, `HealthDataComponent`
- Repositories: `StudyRepository`, `ComponentRepository` (class, not protocol)
- Services: `StudyService` conforming to `Module`
- Controllers: Extensions on `Controller`

### Error Handling

Use `ServerError` for all errors:

```swift
throw ServerError.notFound(resource: "Study", identifier: id.uuidString)
throw ServerError.validation(message: "Invalid input")
throw ServerError.internalError(message: "Unexpected error")
```

Use `requireID()` instead of force unwrapping:

```swift
// On Fluent models
let id = try model.requireID()

// On String path parameters
let uuid = try input.path.id.requireID()
```

### Fluent Queries

When using Fluent's query builder with multiple filters, add swiftlint disable comment:

```swift
// swiftlint:disable:next first_where
try await Model.query(on: database)
    .filter(\.$id == id)
    .filter(\.$study.$id == studyId)
    .first()
```

## Commands

```bash
# Build
swift build

# Run server
swift run

# Run tests
swift test

# Lint
swiftlint
```

## Testing

### Test Structure

```
Tests/SpeziStudyServerTests/
├── Integration/                    # HTTP endpoint tests
│   ├── AuthIntegrationTests.swift
│   ├── GroupIntegrationTests.swift
│   ├── StudyIntegrationTests.swift
│   ├── ComponentIntegrationTests.swift
│   ├── ComponentScheduleIntegrationTests.swift
│   ├── HealthDataComponentIntegrationTests.swift
│   ├── QuestionnaireComponentIntegrationTests.swift
│   └── InformationalComponentIntegrationTests.swift
├── Unit/
│   ├── AuthContextTests.swift                    # GroupRole & groupMemberships parsing
│   ├── ParticipationCriterionMapperTests.swift   # Schema ↔ domain round-trip
│   ├── ComponentScheduleMapperTests.swift        # Schedule mapping tests
│   └── SchedulePatternMapperTests.swift          # Schedule pattern mapping tests
└── Support/
    ├── TestApp.swift               # App lifecycle, JWT signing with HMAC
    ├── Request+JSON.swift          # bearerAuth() + encodeJSONBody() helpers
    └── Fixtures/
        ├── GroupFixtures.swift     # Test data factories
        ├── StudyFixtures.swift
        └── ComponentFixtures.swift
```

### Test Patterns

- Uses Swift Testing framework (`@Suite`, `@Test`, `#expect`)
- In-memory SQLite database (configured via `DatabaseConfiguration.testing`)
- Fixtures create data directly via Fluent models (fast, focused tests)
- `TestApp.withApp(groups:)` manages app lifecycle and provides `(Application, String?)` — app + signed bearer token
  - `groups: nil` → no token (tests 401)
  - `groups: [...]` → signed JWT with those groups via HMAC test key
- Tests use real `AuthMiddleware` with HMAC-signed JWTs (not mocked)

### Running Tests

```bash
swift test                    # Run all tests
swift test --filter "Study"   # Run tests matching "Study"
```

## API Testing with Bruno

API requests are defined in `tools/bruno/`. Bruno is an open-source API client (alternative to Postman).

### Structure

```
tools/bruno/
├── collection.bru               # Root collection config
├── environments/SpeziStudy.bru  # Environment variables
├── Health Check.bru             # Health check endpoint
├── Seed.bru                     # Database seeding script
├── Auth/                        # Login + Refresh Token
├── Group/                       # Get Groups, Get Group
├── Study/                       # Post, Get, Put, Delete, Download, Get Studies In Group
├── Components/                  # CRUD per type (Informational, Questionnaire, HealthData) + List, Delete
└── ComponentSchedules/          # Get, Post (Once/Daily/Weekly), Put, Delete
```

### Database Seeding

The `Seed` request (`tools/bruno/Seed.bru`) includes a post-response script that seeds the database:

```javascript
script:post-response {
  await bru.runRequest("Auth/Login")
  await bru.runRequest("Group/Get Groups")
  await bru.runRequest("Study/Post Study")
  await bru.runRequest("Components/Questionnaire - Create")
  await bru.runRequest("Components/Informational - Create")
  await bru.runRequest("Components/HealthData - Create")
}
```

Run the `Seed` request to authenticate, fetch groups, and create a study with sample components for testing.
