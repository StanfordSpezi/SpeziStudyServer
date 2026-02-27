<!--

This source file is part of the Stanford Spezi open-source project

SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)

SPDX-License-Identifier: MIT

-->

# Spezi Study Server

[![Build and Test](https://github.com/StanfordSpezi/SpeziStudyServer/actions/workflows/build-and-test.yml/badge.svg)](https://github.com/StanfordSpezi/SpeziStudyServer/actions/workflows/build-and-test.yml)
[![codecov](https://codecov.io/gh/StanfordSpezi/SpeziStudyServer/branch/main/graph/badge.svg?token=X7BQYSUKOH)](https://codecov.io/gh/StanfordSpezi/SpeziStudyServer)
[![DOI](https://zenodo.org/badge/573230182.svg)](https://zenodo.org/badge/latestdoi/573230182)

A Vapor-based server for managing clinical research studies, built as part of the Spezi ecosystem.


## Overview

Spezi Study Server provides a REST API for managing clinical research studies, including:

- **Studies** - Create and manage study definitions with metadata
- **Components** - Configure study components (questionnaires, health data collection, informational content)
- **Schedules** - Define when components should be presented to participants

The server integrates with [SpeziStudy](https://github.com/StanfordSpezi/SpeziStudy) for study configuration types and [SpeziVapor](https://github.com/StanfordSpezi/SpeziVapor) for dependency injection.


## Requirements

- Swift 6.0+
- Docker


## Local Development Setup

The project uses PostgreSQL and [Keycloak](https://www.keycloak.org) for authentication, both running via Docker Compose.

```bash
cp .env.example .env                          # configure environment (defaults work out of the box)
docker compose up -d db keycloak-db keycloak  # start PostgreSQL and Keycloak
swift run SpeziStudyServer migrate --yes      # create / update database tables
swift run                                     # start the server
```

The server connects to PostgreSQL, fetches JWKS from Keycloak, and syncs groups on startup.

To revert migrations, run `swift run SpeziStudyServer migrate --revert`. When using Docker Compose for the app itself, use `docker compose run migrate` and `docker compose run revert` instead.

See `.env.example` for all available environment options.

### Run Tests

```bash
swift test
```

Tests use an in-memory SQLite database and mock JWT signing — no Docker services required.

### Docker Compose Services

| Service | Description | Port |
|---|---|---|
| `db` | PostgreSQL for the application | `5432` |
| `keycloak-db` | PostgreSQL for Keycloak | internal |
| `keycloak` | Keycloak identity provider | `8180` |
| `app` | Production server (requires `docker compose build` first) | `8080` |
| `migrate` | Run migrations manually (`docker compose run migrate`) | — |
| `revert` | Revert migrations (`docker compose run revert`) | — |


## API Documentation

The API is defined using OpenAPI. See [`Sources/SpeziStudyServer/openapi.yaml`](Sources/SpeziStudyServer/openapi.yaml) for the full specification.

### API Testing with Bruno

API requests for manual testing are available in `tools/bruno/`. [Bruno](https://www.usebruno.com) is an open-source API client. Select the **SpeziStudy** environment in Bruno to load the required variables.

Run the **Seed** request to bootstrap a working dataset — it logs in via Keycloak, fetches groups, creates a study, and adds sample components in sequence. Requests use post-response scripts to pass IDs (e.g. `groupId`, `studyId`) to subsequent requests automatically, so you can explore the API without manually copying values.


## Architecture

The server follows a module-based architecture:

```
Sources/SpeziStudyServer/
├── App/              # Application bootstrap and configuration
├── Modules/          # Feature modules (Study, Component, etc.)
├── Models/           # Fluent database models
├── Migrations/       # Database migrations
└── Core/             # Shared infrastructure
```

Each module contains its own Controller, Service, Repository, and Mapper.

For detailed architecture documentation, see [AGENTS.md](AGENTS.md).


## License

This project is licensed under the MIT License. See [Licenses](https://github.com/StanfordSpezi/SpeziStudyServer/tree/main/LICENSES) for more information.


## Contributors

This project is developed as part of the Stanford Mussallem Center for Biodesign at Stanford University.
See [CONTRIBUTORS.md](https://github.com/StanfordSpezi/SpeziStudyServer/tree/main/CONTRIBUTORS.md) for a full list of all Spezi Study Server contributors.

![Stanford Mussallem Center for Biodesign Logo](https://raw.githubusercontent.com/StanfordBDHG/.github/main/assets/biodesign-footer-light.png#gh-light-mode-only)
![Stanford Mussallem Center for Biodesign Logo](https://raw.githubusercontent.com/StanfordBDHG/.github/main/assets/biodesign-footer-dark.png#gh-dark-mode-only)
