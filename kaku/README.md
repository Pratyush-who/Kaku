# Canvas --- Collaborative Drawing Workspace

> A persistent, project-based drawing workspace inspired by the
> simplicity of Excalidraw and the organization of Notion. Create
> editable diagrams and sketches, keep them organized in projects,
> reopen them later, and collaborate with other people in real time.

**Status:** Product concept / architecture plan\
**Client:** Flutter\
**Backend:** Go\
**Database:** PostgreSQL with JSONB\
**Real-time transport:** WebSockets\
**Primary goal:** A drawing should remain editable and recoverable---not
just be exported as an image.

> **Working name:** `Canvas` is a placeholder. Choose a distinct product
> name before publishing or distributing the app.

------------------------------------------------------------------------

## Table of contents

-   [1. Overview](#1-overview)
-   [2. Problem statement](#2-problem-statement)
-   [3. Product vision](#3-product-vision)
-   [4. Goals and non-goals](#4-goals-and-non-goals)
-   [5. Core features](#5-core-features)
-   [6. User journeys](#6-user-journeys)
-   [7. Architecture](#7-architecture)
-   [8. Technology stack](#8-technology-stack)
-   [9. Repository structure](#9-repository-structure)
-   [10. Drawing document model](#10-drawing-document-model)
-   [11. Database design](#11-database-design)
-   [12. Persistence and recovery](#12-persistence-and-recovery)
-   [13. Real-time collaboration](#13-real-time-collaboration)
-   [14. API design](#14-api-design)
-   [15. WebSocket protocol](#15-websocket-protocol)
-   [16. Flutter application
    architecture](#16-flutter-application-architecture)
-   [17. Go backend architecture](#17-go-backend-architecture)
-   [18. Security and permissions](#18-security-and-permissions)
-   [19. Error handling and
    reliability](#19-error-handling-and-reliability)
-   [20. Testing strategy](#20-testing-strategy)
-   [21. Local development](#21-local-development)
-   [22. Configuration](#22-configuration)
-   [23. Deployment](#23-deployment)
-   [24. Performance considerations](#24-performance-considerations)
-   [25. Observability](#25-observability)
-   [26. Development roadmap](#26-development-roadmap)
-   [27. MVP acceptance criteria](#27-mvp-acceptance-criteria)
-   [28. Risks and trade-offs](#28-risks-and-trade-offs)
-   [29. Future possibilities](#29-future-possibilities)
-   [30. Contributing](#30-contributing)
-   [31. License](#31-license)

------------------------------------------------------------------------

## 1. Overview

Canvas is a cross-platform drawing workspace where users can create
diagrams, sketches, flowcharts, architecture plans, brainstorming
boards, and other visual documents.

It combines three ideas:

1.  **An Excalidraw-like canvas:** draw and edit objects on an
    effectively infinite workspace.
2.  **A Notion-like organization model:** organize boards inside
    projects and return to them whenever needed.
3.  **Real-time collaboration:** invite collaborators to a board and see
    their edits while working together.

The application is not intended to be a simple image editor. A board is
a structured, editable document made of elements such as shapes, text,
arrows, and freehand strokes. The app stores that document so the user
can close the app, return later, and continue editing.

### Core product principles

-   **Persistence by default:** users should not have to remember to
    save.
-   **Editable documents:** the source of truth is structured drawing
    data, not a PNG screenshot.
-   **Local-first resilience:** recent work should remain recoverable
    during network interruptions.
-   **Collaboration as a first-class capability:** live edits should
    feel responsive and predictable.
-   **Simple organization:** projects contain boards; boards contain
    drawing elements.
-   **Clear ownership and access:** sharing must never bypass
    authorization.
-   **Incremental complexity:** start with a reliable single-server
    implementation and scale only when necessary.

------------------------------------------------------------------------

## 2. Problem statement

Many drawing tools make it easy to start a sketch but do not provide the
project-oriented workflow desired here. A user may have to export
drawings manually, keep track of separate files, or search through
unrelated documents to find an earlier board.

This project aims to make visual work persistent and organized:

-   Create a project for a course, product, feature, or team.
-   Create multiple boards inside that project.
-   Draw and edit without manually saving every change.
-   Close the app and later resume the same board.
-   Share a board with collaborators.
-   Work alone when collaboration is not needed.
-   Preserve editable elements, not merely a flattened image.

### Example use cases

-   Software architecture diagrams
-   Database schemas and entity relationships
-   Flowcharts and algorithm explanations
-   Product brainstorming
-   UI wireframes and rough sketches
-   Team planning sessions
-   Personal study notes
-   System design interview practice
-   Visual documentation for codebases

------------------------------------------------------------------------

## 3. Product vision

The long-term vision is a dependable home for visual thinking: a user
can create a project, collect boards around a topic, and invite others
to contribute without changing tools or losing context.

### Conceptual hierarchy

``` text
Workspace
└── Project
    ├── Board: System Architecture
    │   ├── Rectangle
    │   ├── Text
    │   ├── Arrow
    │   └── Freehand Stroke
    ├── Board: Database Design
    └── Board: User Flow
```

For the first version, a personal workspace can simply be represented by
the user's projects. A separate workspace entity can be introduced later
if the product needs multiple teams or organizations per account.

### Product terminology

-   **User:** an authenticated account.
-   **Project:** a container for related boards.
-   **Board:** one editable drawing document.
-   **Element:** a shape, text object, connector, image, or stroke on a
    board.
-   **Viewport:** the canvas camera state, such as zoom and pan
    position.
-   **Operation:** a change to a board, such as creating or moving an
    element.
-   **Room:** the active WebSocket collaboration session for a board.
-   **Snapshot:** a persisted representation of a board at a specific
    revision.

------------------------------------------------------------------------

## 4. Goals and non-goals

### Goals

-   Build a Flutter application with a responsive drawing experience.
-   Build a Go backend with a clear, maintainable API.
-   Persist projects and boards in PostgreSQL.
-   Store flexible drawing content as JSONB.
-   Autosave local changes and synchronize them with the server.
-   Restore the latest board content after an app restart.
-   Support authentication, invitations, and collaborator roles.
-   Support live collaboration through WebSockets.
-   Design for incremental growth without prematurely adopting
    microservices.
-   Provide a foundation for export, history, and future canvas
    features.

### Initial non-goals

The MVP does not need to include:

-   A full document editor like Notion.
-   Video or audio calls.
-   Comments, chat, or task management.
-   Complex organization/team billing.
-   Unlimited offline conflict-free collaboration.
-   A distributed multi-region backend.
-   A microservice for every domain.
-   A full CRDT implementation before basic collaboration works.
-   A custom binary file format.
-   AI-generated diagrams.

These may be considered after the core drawing, saving, and
collaboration experience is reliable.

------------------------------------------------------------------------

## 5. Core features

### 5.1 Canvas and drawing tools

The canvas should support an effectively infinite two-dimensional
workspace with pan and zoom.

Initial tools:

-   Selection and multi-selection
-   Freehand pen
-   Eraser
-   Rectangle
-   Ellipse
-   Line
-   Arrow
-   Text
-   Hand/pan tool

Element editing:

-   Select, move, resize, and delete elements
-   Change stroke and fill colors
-   Change line thickness
-   Change text content and size
-   Duplicate elements
-   Bring elements forward or send them backward
-   Grouping can be added after basic selection is stable
-   Undo and redo
-   Keyboard shortcuts where the platform supports them

Canvas behavior:

-   Pan using a hand tool or supported gesture.
-   Zoom around the pointer or focal point where practical.
-   Keep screen coordinates separate from document coordinates.
-   Support hit-testing for selection and editing.
-   Avoid recreating the entire drawing model unnecessarily on every
    pointer event.
-   Handle large boards without excessive allocations or frame drops.

### 5.2 Projects and boards

Users can:

-   Create, rename, and delete projects.
-   Create boards within a project.
-   Rename and delete boards.
-   Open an existing board and continue editing.
-   See the last-updated time.
-   View a board thumbnail or preview.
-   Keep boards grouped by topic.
-   Search projects and boards in a later iteration.

Deletion should be explicit. A future trash/restore feature can provide
an additional recovery layer.

### 5.3 Automatic persistence

Saving should be automatic and mostly invisible to the user.

The application should:

-   Save a local snapshot after meaningful changes.
-   Schedule remote autosaves after a short idle period.
-   Display whether changes are saved, saving, offline, or failed.
-   Retry failed remote saves safely.
-   Keep pending local changes until they are acknowledged by the
    server.
-   Restore the last usable local state after a restart.
-   Reconcile local and remote revisions on reconnect.
-   Persist viewport state if the product wants reopening to preserve
    zoom and pan.

Do not rely exclusively on an app-close callback. Mobile operating
systems may terminate an app without giving it time to perform a final
save.

### 5.4 Accounts and sharing

Initial account capabilities:

-   Sign up and sign in
-   Secure session/token handling
-   View owned projects
-   Invite collaborators
-   Accept or reject an invitation
-   Remove a collaborator
-   Leave a shared project
-   Assign viewer or editor access

A project-level permission model is a reasonable MVP default.
Board-level overrides can be added later if required.

### 5.5 Real-time collaboration

Collaborators should be able to:

-   Join the same board
-   See each other's drawing changes
-   See remote cursors and collaborator identity
-   Move and edit elements
-   Receive server acknowledgements
-   Recover from temporary disconnects
-   Rejoin and synchronize after reconnecting

Remote cursors are transient state and should not be written to
PostgreSQL on every movement.

### 5.6 Export and sharing links

After the core MVP:

-   Export a board as PNG.
-   Consider SVG export for supported vector elements.
-   Create read-only share links if public sharing is desired.
-   Generate board thumbnails.
-   Import supported image assets.

Exports are useful outputs, but they must not replace the editable
document stored by the application.

------------------------------------------------------------------------

## 6. User journeys

### Journey A: Create and resume a board

1.  The user opens the app and signs in.
2.  The user creates a project named `System Design`.
3.  The user creates a board named `URL Shortener`.
4.  The user draws services, arrows, and text.
5.  The app saves changes locally and schedules a server save.
6.  The user closes the app.
7.  Later, the user opens the project and selects `URL Shortener`.
8.  The board is restored with its editable elements and saved viewport.

**Expected result:** the user can continue editing without manually
exporting or reconstructing the drawing.

### Journey B: Collaborate on a board

1.  The owner opens a project and invites a collaborator.
2.  The collaborator accepts the invitation.
3.  Both users open the same board.
4.  Each client establishes an authenticated WebSocket connection.
5.  The server verifies board access and joins both clients to the board
    room.
6.  A drawing operation from one client is validated and broadcast.
7.  Other clients apply the operation and update their canvases.
8.  The server persists operations or batches into the board snapshot.
9.  If a client disconnects, it reconnects and synchronizes from the
    last acknowledged revision.

### Journey C: Work through a network interruption

1.  The user is editing a board.
2.  The network becomes unavailable.
3.  Local autosave continues.
4.  The UI indicates that remote synchronization is pending.
5.  The network returns.
6.  The client exchanges revision information with the server.
7.  Pending operations are submitted or reconciled.
8.  The client shows a synchronized state only after acknowledgement.

Conflict behavior must be defined rather than silently overwriting newer
server content.

------------------------------------------------------------------------

## 7. Architecture

### High-level system

``` mermaid
flowchart TB
    U[User]
    F[Flutter Application]
    C[Canvas Engine]
    L[Local Persistence]
    R[REST API Client]
    W[WebSocket Client]
    G[Go Backend]
    A[Authentication and Authorization]
    B[Board and Project Services]
    H[Collaboration Hub]
    P[(PostgreSQL JSONB)]
    O[(Object Storage)]

    U --> F
    F --> C
    F --> L
    F --> R
    F --> W
    R --> G
    W <--> H
    G --> A
    G --> B
    H --> A
    B --> P
    B --> O
    H --> P
```

### Main responsibilities

**Flutter** - Render the canvas and handle gestures. - Maintain the
current in-memory board model. - Provide tools, selection, history, and
keyboard shortcuts. - Persist local snapshots. - Call the REST API. -
Connect to collaboration rooms over WebSockets. - Show sync state and
recover pending work.

**Go backend** - Authenticate users. - Authorize access to projects and
boards. - Expose REST endpoints. - Manage WebSocket sessions and board
rooms. - Validate incoming operations. - Sequence or version edits. -
Persist snapshots and operation batches. - Handle invitations and
membership changes.

**PostgreSQL** - Store users, projects, boards, memberships,
invitations, and revisions. - Store board document JSON in JSONB. -
Enforce relational constraints and transactional updates.

**Object storage** - Store uploaded images or other large binary
assets. - Keep only asset metadata and references in board documents. -
Can be omitted until asset uploads are implemented.

### Deployment shape

Start with a modular monolith:

-   One Flutter app
-   One Go backend
-   One PostgreSQL database
-   Optional object storage when needed

Do not split the collaboration hub into a separate service until scale
or operational requirements justify it.

------------------------------------------------------------------------

## 8. Technology stack

The exact package versions should be selected and pinned during
implementation.

  -----------------------------------------------------------------------
  Area                    Proposed choice         Purpose
  ----------------------- ----------------------- -----------------------
  Client                  Flutter / Dart          Cross-platform UI and
                                                  canvas

  Client architecture     Clean Architecture      Separation of
                                                  presentation, domain,
                                                  and data

  State management        `flutter_bloc` / Cubit  UI state and user
                                                  actions

  Local database          SQLite, using a         Durable local snapshots
                          maintained Flutter      and pending changes
                          integration             

  HTTP                    `dio` or a suitable     REST requests
                          Dart HTTP client        

  Backend                 Go                      API and collaboration
                                                  services

  HTTP router             `chi`                   Lightweight routing and
                                                  middleware

  PostgreSQL driver       `pgx`                   Database access

  Query generation        `sqlc`                  Type-safe generated SQL
                                                  access

  Schema migrations       `golang-migrate` or an  Versioned schema
                          equivalent migration    changes
                          tool                    

  WebSockets              `coder/websocket`       Real-time communication

  Database                PostgreSQL              Relational data and
                                                  JSONB documents

  Binary assets           S3-compatible object    Images and large files
                          storage, when needed    

  API specification       OpenAPI                 API documentation and
                                                  client integration

  Containers              Docker Compose          Local backend/database
                                                  environment

  Testing                 Go test, Flutter test,  Quality and regression
                          integration tests       coverage
  -----------------------------------------------------------------------

### Why PostgreSQL with JSONB?

The drawing itself is document-shaped, but the surrounding product is
relational:

-   A user owns projects.
-   A project contains boards.
-   A project has members.
-   An invitation belongs to a project.
-   A board has a revision and update history.

PostgreSQL can model these relationships with foreign keys and
transactions while storing flexible drawing content in JSONB.

A board table can contain:

-   `content JSONB` --- editable elements and drawing metadata.
-   `viewport JSONB` --- saved camera state if persisted per user or
    board.
-   `revision BIGINT` --- server-managed board revision.
-   `updated_at TIMESTAMPTZ` --- last successful update.

MongoDB is also viable, but it is not necessary solely because the
canvas document is nested JSON. Re-evaluate the choice only if
document-first requirements later outweigh the relational benefits.

### Why not add Redis or Kafka immediately?

The initial backend can manage active rooms in memory and persist to
PostgreSQL. Redis Pub/Sub may become useful when multiple Go instances
need to exchange room events. Kafka is unnecessary for the MVP's direct
collaboration path.

------------------------------------------------------------------------

## 9. Repository structure

A monorepo is a convenient starting point:

``` text
canvas/
├── README.md
├── .gitignore
├── .editorconfig
├── .env.example
├── docker-compose.yml
├── docs/
│   ├── architecture.md
│   ├── api.md
│   ├── websocket-protocol.md
│   ├── drawing-document.md
│   └── decisions/
├── app/
│   └── flutter_app/
│       ├── pubspec.yaml
│       ├── lib/
│       │   ├── app/
│       │   ├── core/
│       │   │   ├── errors/
│       │   │   ├── network/
│       │   │   ├── persistence/
│       │   │   ├── routing/
│       │   │   └── theme/
│       │   └── features/
│       │       ├── auth/
│       │       ├── projects/
│       │       ├── boards/
│       │       ├── canvas/
│       │       ├── collaboration/
│       │       └── settings/
│       └── test/
├── backend/
│   ├── go.mod
│   ├── cmd/
│   │   └── api/
│   │       └── main.go
│   ├── internal/
│   │   ├── config/
│   │   ├── http/
│   │   ├── auth/
│   │   ├── users/
│   │   ├── projects/
│   │   ├── boards/
│   │   ├── collaboration/
│   │   ├── invitations/
│   │   ├── persistence/
│   │   └── observability/
│   ├── migrations/
│   ├── queries/
│   └── test/
└── infra/
    ├── docker/
    └── deployment/
```

### Flutter feature organization

Use a feature-first Clean Architecture structure:

``` text
features/boards/
├── presentation/
│   ├── pages/
│   ├── cubit/
│   └── widgets/
├── domain/
│   ├── entities/
│   ├── repositories/
│   └── usecases/
└── data/
    ├── models/
    ├── datasources/
    └── repositories/
```

Keep domain code independent of Flutter, Dio, JSON serialization, and
database implementation details.

A typical flow is:

`Page → Cubit → UseCase → Repository interface → Repository implementation → Data source`

Cubits should depend on use cases rather than directly calling APIs or
database clients. Repository methods should expose typed success/failure
results and keep transport or parsing exceptions inside the data layer.

------------------------------------------------------------------------

## 10. Drawing document model

The drawing document is the central contract shared by the Flutter
client and Go backend. Treat its schema as versioned API data.

### 10.1 Document shape

Illustrative example:

``` json
{
  "schemaVersion": 1,
  "elements": [
    {
      "id": "element-001",
      "type": "rectangle",
      "x": 120.0,
      "y": 80.0,
      "width": 220.0,
      "height": 100.0,
      "rotation": 0.0,
      "stroke": "#202020",
      "strokeWidth": 2.0,
      "fill": "#FFFFFF"
    },
    {
      "id": "element-002",
      "type": "text",
      "x": 150.0,
      "y": 115.0,
      "text": "API Gateway",
      "fontSize": 18.0,
      "color": "#202020"
    }
  ]
}
```

This is an illustrative schema, not the final serialization contract.
Define exact field types, defaults, validation, and compatibility rules
before shipping.

### 10.2 Supported element types

  Type              Important properties
  ----------------- --------------------------------------------------------
  Rectangle         Position, width, height, stroke, fill, rotation
  Ellipse           Position, dimensions, stroke, fill
  Line              Start and end points, stroke
  Arrow             Start and end points, stroke, arrowhead style
  Freehand stroke   Ordered points, stroke, width
  Text              Position, text, font size, color, alignment
  Image             Position, dimensions, asset reference
  Group             Child element IDs or a defined grouping representation

Do not allow arbitrary unvalidated data from clients to become trusted
server state.

### 10.3 Stable identifiers

Every element should have a stable unique ID. Operations refer to
element IDs rather than array indexes because indexes change when
elements are inserted, deleted, or reordered.

Operation IDs should also be unique so retried requests can be
deduplicated.

### 10.4 Coordinate system

Keep the document in world coordinates and treat the viewport as a
transform:

-   World coordinates describe where elements exist in the drawing.
-   Screen coordinates describe where elements appear on the display.
-   Zoom and pan convert between these coordinate systems.

A simplified transform is:

``` text
screenPoint = (worldPoint * zoom) + panOffset
worldPoint = (screenPoint - panOffset) / zoom
```

The exact transform should account for the chosen canvas origin and
gesture focal point.

### 10.5 Schema evolution

Include a schema version from the beginning. When a document format
changes:

1.  Define the migration or compatibility behavior.
2.  Update parsing and validation.
3.  Preserve the ability to open supported older documents.
4.  Test old snapshots against the new client.
5.  Avoid destructive migrations without a recovery strategy.

### 10.6 Document size

JSONB is appropriate for board snapshots, but very large boards may need
a different strategy. Measure actual board sizes and save frequency
before introducing per-element rows, chunked documents, or operation
logs.

------------------------------------------------------------------------

## 11. Database design

The following schema is conceptual. Use migrations to create and evolve
the actual tables.

### 11.1 Users

``` sql
CREATE TABLE users (
    id UUID PRIMARY KEY,
    email TEXT NOT NULL UNIQUE,
    display_name TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
```

Authentication secrets, password hashes, or external identity references
should be handled according to the chosen authentication model. Never
store plaintext passwords.

### 11.2 Projects

``` sql
CREATE TABLE projects (
    id UUID PRIMARY KEY,
    owner_id UUID NOT NULL REFERENCES users(id),
    name TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX projects_owner_updated_idx
    ON projects(owner_id, updated_at DESC);
```

### 11.3 Project members

``` sql
CREATE TABLE project_members (
    project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role TEXT NOT NULL CHECK (role IN ('viewer', 'editor', 'owner')),
    joined_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (project_id, user_id)
);
```

The owner relationship and membership model should have a clear source
of truth. Enforce invariants so the owner cannot accidentally lose
ownership through an ordinary member-removal operation.

### 11.4 Boards

``` sql
CREATE TABLE boards (
    id UUID PRIMARY KEY,
    project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    content JSONB NOT NULL DEFAULT '{"schemaVersion":1,"elements":[]}'::jsonb,
    revision BIGINT NOT NULL DEFAULT 0,
    created_by UUID NOT NULL REFERENCES users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX boards_project_updated_idx
    ON boards(project_id, updated_at DESC);
```

Consider storing viewport state separately if it should be personal to
each user. A shared board-level viewport means one user's camera state
may affect everyone, which is usually undesirable.

### 11.5 Invitations

``` sql
CREATE TABLE invitations (
    id UUID PRIMARY KEY,
    project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    invited_email TEXT NOT NULL,
    role TEXT NOT NULL CHECK (role IN ('viewer', 'editor')),
    token_hash TEXT NOT NULL UNIQUE,
    expires_at TIMESTAMPTZ NOT NULL,
    accepted_at TIMESTAMPTZ,
    created_by UUID NOT NULL REFERENCES users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
```

Store a hash of a high-entropy invitation token, not the raw token.
Validate expiry, email/account matching rules, and whether the
invitation has already been accepted.

### 11.6 Optional future tables

Add these only when their behavior is defined and needed:

-   `board_operations` --- operation log for replay or recovery.
-   `board_snapshots` --- historical snapshots.
-   `board_assets` --- metadata for uploaded files.
-   `user_board_preferences` --- per-user viewport and recent-board
    state.
-   `audit_events` --- security-sensitive actions and sharing changes.

### 11.7 Data access principles

-   Use foreign keys for relationships.
-   Use transactions for multi-table changes.
-   Validate JSON structure and limits before saving.
-   Use parameterized SQL.
-   Enforce authorization in the service layer on every protected
    operation.
-   Use optimistic concurrency or revision checks to avoid silent lost
    updates.
-   Add indexes based on real query patterns.

------------------------------------------------------------------------

## 12. Persistence and recovery

Reliable persistence is one of the most important product requirements.

### 12.1 Three relevant states

The client should distinguish:

1.  **Local state:** what is currently visible and stored on the device.
2.  **Pending state:** local changes not yet acknowledged by the server.
3.  **Server state:** the latest committed revision known to the
    backend.

A successful local write does not mean the server has received the
changes. The UI should communicate that distinction honestly.

### 12.2 Save pipeline

``` mermaid
flowchart TD
    E[User edits an element]
    M[Update in-memory document]
    L[Persist local snapshot or pending operation]
    D[Debounce remote save]
    N{Network available?}
    Q[Keep operation pending and retry later]
    S[Send changes with base revision]
    V[Validate and persist on server]
    A[Return acknowledgement and revision]
    C[Mark acknowledged changes as synchronized]

    E --> M --> L --> D --> N
    N -- No --> Q
    Q --> N
    N -- Yes --> S --> V --> A --> C
```

### 12.3 Autosave behavior

-   Persist local changes promptly after meaningful edits.
-   Debounce remote snapshot saves to avoid sending the entire document
    for every pointer movement.
-   For freehand drawing, batch point updates during a stroke.
-   Send a final operation when the stroke ends.
-   Keep a queue of unacknowledged operations or equivalent pending
    state.
-   Retry network failures with bounded exponential backoff and jitter.
-   Use operation IDs or idempotency keys to make retries safe.
-   Keep a visible sync indicator.
-   Never discard pending changes simply because a request timed out.

### 12.4 Reopening a board

A possible loading strategy:

1.  Open the last local snapshot immediately when available.
2.  Fetch the server board and revision.
3.  Compare local pending state with the server state.
4.  Apply or reconcile pending operations according to the revision
    protocol.
5.  Persist the reconciled state locally.
6.  Display the board as fully synchronized only when confirmed.

The exact merge policy must be designed alongside collaboration.
Replacing the local document with a remote snapshot without considering
pending edits can destroy unsynchronized work.

### 12.5 Undo and redo

Undo/redo is initially local editing history. Collaboration makes
history more complex: undoing a local edit should not accidentally
remove another user's later edit.

For the MVP, maintain a local command/history stack and define how
operations are reversed. A future shared undo model can use explicit
compensating operations rather than restoring an old full-board
snapshot.

------------------------------------------------------------------------

## 13. Real-time collaboration

### 13.1 Room model

Each active board has a logical room. A room tracks connected clients
and transient session information.

The room can manage:

-   Connected client IDs
-   Authenticated user IDs
-   Board ID
-   Permissions
-   Presence and cursor state
-   Operation sequencing
-   Broadcast queues
-   Connection cleanup

The room is an in-memory coordination mechanism, not the permanent
source of truth. PostgreSQL remains responsible for durable state.

### 13.2 Operation flow

1.  The client applies an edit optimistically to its local model.
2.  It writes the pending operation locally.
3.  It sends the operation to the backend.
4.  The backend authenticates the connection and checks board access.
5.  The backend validates the operation and checks revision or sequence
    constraints.
6.  The backend assigns or confirms an ordering/revision.
7.  The operation is broadcast to authorized clients.
8.  The operation or resulting snapshot is persisted according to the
    durability strategy.
9.  The sender receives acknowledgement.
10. Clients reconcile duplicates and handle missing revisions.

Define whether persistence happens before broadcast or whether the
system uses a more advanced durable event pipeline. For the MVP,
durability and predictable recovery are more important than minimizing
every millisecond of latency.

### 13.3 Message categories

**Persistent operations** - Create an element - Update element
properties - Delete an element - Reorder elements - Create or remove a
group

**Transient messages** - Cursor movement - Current selection - Typing or
drawing presence - Temporary interaction previews

Persistent operations need deduplication, validation, and revision
semantics. Transient messages can be throttled and dropped when stale.

### 13.4 Concurrent edits

Two users may edit the same element at the same time. Define a policy
instead of assuming this will not happen.

A pragmatic initial policy:

-   Assign stable element and operation IDs.
-   Let the server order accepted operations.
-   Use board revisions and explicit conflict responses.
-   Avoid silently accepting a stale full-document overwrite.
-   Make duplicate operations harmless.
-   Provide a refresh/resync path when a client misses events.

For simultaneous edits to the same property, a simple
server-authoritative last-accepted-write policy may be sufficient
initially, provided its behavior is explicit. More advanced merging can
be introduced when requirements justify it.

### 13.5 Why not CRDTs immediately?

CRDTs can help with offline-first concurrent editing, but they add
complexity around element lifecycle, operation encoding, compaction,
history, and data migration.

Start with a revisioned operation protocol and reliable
resynchronization. Adopt a CRDT only if product requirements demand
seamless offline merging or highly concurrent editing.

### 13.6 Scaling rooms

A single Go process can own active rooms for the first version. When
running multiple backend instances, a user connected to instance A may
need to receive an event originating at instance B.

At that point, consider:

-   Redis Pub/Sub or another inter-instance messaging mechanism.
-   Consistent room ownership or routing.
-   Shared durable operation storage.
-   Connection draining during deployment.
-   Presence expiration and cleanup.

Do not use Redis as the only durable source of drawing data.

------------------------------------------------------------------------

## 14. API design

Use versioned REST endpoints, for example `/api/v1`. Exact request and
response models should be documented in OpenAPI.

### 14.1 Authentication

  Method   Endpoint                  Purpose
  -------- ------------------------- ---------------------------------
  `POST`   `/api/v1/auth/register`   Register an account
  `POST`   `/api/v1/auth/login`      Sign in
  `POST`   `/api/v1/auth/refresh`    Refresh a session, if supported
  `POST`   `/api/v1/auth/logout`     End a session
  `GET`    `/api/v1/me`              Get current user

Authentication details depend on whether the application uses
email/password, OAuth, or an external identity provider.

### 14.2 Projects

  -------------------------------------------------------------------------------------------------
  Method                  Endpoint                                          Purpose
  ----------------------- ------------------------------------------------- -----------------------
  `GET`                   `/api/v1/projects`                                List accessible
                                                                            projects

  `POST`                  `/api/v1/projects`                                Create a project

  `GET`                   `/api/v1/projects/{projectId}`                    Get project details

  `PATCH`                 `/api/v1/projects/{projectId}`                    Rename or update
                                                                            metadata

  `DELETE`                `/api/v1/projects/{projectId}`                    Delete a project

  `GET`                   `/api/v1/projects/{projectId}/members`            List members

  `POST`                  `/api/v1/projects/{projectId}/invitations`        Invite a collaborator

  `DELETE`                `/api/v1/projects/{projectId}/members/{userId}`   Remove a member
  -------------------------------------------------------------------------------------------------

### 14.3 Boards

  ---------------------------------------------------------------------------------------
  Method                  Endpoint                                Purpose
  ----------------------- --------------------------------------- -----------------------
  `GET`                   `/api/v1/projects/{projectId}/boards`   List boards

  `POST`                  `/api/v1/projects/{projectId}/boards`   Create a board

  `GET`                   `/api/v1/boards/{boardId}`              Fetch a board snapshot

  `PATCH`                 `/api/v1/boards/{boardId}`              Update metadata

  `PUT`                   `/api/v1/boards/{boardId}/content`      Save a full snapshot
                                                                  with concurrency
                                                                  protection

  `POST`                  `/api/v1/boards/{boardId}/operations`   Submit operations, if
                                                                  using an HTTP operation
                                                                  path

  `DELETE`                `/api/v1/boards/{boardId}`              Delete a board
  ---------------------------------------------------------------------------------------

Use the WebSocket for live operations once collaboration is enabled. The
HTTP operation endpoint is optional and may be useful for recovery,
testing, or clients that cannot maintain a socket.

### 14.4 Invitations

  ---------------------------------------------------------------------------------------
  Method                  Endpoint                                Purpose
  ----------------------- --------------------------------------- -----------------------
  `GET`                   `/api/v1/invitations/{token}`           Inspect a valid
                                                                  invitation

  `POST`                  `/api/v1/invitations/{token}/accept`    Accept an invitation

  `POST`                  `/api/v1/invitations/{token}/decline`   Decline an invitation
  ---------------------------------------------------------------------------------------

Avoid leaking invitation tokens in logs, analytics, or error reports.

### 14.5 Example board response

``` json
{
  "id": "a-board-uuid",
  "projectId": "a-project-uuid",
  "name": "Service Architecture",
  "revision": 42,
  "content": {
    "schemaVersion": 1,
    "elements": []
  },
  "updatedAt": "2026-10-17T10:00:00Z"
}
```

The IDs and timestamp above are illustrative. Define consistent casing,
error formats, and pagination rules for the actual API.

### 14.6 Concurrency protection

A full-snapshot save should include the revision the client based its
changes on. If the server revision has changed, return a conflict
response rather than blindly replacing newer content.

For example:

``` json
{
  "error": {
    "code": "REVISION_CONFLICT",
    "message": "The board has changed since this version was loaded.",
    "currentRevision": 43
  }
}
```

Clients must have a defined recovery behavior for this response.

### 14.7 API conventions

-   Use UUIDs or another consistently defined identifier format.
-   Validate inputs at the boundary.
-   Return appropriate HTTP status codes.
-   Use structured error codes.
-   Apply pagination to potentially large collections.
-   Enforce request body and document size limits.
-   Avoid exposing internal stack traces.
-   Document authorization requirements per endpoint.

------------------------------------------------------------------------

## 15. WebSocket protocol

Use a documented, versioned message protocol. Example endpoint:

``` text
GET /api/v1/boards/{boardId}/ws
```

Authenticate the connection using a secure mechanism appropriate for the
client. Verify authorization before allowing the client to join the
room.

### 15.1 Client messages

Example operation:

``` json
{
  "type": "operation",
  "protocolVersion": 1,
  "operationId": "client-generated-unique-id",
  "baseRevision": 42,
  "operation": {
    "type": "element.created",
    "element": {
      "id": "element-123",
      "type": "rectangle",
      "x": 100,
      "y": 100,
      "width": 180,
      "height": 80
    }
  }
}
```

Example cursor update:

``` json
{
  "type": "presence.cursor",
  "x": 320.0,
  "y": 240.0
}
```

Cursor messages are transient and should be rate-limited.

### 15.2 Server messages

Example accepted operation:

``` json
{
  "type": "operation.accepted",
  "operationId": "client-generated-unique-id",
  "revision": 43
}
```

Example broadcast:

``` json
{
  "type": "operation.applied",
  "actorId": "user-uuid",
  "revision": 43,
  "operation": {
    "type": "element.created",
    "element": {
      "id": "element-123",
      "type": "rectangle",
      "x": 100,
      "y": 100,
      "width": 180,
      "height": 80
    }
  }
}
```

Example error:

``` json
{
  "type": "error",
  "code": "REVISION_CONFLICT",
  "message": "Resynchronization is required."
}
```

### 15.3 Connection lifecycle

The client should handle:

-   Connection establishment
-   Authentication failure
-   Permission revocation
-   Heartbeats or liveness checks
-   Network loss
-   Reconnection with backoff
-   Duplicate messages
-   Missing revisions
-   Server shutdown
-   Room membership cleanup

### 15.4 Backpressure

A slow client should not block every other client in a room. Use bounded
outbound queues and a clear policy for slow consumers. If persistent
operations cannot be delivered safely, disconnect the client and require
resynchronization rather than silently dropping critical edits.

------------------------------------------------------------------------

## 16. Flutter application architecture

### 16.1 Layers

**Presentation** - Pages and widgets - Cubits and immutable UI states -
Canvas overlays and toolbars - Project and board navigation - Save/sync
indicators

**Domain** - Entities and value objects - Repository interfaces - Use
cases - Drawing and permission rules that do not depend on Flutter

**Data** - API data sources - Local persistence data sources - Models
and serialization - Repository implementations - Mapping between data
models and domain entities

### 16.2 Suggested features

-   `auth`: login, registration, session
-   `projects`: project list, create, rename, delete
-   `boards`: board list, loading, metadata
-   `canvas`: document model, renderer, tools, selection, history
-   `collaboration`: WebSocket connection, operations, presence, resync
-   `settings`: user preferences and account settings

### 16.3 Canvas engine separation

Do not put all drawing logic inside a page widget or one giant Cubit.

Separate:

-   **Document model:** elements and their properties.
-   **Interaction controller:** current tool, selection, gesture state.
-   **Renderer:** paints document elements.
-   **Hit-testing:** identifies the element under a pointer.
-   **Viewport controller:** zoom and pan.
-   **History manager:** undo/redo operations.
-   **Serialization:** converts documents to/from versioned data.
-   **Sync engine:** tracks pending operations and revisions.

The canvas engine should be testable without requiring the complete
application UI.

### 16.4 Rendering

Flutter's `CustomPainter` can draw many basic vector elements. Consider
`RepaintBoundary`, repaint notifications, spatial indexing, and
selective rendering as profiling shows a need.

Avoid triggering full network saves or broad application rebuilds on
every pointer event. A freehand stroke should be rendered interactively,
then committed as a coherent document operation.

### 16.5 State ownership

Separate transient UI state from persisted document state.

Transient examples: - Active tool - Hovered element - Temporary
selection rectangle - In-progress stroke - Drag preview

Persistent examples: - Element positions - Text content - Stroke
points - Element styling - Board metadata

Not every mouse movement should mutate the durable document or cause a
server write.

------------------------------------------------------------------------

## 17. Go backend architecture

Use a modular monolith with clear package boundaries.

### 17.1 Suggested responsibilities

**HTTP layer** - Routing - Request decoding - Validation at boundaries -
Authentication middleware - Error-to-HTTP mapping

**Application/services** - Project and board use cases - Membership
management - Authorization - Revision handling - Snapshot persistence -
Invitation lifecycle

**Domain** - Project and board concepts - Role and permission rules -
Operation validation - Revision/conflict rules

**Persistence** - PostgreSQL queries - Transactions - Repository
implementations - Migrations

**Collaboration** - WebSocket lifecycle - Room membership - Incoming
message validation - Event sequencing and broadcast -
Reconnection/resync support

**Observability** - Structured logging - Metrics - Tracing where
useful - Health endpoints

### 17.2 Go concurrency rules

-   Give each connection a controlled read/write lifecycle.
-   Avoid concurrent writes to a WebSocket connection unless the library
    explicitly supports the usage.
-   Use bounded channels for outgoing messages.
-   Clean up disconnected clients from rooms.
-   Use context cancellation for requests and background tasks.
-   Avoid unbounded goroutine creation.
-   Apply timeouts to database and network operations.
-   Run tests with the Go race detector.

### 17.3 Graceful shutdown

On shutdown:

1.  Stop accepting new HTTP connections.
2.  Stop accepting new WebSocket sessions.
3.  Notify or close active sessions according to the protocol.
4.  Stop background workers.
5.  Finish or safely abandon work that can be retried.
6.  Close database resources.

Do not assume that every in-memory event has been persisted. Durable
acknowledgement semantics must be explicit.

------------------------------------------------------------------------

## 18. Security and permissions

Security must be enforced by the backend, not just hidden in the UI.

### Authentication

-   Use a well-reviewed authentication approach.
-   Store password hashes, never plaintext passwords, if managing
    passwords.
-   Expire and rotate sessions appropriately.
-   Protect tokens from logs and accidental exposure.
-   Use TLS in deployed environments.

### Authorization

-   Check access to every project, board, invitation, and asset.
-   Verify editor permissions before accepting drawing changes.
-   Verify viewer permissions before allowing read-only room access.
-   Recheck or revoke active access when membership changes.
-   Do not trust a client-supplied user ID or role.

### WebSockets

-   Authenticate the connection.
-   Validate the requested board and membership.
-   Validate every operation and its size.
-   Rate-limit excessive messages.
-   Limit concurrent connections and room sizes according to deployment
    capacity.
-   Close sessions when access is revoked.

### Input validation

-   Limit document and message sizes.
-   Validate element types and numeric values.
-   Reject NaN, infinity, invalid dimensions, malformed IDs, and
    unsupported schema versions.
-   Restrict asset types and upload sizes.
-   Sanitize text when rendered in contexts where injection could occur.

### Invitations

-   Use cryptographically secure, high-entropy tokens.
-   Store token hashes.
-   Set expiration times.
-   Make acceptance idempotent where appropriate.
-   Avoid revealing whether unrelated accounts exist.

### Data protection

-   Use environment variables or a secret manager for credentials.
-   Apply least-privilege database permissions.
-   Back up PostgreSQL and test restores.
-   Define retention and deletion behavior.
-   Avoid logging full board contents or secrets by default.

------------------------------------------------------------------------

## 19. Error handling and reliability

Failures should be expected and recoverable.

### Client errors

-   Invalid drawing operation
-   Local database write failure
-   Network timeout
-   Authentication expiration
-   Permission revoked
-   Revision conflict
-   Unsupported document schema
-   WebSocket disconnect

### Server errors

-   Database unavailable
-   Invalid request
-   Authorization failure
-   Duplicate operation
-   Stale revision
-   Rate limit exceeded
-   Room overloaded
-   Internal failure

### Reliability principles

-   Keep local work durable before treating it as safely queued.
-   Use idempotency keys for retried operations.
-   Do not silently ignore rejected edits.
-   Make server acknowledgements explicit.
-   Make reconnection and resynchronization routine paths.
-   Use bounded retries and backoff.
-   Provide actionable error messages without leaking sensitive
    implementation details.
-   Keep a clear distinction between saved, pending, and failed states.

------------------------------------------------------------------------

## 20. Testing strategy

### 20.1 Flutter unit tests

Test:

-   Document serialization and deserialization
-   Element geometry
-   Coordinate transformations
-   Hit-testing
-   Undo/redo behavior
-   Operation creation and application
-   Local snapshot persistence
-   Revision reconciliation
-   Repository result mapping
-   Cubit state transitions

### 20.2 Flutter widget tests

Test:

-   Tool selection
-   Drawing and selection interactions
-   Project and board navigation
-   Autosave indicators
-   Loading and error states
-   Permission-based UI
-   Reopening a board from persisted data

### 20.3 Go unit tests

Test:

-   Project and board business rules
-   Permission checks
-   Request validation
-   Revision conflict handling
-   Duplicate operation handling
-   Invitation expiry and acceptance
-   WebSocket message validation
-   Room lifecycle and cleanup

### 20.4 Integration tests

Test against a real test PostgreSQL instance:

-   Migrations from an empty database
-   Project creation and ownership
-   Board creation and retrieval
-   Snapshot saves and stale revision rejection
-   Membership and permission enforcement
-   Invitation lifecycle
-   Database transaction behavior

### 20.5 Collaboration tests

At minimum, simulate two clients:

1.  Both connect to one board.
2.  Client A creates an element.
3.  Client B receives and applies it.
4.  Client B edits another element.
5.  Client A receives the update.
6.  One client disconnects and reconnects.
7.  The client resynchronizes without losing accepted operations.
8.  A viewer attempts an edit and is rejected.
9.  A duplicate operation is not applied twice.
10. A stale revision triggers the defined conflict flow.

### 20.6 Reliability tests

-   Kill the app after local save but before remote acknowledgement.
-   Restart and verify pending work is recoverable.
-   Simulate offline editing.
-   Simulate a database outage.
-   Send malformed or oversized WebSocket messages.
-   Run Go tests with `-race`.
-   Profile rendering with large boards.
-   Test migration and backup restoration procedures.

------------------------------------------------------------------------

## 21. Local development

### Prerequisites

Install:

-   Flutter SDK and the relevant platform toolchain
-   Go
-   Docker Desktop or a local PostgreSQL installation
-   Git
-   An IDE of your choice

Check the tools:

``` bash
flutter --version
go version
git --version
docker --version
docker compose version
```

### Start PostgreSQL

A development `docker-compose.yml` can start PostgreSQL:

``` yaml
services:
  postgres:
    image: postgres:17
    restart: unless-stopped
    environment:
      POSTGRES_DB: canvas
      POSTGRES_USER: canvas
      POSTGRES_PASSWORD: local-development-only
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U canvas -d canvas"]
      interval: 5s
      timeout: 3s
      retries: 10

volumes:
  postgres_data:
```

The credentials above are for local development only. Do not use them in
production. Do not expose the database publicly in a deployed
environment.

Start the database:

``` bash
docker compose up -d postgres
```

### Run the Go backend

The exact commands depend on the implemented configuration and migration
tooling. A typical workflow will look like:

``` bash
cd backend
go mod download
go test ./...
go run ./cmd/api
```

Run database migrations before starting the API when the application
requires them.

### Run the Flutter app

``` bash
cd app/flutter_app
flutter pub get
flutter analyze
flutter test
flutter run
```

Use the correct backend base URL for the selected platform. An Android
emulator's `localhost` is not the host machine's localhost; configure
the development endpoint accordingly.

### Suggested first development milestone

Before adding authentication or WebSockets, make a vertical slice work:

1.  Launch Flutter.
2.  Draw a rectangle and some text.
3.  Save the document locally.
4.  Restart the app.
5.  Restore the same document.
6.  Add the Go API and PostgreSQL persistence.
7.  Load and save the same board through the API.

This verifies the drawing document and persistence model before
collaboration increases complexity.

------------------------------------------------------------------------

## 22. Configuration

Keep a `.env.example` in the repository with placeholders only. Do not
commit real secrets.

Illustrative backend variables:

``` dotenv
APP_ENV=development
HTTP_ADDR=:8080
DATABASE_URL=postgres://canvas:local-development-only@localhost:5432/canvas?sslmode=disable
LOG_LEVEL=debug
CORS_ALLOWED_ORIGINS=http://localhost:3000
```

Add authentication, token, object-storage, and telemetry settings only
when those integrations exist.

Configuration principles:

-   Validate required settings on startup.
-   Use different credentials for development, staging, and production.
-   Never hardcode secrets in source code.
-   Keep TLS and database security requirements explicit per
    environment.
-   Do not disable production security checks to make local development
    easier.

------------------------------------------------------------------------

## 23. Deployment

### Initial production topology

``` mermaid
flowchart TB
    C[Flutter Clients]
    P[HTTPS / WSS Endpoint]
    G[Go API and WebSocket Server]
    D[(Managed PostgreSQL)]
    S[Object Storage]
    M[Monitoring and Logs]

    C --> P --> G
    G --> D
    G --> S
    G --> M
```

### Deployment checklist

-   [ ] Use HTTPS and WSS.
-   [ ] Store secrets outside the repository.
-   [ ] Run database migrations as a controlled deployment step.
-   [ ] Enable automated database backups.
-   [ ] Test backup restoration.
-   [ ] Restrict database network access.
-   [ ] Configure request and WebSocket message limits.
-   [ ] Configure graceful shutdown.
-   [ ] Monitor connection count and database pool usage.
-   [ ] Configure health and readiness checks.
-   [ ] Document rollback behavior.
-   [ ] Avoid logging access tokens or invitation secrets.
-   [ ] Verify CORS and origin policies for browser clients.
-   [ ] Test long-lived WebSocket behavior through the selected
    proxy/load balancer.

### Scaling path

**Stage 1:** one Go instance and PostgreSQL.

**Stage 2:** optimize database access, drawing payload sizes, connection
management, and room cleanup.

**Stage 3:** multiple Go instances with a shared inter-instance
messaging layer such as Redis Pub/Sub, plus room routing and
reconnection support.

**Stage 4:** evaluate durable operation logs, snapshot compaction, and
specialized scaling only if measurements justify them.

------------------------------------------------------------------------

## 24. Performance considerations

### Canvas rendering

-   Profile before optimizing.
-   Avoid unnecessary full-document rebuilds during pointer movement.
-   Batch freehand points.
-   Use repaint boundaries where beneficial.
-   Consider spatial indexing for hit-testing on large boards.
-   Keep rendering and serialization costs measurable.

### Network traffic

-   Do not send the complete board for every element movement.
-   Batch pointer samples.
-   Throttle presence and cursor messages.
-   Compress payloads only when measurements justify the CPU cost.
-   Avoid sending large images over WebSockets; upload assets
    separately.

### Database

-   Use connection pooling.
-   Keep transactions short.
-   Avoid rewriting large JSONB documents for every tiny pointer update.
-   Measure board sizes and save frequency.
-   Use operation batches and periodic snapshots if full-document saves
    become expensive.
-   Index common lookup paths.

### Memory

-   Bound outbound WebSocket queues.
-   Avoid retaining closed connections in rooms.
-   Set reasonable limits for element count and document size.
-   Consider culling off-screen rendering work for very large boards.

### Reliability versus throughput

The system should not report an operation as durably saved unless its
durability guarantee has been met. Choose and document the relationship
between persistence, broadcast, and acknowledgement before optimizing
latency.

------------------------------------------------------------------------

## 25. Observability

Instrument the backend enough to diagnose lost edits, slow saves, and
collaboration failures.

### Useful structured log fields

-   Request ID
-   Board ID
-   Operation ID
-   User ID, where appropriate and safe
-   Operation type
-   Revision
-   Error code
-   Connection lifecycle event

Avoid logging full document bodies or secrets.

### Useful metrics

-   HTTP request latency and error rate
-   Database query latency and pool saturation
-   Active WebSocket connections
-   Active rooms and room membership
-   Operation acceptance/rejection counts
-   Revision conflict rate
-   Save acknowledgement latency
-   Pending operation queue depth
-   Reconnection rate
-   Oversized or invalid message count
-   Snapshot size and persistence duration

### Tracing

Tracing can help follow a save from API entry through validation and
database commit. Introduce distributed tracing when there are enough
components to benefit from it.

The most important product-facing reliability metric is whether accepted
user edits remain recoverable after crashes and network failures.

------------------------------------------------------------------------

## 26. Development roadmap

The order below deliberately validates persistence before introducing
real-time complexity.

### Phase 0 --- Product and technical contracts

-   [ ] Confirm product name and terminology.
-   [ ] Define the first supported platforms.
-   [ ] Define the document schema and element types.
-   [ ] Define coordinate and viewport semantics.
-   [ ] Choose local persistence and serialization strategy.
-   [ ] Define revision and conflict behavior.
-   [ ] Set up repository, formatting, linting, and CI.

**Exit criterion:** the client and backend can agree on one versioned
board document.

### Phase 1 --- Drawing engine

-   [ ] Canvas pan and zoom
-   [ ] Rectangle and ellipse
-   [ ] Line and arrow
-   [ ] Freehand pen
-   [ ] Text elements
-   [ ] Selection, move, resize, delete
-   [ ] Undo/redo
-   [ ] Document serialization
-   [ ] Unit tests for geometry and history

**Exit criterion:** a user can create and edit a small diagram entirely
locally.

### Phase 2 --- Durable local persistence

-   [ ] Local database
-   [ ] Local snapshots
-   [ ] Recovery after process termination
-   [ ] Local document migrations
-   [ ] Pending change tracking
-   [ ] Saved/pending/error UI state

**Exit criterion:** the board survives closing and restarting the app
without a network connection.

### Phase 3 --- Backend and project organization

-   [ ] Go HTTP API
-   [ ] PostgreSQL migrations
-   [ ] Users and authentication
-   [ ] Project CRUD
-   [ ] Board CRUD
-   [ ] Board snapshot load/save
-   [ ] Revision conflict protection
-   [ ] Integration tests

**Exit criterion:** users can save boards remotely, organize them into
projects, and reopen them.

### Phase 4 --- Autosave and recovery

-   [ ] Debounced server autosave
-   [ ] Idempotent retries
-   [ ] Server acknowledgements
-   [ ] Offline pending queue
-   [ ] Reconnect synchronization
-   [ ] Conflict UX
-   [ ] Failure-injection tests

**Exit criterion:** temporary network failures do not silently discard
local edits.

### Phase 5 --- Sharing and permissions

-   [ ] Project membership
-   [ ] Viewer/editor roles
-   [ ] Invitations
-   [ ] Permission checks for REST endpoints
-   [ ] Permission checks for WebSocket joins
-   [ ] Membership revocation behavior

**Exit criterion:** only authorized collaborators can view or edit
shared content.

### Phase 6 --- Real-time collaboration

-   [ ] WebSocket lifecycle
-   [ ] Board rooms
-   [ ] Operation protocol
-   [ ] Server sequencing/revision handling
-   [ ] Remote cursors
-   [ ] Duplicate operation handling
-   [ ] Reconnection and resync
-   [ ] Two-client integration tests
-   [ ] Slow-consumer and disconnect handling

**Exit criterion:** two users can safely edit the same board and recover
from a temporary disconnect.

### Phase 7 --- Product polish

-   [ ] Board thumbnails
-   [ ] Export PNG
-   [ ] SVG export evaluation
-   [ ] Image attachments
-   [ ] Keyboard shortcuts
-   [ ] Search and sorting
-   [ ] Accessibility and responsive layouts
-   [ ] Performance profiling
-   [ ] Deployment automation and monitoring

**Exit criterion:** the app is usable as a personal drawing workspace
and a basic team tool.

------------------------------------------------------------------------

## 27. MVP acceptance criteria

The MVP is not complete merely because the canvas can draw shapes. It
should satisfy the following end-to-end checks.

### Drawing

-   [ ] A user can create, move, resize, and delete supported elements.
-   [ ] Undo/redo restores the expected document state.
-   [ ] The canvas supports pan and zoom.
-   [ ] Document serialization preserves supported properties.

### Persistence

-   [ ] Local changes are saved without a manual save action.
-   [ ] The current board can be reopened after an app restart.
-   [ ] A remote save failure is visible to the user.
-   [ ] Pending local changes are not discarded on a timeout.
-   [ ] A stale full-document write cannot silently overwrite a newer
    server revision.

### Projects

-   [ ] A user can create projects and boards.
-   [ ] Boards can be renamed and reopened.
-   [ ] Access to projects and boards is checked on the backend.

### Collaboration

-   [ ] Two authorized clients can join the same board.
-   [ ] A supported edit from one client reaches the other.
-   [ ] Duplicate operations are not applied twice.
-   [ ] Reconnection triggers synchronization.
-   [ ] A viewer cannot edit.
-   [ ] Revoked users cannot continue submitting authorized edits.

### Quality

-   [ ] Flutter analysis and tests pass.
-   [ ] Go unit and integration tests pass.
-   [ ] Database migrations work from an empty database.
-   [ ] The Go backend passes race-detector tests for relevant
    concurrency paths.
-   [ ] Setup instructions are reproducible on a clean development
    machine.

------------------------------------------------------------------------

## 28. Risks and trade-offs

  -----------------------------------------------------------------------
  Risk                    Why it matters          Mitigation
  ----------------------- ----------------------- -----------------------
  Canvas complexity grows Gestures, hit-testing,  Build a small drawing
  quickly                 selection, and history  engine in stages and
                          interact                test its model
                                                  independently

  Lost updates            Concurrent clients may  Revision checks,
                          overwrite each other    operation IDs,
                                                  acknowledgements,
                                                  explicit conflict
                                                  handling

  App termination         A final close callback  Local autosave on
                          may never run           changes and durable
                                                  pending operations

  Large board snapshots   Rewriting JSONB can     Measure first; batch
                          become expensive        operations and add
                                                  snapshots/logs if
                                                  needed

  WebSocket overload      Slow clients can        Bounded queues, rate
                          consume memory or block limits,
                          a room                  disconnect/resync
                                                  behavior

  Offline conflicts       Independent edits may   Start with explicit
                          conflict after          conflict policy;
                          reconnection            consider CRDTs if
                                                  requirements justify
                                                  them

  Schema evolution        Old boards may become   Versioned documents and
                          unreadable              tested migrations

  Permission gaps         A hidden UI button is   Server-side
                          not security            authorization on every
                                                  protected action

  Premature               Redis, Kafka, and       Start with a modular
  infrastructure          microservices add       monolith and scale from
                          operational cost        measured bottlenecks

  Package lock-in         A drawing package may   Own the document
                          constrain future        contract and evaluate
                          editing behavior        package limitations
                                                  early
  -----------------------------------------------------------------------

------------------------------------------------------------------------

## 29. Future possibilities

These are deliberately outside the first MVP:

-   Board version history and restore
-   Personal and shared workspaces
-   Public read-only links
-   Comments and annotations
-   Templates for architecture diagrams and flowcharts
-   Layers and grouping
-   Snap-to-grid and alignment guides
-   Connectors that attach to shapes
-   Import/export of additional formats
-   Image uploads and asset management
-   Search across board titles and text
-   Collaborative cursors and selections with richer presence
-   Offline conflict-free collaboration using CRDTs
-   Multi-instance WebSocket scaling
-   Team administration and audit history
-   Mobile stylus improvements
-   Desktop keyboard shortcuts and context menus
-   AI assistance for generating or explaining diagrams

Prioritize future features based on actual use and measured pain points
rather than implementing every possible drawing-tool feature at once.

------------------------------------------------------------------------

## 30. Contributing

Contributions should preserve the separation between drawing logic,
persistence, transport, and UI.

### Development guidelines

-   Keep changes focused.
-   Add tests for behavior changes.
-   Document changes to the board schema and WebSocket protocol.
-   Use migrations for database changes.
-   Never commit secrets or real user data.
-   Validate input at trust boundaries.
-   Avoid adding infrastructure without a clear need.
-   Keep local development instructions up to date.

### Before opening a pull request

Run the relevant checks:

``` bash
# Flutter
flutter format --set-exit-if-changed .
flutter analyze
flutter test

# Go
gofmt -w .
go vet ./...
go test ./...
```

Run integration tests against a disposable test database where
applicable. Exact commands may be adjusted as the repository and CI
pipeline are established.

### Architecture decision records

Record significant decisions in `docs/decisions/`, for example:

-   Why PostgreSQL JSONB was selected
-   Why the document format is versioned
-   How revisions and conflicts work
-   What a successful save acknowledgement guarantees
-   Why the first collaboration protocol does or does not use CRDTs
-   How authentication works for WebSocket connections

Each decision should capture the context, options considered, chosen
approach, and consequences.

------------------------------------------------------------------------

## 31. License

No license has been selected yet. Choose and add a license file before
making the repository public or accepting external contributions. Until
then, do not assume the source is available for unrestricted reuse.

------------------------------------------------------------------------

## Final summary

Canvas is a persistent, project-based drawing workspace built with
Flutter and Go.

Its foundation is:

-   **Flutter** for the interactive canvas and cross-platform
    experience.
-   **Go** for REST APIs, authorization, persistence workflows, and
    WebSocket collaboration.
-   **PostgreSQL + JSONB** for relational project data and editable
    drawing documents.
-   **Local persistence** for recovery and offline resilience.
-   **Revisioned operations over WebSockets** for live collaboration.
-   **A modular monolith** that can scale as real usage demands.

The implementation priority is intentional:

**Drawing engine → local durability → projects and remote persistence →
autosave/recovery → permissions → real-time collaboration → polish and
scale.**

The defining quality of the product should be trust: users can draw,
close the app, come back later, and find their work still there---and
when they invite others, everyone's edits are handled predictably.
