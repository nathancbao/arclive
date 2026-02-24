-- ArcLive Gym Occupancy Tracker — Postgres Schema
-- Apply via: psql $DATABASE_URL -f db/schema.sql
--            or paste into Supabase SQL Editor

-- Enable UUID generation
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ─────────────────────────────────────────────
-- visits
-- Each row represents one gym visit (check-in / check-out pair).
-- check_out_time is NULL while the visit is still active.
-- ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS visits (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    device_id       UUID        NOT NULL,
    check_in_time   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    check_out_time  TIMESTAMPTZ,         -- NULL = currently checked in
    exercise_type   TEXT        CHECK (exercise_type IN ('chest', 'back', 'legs', 'arms', 'cardio'))
);

-- ─────────────────────────────────────────────
-- Indexes
-- ─────────────────────────────────────────────

-- CRITICAL: Enforces at most ONE active visit per device.
-- Because this is a *partial* index (WHERE check_out_time IS NULL),
-- it only covers open visits. Past visits are unrestricted.
CREATE UNIQUE INDEX IF NOT EXISTS idx_visits_device_active
    ON visits (device_id)
    WHERE check_out_time IS NULL;

-- Fast occupancy count: COUNT(*) WHERE check_out_time IS NULL
CREATE INDEX IF NOT EXISTS idx_visits_active
    ON visits (check_out_time)
    WHERE check_out_time IS NULL;

-- Fast lookup by device (used in checkout and status checks)
CREATE INDEX IF NOT EXISTS idx_visits_device_id
    ON visits (device_id);
