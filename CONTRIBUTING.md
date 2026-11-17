# Contributing

## The workflow

1. **Pick or create an issue** on the [project board](https://github.com/users/nathancbao/projects). Use an issue form so it has acceptance criteria. Move the card to **In Progress** and assign yourself.
2. **Branch from `main`:** `git switch -c feature/12-weekly-stats`. The format is `<type>/<issue>-<slug>`.
3. **Commit in small steps** using [Conventional Commits](https://www.conventionalcommits.org), e.g. `feat(backend): add weekly stats endpoint`.
4. **Open a PR** early. Fill in the template and say `Closes #12`. The title must also follow Conventional Commits, because the squash merge uses it as the commit message.
5. **CI must pass**: PR title, backend lint and tests, and the iOS build.
6. **The other person reviews and approves.** Nobody merges their own PR without an approval. Reply to every comment, then re-request review.
7. **Squash and merge**, and delete the branch. Move the card to **Done** if the automation hasn't already.

`main` is protected, so you can't push to it directly, and it always builds.

## Reviewing

- Review within a working day if you can, and keep PRs small enough to make that possible.
- Check the PR against the issue's acceptance criteria, not just the code style.
- Say what is blocking and what is only a suggestion. Prefix optional comments with `nit:`.
- Approve when you would be happy to ship it.

## Running things locally

See [CLAUDE.md](CLAUDE.md#commands) for the backend and iOS commands.

## Database changes

Update `db/schema.sql` and add a migration file in `db/` in the same PR. Say in the PR when the migration has to be applied to Supabase, and apply it before the backend change deploys.

## Dependencies

Dependabot opens weekly PRs for Python packages and GitHub Actions. Review them like any other PR.
