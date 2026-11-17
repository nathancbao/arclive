---
name: pr-review
description: Use when asked to review a pull request (by number, URL or branch), to do a code review, or to check a branch's changes before opening a PR.
---

# PR review

Three reviewers read the change at once, one per angle, and check every finding against the code. Each blocking finding then gets its own check that it's real. Nothing goes to GitHub as a comment until the developer picks what to post. At the end, the review teaches the project: what was caught or dismissed becomes a preference (step 7).

## 1. Gather

- **The change:** for a PR, run `gh pr view <n> --json number,title,body,url,author,headRefName,headRefOid,baseRefName,files` and save `gh pr diff <n>` to a scratch file outside the repo. For a branch with no PR, use `git diff main...<branch>`.
- **The code at the head commit:** `git fetch origin pull/<n>/head`, then read files with `git show <head sha>:<path>` and search with `git grep -n <pattern> <head sha>`.
- **The requirements:** the issue the PR closes (`gh issue view <issue>`): what to build and the acceptance criteria.
- **The rules:** `CLAUDE.md` and `.claude/skills/pr-review/review-preferences.md`.
- **What's been said:** `gh pr view <n> --comments` and `gh api repos/{owner}/{repo}/pulls/<n>/comments`. Don't repeat points already raised.
- **CI:** `gh pr checks <n>`.

## 2. Review: three agents at once

Dispatch three general-purpose agents in one message. Each brief has the PR's number, title, head SHA and base, the diff's path, the issue's text, the paths to `CLAUDE.md` and the review preferences, its angle's checklist, the blocking bar (step 3) and these rules:

- Read only; change nothing.
- Verify every finding against the code at the head SHA. Read at least 50 lines around it, trace the code path and confirm the problem really happens. Report nothing speculative.
- Report only problems in the PR's changes, or ones the changes cause.
- Return each finding with its file, its line in the head version, a proposed severity (blocking, non-blocking or suggestion), what's wrong, a concrete scenario where it goes wrong and the code path traced. Add one to three things done well.

The angles:

- **A. Correctness and acceptance criteria**
  - Is every acceptance criterion met?
  - Logic errors, missing edge cases, error handling. For check-in and checkout: races, double check-ins, the partial unique index still holding.
  - Do the backend and the iOS app agree on every request and response shape? A renamed or retyped field breaks installed apps.
  - Time handling: timezone-aware datetimes, and no assumptions about the server's local time.
- **B. Security and secrets**
  - This repo is public. Any committed secret is leaked: `DATABASE_URL`, Discord webhooks, API keys, tokens, `.env` contents. Check the diff, CI workflows and docs.
  - Is every request body and query parameter validated by a Pydantic schema? Is anything trusted that the client sends, such as ids or timing?
  - Are new endpoints rate limited like the existing ones? Is CORS or auth loosened?
  - SQL built from strings instead of SQLAlchemy parameters.
  - Changes to `.claude/`, `.github/workflows/` and scripts run on every developer's machine or on CI runners. What do they run, read or post? Do they loosen permissions or pin fewer versions?
- **C. Tests and quality**
  - Do new or changed backend paths have tests in `backend/tests/`, including error paths? Do the tests assert behavior and not just exist?
  - Do CI checks pass, and does the PR say how the iOS side was checked?
  - Does a schema change update `db/schema.sql` and add a migration file in `db/`?
  - Does it follow `CLAUDE.md` (business rules in the backend, MVVM on iOS, Conventional Commit PR title)?
  - Unnecessary complexity, duplicated helpers, naming. Naming and style never block.

## 3. Sort, then verify the blocking list

Merge the findings and drop duplicates. Sort them with this bar.

**Blocking:** merging as-is would

- break the build, lint, tests or CI;
- miss an acceptance criterion of the linked issue;
- do the wrong thing on a path users will hit: a logic error, a crash, a data race or a mismatch between app and backend;
- commit a secret, skip validating client input, or lose or corrupt data;
- break a rule in `CLAUDE.md`;
- leave new backend logic untested.

**Non-blocking (should fix):** a real problem that is safe to merge and fix later. **Suggestion (consider):** optional, or a matter of taste.

Then dispatch one fresh agent per blocking finding, all at once (group them if there are more than six). Each tries to prove the finding wrong: it re-reads the code, traces the path and looks for code, tests or CI that already handle it. It returns one verdict: **BLOCKING**, **NON-BLOCKING** or **NOT REAL**, with the reason. Move each finding to the list its verdict names and drop the ones that aren't real.

## 4. Report

```markdown
## PR review: <PR title> (#<n>)

### What this PR does

<Two or three sentences: the change, and the problem it solves.>

### Acceptance criteria

- ✅ / ⚠️ / ❌ <criterion>: <one line on why>

### Must fix (blocking)

- `path:line`: <the problem, and which part of the bar it meets>

### Should fix (non-blocking)

- `path:line`: <the problem>

### Consider

- `path:line`: <the suggestion>

### Looks good

- <what's well done>
```

Write "None" under an empty list, and "No linked issue" under Acceptance criteria when there isn't one. End with how many findings verification dropped or downgraded. Post nothing until the developer says what to post. They can filter or override: "post only the blocking ones", "skip the naming ones".

## 5. Post

Post only what the developer picked, as one review with inline comments, so it sends one notification:

```sh
gh api repos/{owner}/{repo}/pulls/<n>/reviews --method POST --input review.json
```

```json
{
  "commit_id": "<head sha>",
  "event": "COMMENT",
  "body": "<summary, plus findings on lines outside the diff>",
  "comments": [{ "path": "backend/app/routers/checkin.py", "line": 42, "side": "RIGHT", "body": "<finding>" }]
}
```

An inline comment's `line` has to be in the diff, or GitHub rejects the whole review, so put findings on other lines in `body`. Nothing posted credits Claude.

## 6. Decide

Approve or request changes only when the developer says to:

```sh
gh pr review <n> --approve --body "<note>"
gh pr review <n> --request-changes --body-file feedback.md
gh pr review <n> --comment --body-file feedback.md
```

GitHub doesn't let an author approve or request changes on their own PR, so use `--comment` there. Never merge.

## 7. Learn (the self-improving loop)

This step is what makes the next review better.

- **Dismissed findings:** note the findings the developer dismissed and why ("that's not a bug", "we do that on purpose"). If a pattern shows, say so: "I flagged these, but they were dismissed: X, Y."
- **Caught findings:** note the real problems worth catching every time, especially ones CI didn't catch.
- **Ask, then record.** Ask whether to record them as review preferences. Agreed ones go in `.claude/skills/pr-review/review-preferences.md` as one line each, with the reason, through a branch and a PR like any change. A preference that stops being true gets deleted.
- **Bigger lessons:** a mistake that isn't about review, such as a wrong assumption Claude keeps making, goes in the Lessons section of `CLAUDE.md` instead.
