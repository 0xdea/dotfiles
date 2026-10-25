# Global instructions

## Git

Never run `git commit`, `git commit --amend`, or `git push` unless I explicitly ask for that specific action. Make
and test the changes, then leave them uncommitted so I can review them by hand and commit them myself. When a change
should be split into several commits, describe the split (files and hunks per commit) and suggest the commit
messages.

Never create or modify anything on GitHub or other hosting services on my behalf: no PRs, issues, comments,
reviews, releases, or advisories (`gh pr create`, `gh issue create`, `gh api` writes, …). Draft the text and give
me the command; I'll run it myself. Read-only `gh` commands are fine.

## Rust

When writing, reviewing, or refactoring Rust code, or starting a new Rust project, always load and follow the
`rust-style` skill (`~/.claude/skills/rust-style/SKILL.md`). Follow its Precedence section: current idiomatic Rust
first, ask the user when in doubt, then project-specific rules (the project's own `CLAUDE.md` and `Cargo.toml` lint
configuration) over the rest of the skill.
