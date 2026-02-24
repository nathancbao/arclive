-- Migration: add exercise_type to visits
-- Run once in Supabase SQL Editor

ALTER TABLE visits
    ADD COLUMN IF NOT EXISTS exercise_type TEXT
    CHECK (exercise_type IN ('chest', 'back', 'legs', 'arms', 'cardio'));
