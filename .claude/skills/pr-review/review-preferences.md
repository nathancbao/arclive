# Review preferences

What this team wants reviewers (and Claude) to flag, or to leave alone. The `pr-review` skill reads this on every review and adds to it in its Learn step.

Add one line per preference, with the reason, and delete lines that stop being true. Changes go through a PR.

## Always flag

<!-- Example: - A new endpoint without a rate limit. Why: the existing ones all have one, and check-ins are abusable. -->

None yet.

## Don't flag

<!-- Example: - `datetime.timezone.utc` instead of `datetime.UTC`. Why: both work, and ruff's UP017 is turned off on purpose. -->

- `datetime.timezone.utc` instead of `datetime.UTC`. Why: both work, and ruff's `UP017` is turned off on purpose in `backend/pyproject.toml`.
