# ArcLive — Gym Occupancy Tracker

Real-time gym check-in / check-out tracking.
No user accounts — every install gets a stable device UUID.

---

## System Architecture

```
┌────────────────────┐        HTTPS         ┌─────────────────────────┐
│   iOS App          │ ──── POST /checkin ──▶│   FastAPI Backend       │
│   (SwiftUI/MVVM)   │ ──── POST /checkout ─▶│   (Python + asyncpg)    │
│                    │ ──── GET  /occupancy ─▶│                         │
│  Stores device_id  │                       │  Validates requests      │
│  in UserDefaults   │◀─── JSON response ───│  Enforces 1 visit/device │
└────────────────────┘                       └──────────┬──────────────┘
                                                        │ async SQL
                                             ┌──────────▼──────────────┐
                                             │   Supabase (Postgres)   │
                                             │                         │
                                             │  visits table           │
                                             │  + partial unique index │
                                             └─────────────────────────┘
```

**iOS App** — generates/reads a UUID from `UserDefaults`, calls the API, shows occupancy and check-in state.

**FastAPI Backend** — stateless HTTP API. All business logic lives here: duplicate-check-in detection, safe checkout, occupancy aggregation.

**Postgres (Supabase)** — single source of truth. The partial unique index on `(device_id) WHERE check_out_time IS NULL` is the database-level guarantee that no device can have two active visits, even under concurrent load.

---

## Repo Structure

```
arclive/
├── backend/
│   ├── app/
│   │   ├── main.py          ← FastAPI app + CORS
│   │   ├── database.py      ← async engine, session factory
│   │   ├── models.py        ← SQLAlchemy ORM model (Visit)
│   │   ├── schemas.py       ← Pydantic request/response schemas
│   │   └── routers/
│   │       ├── checkin.py   ← POST /checkin
│   │       ├── checkout.py  ← POST /checkout
│   │       └── occupancy.py ← GET /occupancy
│   ├── requirements.txt
│   └── .env.example
├── db/
│   └── schema.sql           ← Postgres DDL + indexes
├── ios/ArcLive/
│   ├── ArcLiveApp.swift
│   ├── Utilities/DeviceIdentifier.swift
│   ├── Models/
│   │   ├── Visit.swift
│   │   └── OccupancyResponse.swift
│   ├── Services/APIClient.swift
│   ├── ViewModels/
│   │   ├── CheckInViewModel.swift
│   │   └── OccupancyViewModel.swift
│   └── Views/
│       ├── ContentView.swift
│       ├── CheckInView.swift
│       └── OccupancyView.swift
└── README.md
```

---

## Database Schema

See `db/schema.sql`. Key design decisions:

```sql
CREATE TABLE visits (
    id             UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    device_id      UUID        NOT NULL,
    check_in_time  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    check_out_time TIMESTAMPTZ           -- NULL = active visit
);

-- THE critical constraint: at most one open visit per device
CREATE UNIQUE INDEX idx_visits_device_active
    ON visits (device_id)
    WHERE check_out_time IS NULL;
```

The **partial unique index** is the correctness anchor. It is enforced by Postgres atomically, so even if two check-in requests arrive simultaneously for the same device, exactly one will succeed and the other will receive a `409 Conflict`.

---

## API Reference

### `POST /checkin`
```json
// Request
{ "device_id": "550e8400-e29b-41d4-a716-446655440000" }

// 201 Created
{
  "id": "...",
  "device_id": "550e8400-...",
  "check_in_time": "2024-01-15T09:00:00Z",
  "check_out_time": null
}

// 409 Conflict — already checked in
{ "detail": "Device is already checked in." }
```

### `POST /checkout`
```json
// Request
{ "device_id": "550e8400-e29b-41d4-a716-446655440000" }

// 200 OK
{
  "id": "...",
  "device_id": "550e8400-...",
  "check_in_time": "2024-01-15T09:00:00Z",
  "check_out_time": "2024-01-15T10:30:00Z"
}

// 404 Not Found — not checked in
{ "detail": "No active visit found for this device." }
```

### `GET /occupancy`
```json
// 200 OK
{ "count": 42 }
```

---

## Backend Setup

```bash
cd backend
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt

cp .env.example .env
# Edit .env: set DATABASE_URL to your Supabase connection string

# Apply the schema (once, in Supabase SQL Editor or via psql)
psql $DATABASE_URL -f ../db/schema.sql

# Run locally
uvicorn app.main:app --reload
```

Interactive API docs available at http://localhost:8000/docs

---

## iOS Setup

1. Open Xcode → **Create a new project** → iOS App
2. **Product Name** = `ArcLive`, Interface = SwiftUI, Language = Swift
3. Delete the default `ContentView.swift` Xcode generates
4. Drag the entire `ios/ArcLive/` folder into the Xcode project navigator
5. Set `API_BASE_URL` in the scheme's environment variables:
   - `http://localhost:8000` for simulator
   - Your deployed server URL for device testing

The `device_id` is generated automatically on first launch and persisted in `UserDefaults`. No configuration needed.

---

## Scalability Notes

- **100+ concurrent users**: Postgres handles this easily. The async backend uses a connection pool; each connection serves many requests.
- **Partial unique index**: enforced atomically by Postgres — no application-level locking needed for check-in deduplication.
- **SELECT FOR UPDATE** in checkout: Row-level lock prevents two simultaneous checkout requests from the same device racing each other.
- **When to add a counters table**: If `/occupancy` is called thousands of times per second, maintain a `current_count INT` incremented/decremented in the same transaction as the visit write.
- **Rate limiting**: Add at the reverse-proxy level (nginx, Fly.io, Railway) rather than in application code.

---

## Future-Proofing: Replacing `device_id` with `member_id`

| Layer | What changes |
|-------|-------------|
| DB | Add `member_id UUID NULLABLE` to `visits`. Replace the partial unique index. Keep `device_id` during rollout. |
| API | Accept either `member_id` or `device_id` (validate exactly one is provided). Same endpoints, same responses. |
| iOS | Replace `DeviceIdentifier.id` with a scanned QR code or typed member number. `APIClient` is unchanged. |

Keep both columns during the migration window so existing installs keep working. Remove `device_id` after all clients have updated.
