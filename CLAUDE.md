# ArcLive

Real-time gym occupancy tracker. An iOS app checks people in and out, and a FastAPI backend counts who is in the gym. There are no user accounts: each install has a stable device UUID. The README has the architecture, API and schema.

Two people work on it. Everything goes through pull requests.

## Layout

- `backend/`: FastAPI, SQLAlchemy (async) and asyncpg. Routers are in `app/routers`, request and response types in `app/schemas.py`, the ORM model in `app/models.py`.
- `db/`: `schema.sql` is the source of truth for the database. Any schema change also adds a migration file here, named in order like `migration_<what>.sql`.
- `ios/`: SwiftUI in MVVM. `project.yml` defines the Xcode project with XcodeGen. The `.xcodeproj` and `Info.plist` are generated and git-ignored, so never commit them.
- `.github/`: CI, issue and PR templates, CODEOWNERS, Dependabot.

## Commands

```sh
# Backend, from backend/
python -m venv .venv && source .venv/bin/activate
pip install -r requirements-dev.txt
uvicorn app.main:app --reload     # needs DATABASE_URL in backend/.env (see .env.example)
ruff check .                      # lint
pytest                            # tests (need no database)

# iOS, from ios/
xcodegen generate                 # regenerate the project after changing project.yml or adding files
open ArcLive.xcodeproj
```

Before opening a PR, run `ruff check .` and `pytest` in `backend/`. CI runs both, plus an iOS build and a PR title check.

## Rules

- **Business rules live in the backend.** The iOS app only displays and sends requests. Duplicate check-ins are prevented by the partial unique index in the database, so keep that constraint when changing the schema.
- **Validate input with Pydantic schemas**, and keep new endpoints rate limited like the existing ones.
- **Never commit secrets.** `DATABASE_URL` lives in `backend/.env`, which is git-ignored. Only `.env.example` is committed, with placeholder values.
- **Tests:** add a test in `backend/tests/` for any backend change. Tests there must not need a real database.
- **Python style:** type hints on function signatures, and `ruff check .` clean.

## Git and GitHub

- **Never push to `main`.** Branch, push and open a PR. `main` requires CI to pass and one approval from the other person.
- **Branches:** `<type>/<issue>-<slug>`, for example `feature/12-weekly-stats`. Types match the commit types below.
- **Commits and PR titles** follow [Conventional Commits](https://www.conventionalcommits.org): `<type>(<scope>): <summary>`.
  - Types: `build`, `ci`, `docs`, `feat`, `fix`, `perf`, `refactor`, `test`, `chore`, `revert`.
  - Scope is optional: `backend`, `ios`, `db`.
  - The summary is imperative, starts lowercase and has no period. Example: `feat(backend): add weekly stats endpoint`.
  - PRs are squash-merged, so the PR title becomes the commit on `main`. CI checks it.
- **PR descriptions** fill in the template and say `Closes #<issue>`.
- **Issues** use the forms in `.github/ISSUE_TEMPLATE`. Work is tracked on the GitHub Project board: Backlog, Ready, In Progress, In Review, Done.
- **Add no attribution lines** such as `Co-Authored-By: Claude`.
- Claude may push branches, open PRs and comment on issues. It never merges, and approves a PR only when the developer says to.
