---
name: rust-style
description: raptor's Rust conventions for layout, naming, API design, error handling, lints, tests, CLI output, and collaboration. Use whenever writing, reviewing, or refactoring Rust code, tests, or Cargo.toml lint configuration, or when starting a new Rust project.
---

# Rust style guide

This guide records raptor's choices and lessons learned; standard Rust practice is assumed. Baselines: the
[Rust Style Guide](https://doc.rust-lang.org/style-guide/) and the
[Rust API Guidelines](https://rust-lang.github.io/api-guidelines/checklist.html) apply in full. Other sources:
[idalib-rust-style](https://github.com/idalib-rs/idalib/blob/master/skills/idalib-rust-style/SKILL.md),
[xorpse/rust-style](https://github.com/xorpse/rust-style) lints, and these representative projects:
[augur](https://github.com/0xdea/augur), [rhabdomancer](https://github.com/0xdea/rhabdomancer),
[haruspex](https://github.com/0xdea/haruspex), [idalib](https://github.com/idalib-rs/idalib),
[zed-highlight](https://github.com/0xdea/zed-highlight), and [singsing-rs](https://github.com/0xdea/singsing-rs).
When unsure how something is usually done, look at how they do it (local clones may be under
`~/RustroverProjects/`).

## New projects

Start from [raptor-rust-template](https://github.com/0xdea/raptor-rust-template) with `cargo generate --git
https://github.com/0xdea/raptor-rust-template` (`cargo install cargo-generate`), then adapt it rather than writing
the scaffolding (Cargo.toml metadata and lints, CI workflows, CHANGELOG, README) by hand.

## Precedence

1. **Current idiomatic Rust comes first.** The code must stay as idiomatic as possible and current with the latest
   stable Rust release and edition. The rules below, the sources above, and existing project code capture idioms as
   they were when written; when any of them conflicts with a newer idiom (a new std API, language feature, edition
   change, or updated community consensus), prefer the current idiom and point out the outdated rule or code.
2. **When in doubt, ask the user.** If it's unclear which idiom is current, or a newer idiom conflicts with a rule
   below, a project's `CLAUDE.md`, or its lint configuration, explain the options and ask instead of guessing.
3. **Then the project, then this guide.** Otherwise, the project's `CLAUDE.md` and `Cargo.toml` lint configuration
   win over this guide. Clippy with the project's lints is the minimum bar: if code passes the Tooling checks but
   violates a rule below, still fix it.

## Tooling

- Every project uses workspace lints with all clippy groups enabled (`all`, `pedantic`, `nursery`, `cargo`,
  `restriction`) plus the curated baseline allow list in [lints.md](lints.md), as in augur. If a project is missing
  an entry from that list, point it out rather than silently adding it.
- Suppress a lint only when it genuinely can't be avoided (prefer restructuring), with
  `#[expect(clippy::lint_name, reason = "...")]` on the narrowest item, never `#[allow]`. The `reason` must hold at
  every site it covers; recheck it when that code changes. For lints clippy skips in test builds (e.g.,
  `wildcard_imports`), use `#[cfg_attr(not(test), expect(...))]`, or `--all-targets` reports an unfulfilled expect.
  A lint that fights idiomatic code everywhere gets a case-by-case allow in `Cargo.toml` (see [lints.md](lints.md)).
- Always pass `--locked` where supported. Before declaring work done, run:
  ```sh
  cargo fmt --all --check
  cargo clippy --workspace --all-targets --locked -- -D warnings
  RUSTDOCFLAGS="-D warnings" cargo doc --workspace --no-deps --locked
  cargo test --workspace --locked   # or the project's custom harness, e.g. `cargo test --test tests --locked`
  ```
  Keep `--workspace` (without it, a non-virtual workspace silently skips every crate but the root), and run any
  extra CI steps (e.g., a WASM target build).
- Optional extra checks: `cargo fmt -- --config imports_granularity=Module,group_imports=StdExternalCrate` and
  `cargo dylint --git https://github.com/xorpse/rust-style --pattern '*'` (`cargo install cargo-dylint dylint-link`).
- Dependabot cargo updates stay ungrouped.
- Clippy enforces these; write them right the first time:
  - No single-character identifiers (`min_ident_chars`): `name`, `func`, `idx`, `addr`, `err`, not `s`, `f`, `e`.
    Clippy's exemptions (`i`, `j`, `n`, `w`, `x`, `y`, `z`) and single-char lifetimes (`'a`) are fine.
  - No `unwrap`, `expect`, `panic!`, `todo!`, `unimplemented!`, `unreachable!`, or `dbg!` outside tests.
  - `to_owned()`/`String::from` on `&str`, never `to_string()`; inline format arguments (`format!("{name}")`);
    `Vec::new()` over `vec![]` for empty vectors.
- Clippy quirks with this lint set:
  - `renamed_function_params`: trait impls keep the trait's parameter names (`f` in `fmt::Display::fmt`), which
    `min_ident_chars` doesn't flag.
  - `single_range_in_vec_init`: in tests, build ranges from `(start, end)` pairs through a helper, not
    `vec![start..end]`.
  - `ref_patterns`: rely on default binding modes and `*`, not `ref`.
  - `wildcard_enum_match_arm` also flags catch-all binding arms (`entry => ...`): use an `if let` chain or explicit
    arms.
  - `double_must_use`: no `#[must_use]` on functions returning `impl Iterator` or other must-use types.
  - `too_many_lines`: split a custom test harness's `main()` into `test_*` scenarios and `check_*` assertions.
  - `doc_markdown` flags mixed-case words such as "AArch64": rephrase ("ARM64") rather than backtick non-code.

## Defaults to apply

Close calls, decided this way:

- No type annotations on `let` bindings: use turbofish or suffixes (`.collect::<Vec<_>>()`, `0_usize`).
- `let ... else` for early returns; `if let ... && ...` chains instead of nested `if let`.
- Combinators that state intent (`is_some_and`, `map_or_else`, `unwrap_or_default`, `filter_map` + `bool::then`,
  `Option::map_or(Ok(()), ...)` for optional fallible work); the `Entry` API, not `contains_key` + `insert`.
- Borrowed parameter types (`&Path`, `&str`, `&[u8]`); public functions taking a path use `impl AsRef<Path>`,
  converted once at the top by shadowing: `let filepath = filepath.as_ref();`.
- Derive common traits eagerly, in alphabetical order (small enums: `Clone, Copy, Debug, Eq, PartialEq`, plus
  `Ord`/`Hash` when useful, passed by value).
- Constructors are chosen by meaning, not by number of arguments: `Default` (derived when possible) for a natural,
  cheap empty value, instead of a `new()` that only builds defaults; `From`/`TryFrom` only when the type is a
  conversion of one value (newtypes, validating wrappers), never just because there is one argument
  (`FunctionDumper::new(idb)`, like `BufReader::new`); otherwise `new`, whatever its arity, with named alternatives
  (`with_*`, `from_*`, `open`).
- `#[must_use]` on pure functions whose result matters, private ones included; `const fn` wherever possible;
  `#[non_exhaustive]` on public enums and `pub`-field structs that may grow.
- `Result<Option<T>, E>` for an expected absence (like `Child::try_wait`); `anyhow::ensure!` for preconditions.

## Formatting by hand

`rustfmt` doesn't enforce these:

- Line width: code lines are at most 100 characters. Comment-only lines are at most 80 characters excluding
  indentation (sigils included) and never more than 100 in total (a top-level `///` line has 80, one in a method
  indented by 4 has 84). Wrap comments by hand, filling lines close to the limit. String literals can't be split
  either: keep messages short enough to fit, without `\` continuations. Markdown files keep their own wrapping.
- Names clashing with a reserved word use `r#crate` or `crate_`, never a misspelling (`krate`).
- Not adopted for now: the guide's [`Cargo.toml` conventions](https://doc.rust-lang.org/style-guide/cargo.html).
  Keep each project's existing `Cargo.toml` layout (including the curated order of the clippy allow list), and
  don't reorder its keys.

## Imports

- Three groups separated by a blank line: 1) `std`/`core`/`alloc`, 2) external crates, 3) `crate::`/`self::`/`super::`.
- Group sibling leaf items only; never nest multi-segment paths inside braces or repeat a prefix:
  ```rust
  use std::collections::{BTreeMap, HashSet};
  use std::path::{Path, PathBuf};
  use std::{env, mem};

  use anyhow::Context as _;
  use idalib::idb::IDB;
  use idalib::{Address, IDAError};
  ```
  Not `use std::{collections::HashMap, path::PathBuf};`, and not two separate `use std::collections::...` lines.
- Import traits used only for their methods as `_`. No fully qualified type paths in signatures
  (`std::path::PathBuf`): import the type, or keep one disambiguating module (`io::Result`, `fmt::Result`). For the
  same reason, derive `thiserror::Error` by path (`#[derive(Debug, thiserror::Error)]`) instead of importing it, so
  it isn't mistaken for `std::error::Error`.

## Module layout

- A module with (or that may get) submodules is a directory with `mod.rs`; a leaf module is `module_name.rs`. Don't
  use the `module_name.rs` + `module_name/` layout.
- Items in a file follow this order, as in the template's `src/lib.rs` (it replaces clippy's
  `arbitrary_source_item_ordering`, which is allowed):
  1. Inner attributes and crate or module docs (`#![doc = ...]`, `//!`).
  2. Imports.
  3. Module declarations, then public re-exports (`pub use`) next to the modules they expose.
  4. `macro_rules!` macros (their scope is textual).
  5. `const`s, then `static`s.
  6. Type aliases.
  7. Error types.
  8. Traits, before the types that implement them.
  9. Structs and enums, each followed by its impls: the inherent `impl`, then `impl` blocks with trait bounds, then
     trait impls (std, then external crates', then the crate's own). Inside an impl: associated constants,
     constructors (`new`, `with_*`, `from_*`), other associated functions, then methods (getters and setters
     first).
  10. Free functions, public ones (e.g., `run`) first.
  11. `#[cfg(test)] mod tests` last: `use super::*;`, test constants, helpers, then tests.
- No blank lines between consecutive struct fields or enum variants. Alphabetize variants only when their order
  means nothing; when it carries meaning (priority, severity, state machine, FFI), keep it despite xorpse's
  `sorted_enum_variants`, derive `Ord` from it, and pin it with a test.

## Naming

- Error types have descriptive names (`HaruspexError`), never a bare `pub` `Error`.
- Name variables for what they hold, in the domain's terms (`func_name`, `first_xref`, `dirpath`, `marked`), and
  never after a crate they use (`fn parse(text: &str)`, not `toml: &str` next to `toml::from_str`).
- A wrapper around a collection exposes `iter()` yielding flat tuples of the stored fields
  (`(priority, id, func, name)`) instead of exposing the inner map.

## Types and API design

- No trivial getters/setters: a `pub` field is fine when a setter would add no checks. Enforce invariants with
  types instead (newtypes, enums instead of flags or magic values, `NonZero*`, validating constructors), and keep a
  field private only when it guards an invariant types can't express or its representation may change.
  `pub(crate)` is fine internally.
- Encode an invariant in a type only when the excluded value is genuinely invalid (port zero), not merely unusual (a
  zero timeout can be meaningful; a CLI may still narrow the range), and make it hold on every path: a check only a
  parser performs, while a `pub` field accepts anything, is a hole. Write validated literals as checked consts
  (`const HTTPS: NonZeroU16 = NonZeroU16::new(443).unwrap();`, allowed in consts), also in doc examples.
- Keep the public API minimal: making an item public later is non-breaking, making it private is breaking. Don't
  export a constant just because its value is an external text contract (e.g., a tag written into files): document
  the format in the README. A library API is designed as such (e.g., returning results without printing them), not
  obtained by exporting CLI-oriented types.
- Don't store state in a field just to return it once. A method that updates state as it works (e.g., a set of
  processed items) takes `&mut self`, not a `RefCell`: `.map(|item| self.step(item)).sum()` still works.
- One structure keyed by a composite or enum key over parallel structures dispatched by `match` (one
  `BTreeMap<(Priority, FunctionId), _>`, not three maps).
- `#[repr(u8)]`/explicit discriminants only when the values are used or are an external contract (e.g., SDK
  constants). Otherwise map variants to codes with an explicit `match`, never a cast, so codes don't depend on
  declaration order.
- Keep data separate from context: data structs hold results; a context struct holds the borrowed handle (`&IDB`)
  plus caches derived from it, so the handle isn't threaded through every call.
- Derive strings from their constants in one `format!` (`format!("{PREFIX}{level}] {name}")`), not hardcoded
  copies.
- Validate deserialized input once, at the boundary: deserialize a raw struct shaped like the file and convert it
  with `#[serde(try_from = "RawConfig")]`. `From`/`TryFrom` impls are pure (no printing). A private `TryFrom` used
  only by serde can use `type Error = String`, since serde keeps only its `Display`.

## Error handling

- Binaries and top-level `run` functions use `anyhow` with `.context(...)`/`.with_context(|| format!(...))`.
  Errors in a library's public API are `thiserror` enums (with constructor methods for variants with fields): each
  variant describes what failed, carries context in named fields, and chains the underlying error with an explicit
  `#[source]` rather than repeating its message. A variant that only wraps an error, with no other context, is a
  tuple variant; a variant with context uses named fields, each documented, with the error in a `source` field
  (adapted from singsing-rs):
  ```rust
  #[derive(Debug, thiserror::Error)]
  #[non_exhaustive]
  pub enum ScanError {
      /// Creating the raw transport socket failed.
      #[error("failed to create raw socket (run as root or grant CAP_NET_RAW)")]
      SocketCreation(#[source] io::Error),
      /// The services file could not be read.
      #[error("failed to read {}", path.display())]
      ServicesFileRead {
          /// The services file path.
          path: PathBuf,
          /// The underlying I/O error.
          #[source]
          source: io::Error,
      },
  }
  ```
  `#[error(transparent)]` only when the variant adds nothing; `#[from]` only for a single, unambiguous conversion.
- Lower layers return concrete error types (`Result<_, IDAError>`, `Result<_, TomlError>`); only the top level
  converts to `anyhow` and adds context, so combinators like `.sum()` over `Result` need no conversions. The
  exception is a private helper combining several sources whose callers already use `anyhow`: it returns
  `anyhow::Result` with one `.with_context(...)` per source, not a private enum that nothing matches on. The
  underlying errors stay in the chain for tests to downcast. Once callers need to tell failures apart, make them
  `thiserror` variants.
- Error messages are lowercase unless they start with a proper noun or acronym (`"I/O error: ..."`), in
  `thiserror`, `anyhow` contexts, and `ensure!`/`bail!` alike. Printed lines keep their prefix
  (`[!] Error: {err:#}`).
- Never silently ignore errors: when one is deliberately ignored, say so in a comment and match the ignored
  variants explicitly rather than with `_`.
- Use `inspect_err` for cleanup on failure, and report (don't propagate) cleanup failures. Cleanup never deletes
  pre-existing data: create the output directory before, and outside, the path the cleanup covers.

## Expressions and idioms

- For a type alias, start from its default (`BookmarkIndex::default()`) rather than a suffix that hardcodes its
  definition (`0_u32`).
- Walk linked chains with `iter::successors(first, Next::next)`; use an explicit `Vec` work stack instead of
  recursion for unbounded depth. For graph-like traversals, keep a visited set seeded with the start
  (`HashSet::from([start])`) and queue a key only `if visited.insert(key)`: that bounds the work, ends cycles, and
  keeps a node from being walked (and reported) twice.
- `*map.entry(key).or_insert(value) != value` detects a conflicting duplicate while keeping the first value.
- Arithmetic: prefer none written out (total fallible counts with `.map(fallible).sum()` into a `Result`), then
  `saturating_*` for counters, then `checked_*` when overflow is an error. `sum()`/`product()` still add: clippy
  doesn't lint them, and they wrap in release builds, so use them only when the total is provably bounded, and state
  the bound in the doc comment. Use `.sum()` only when each step is a simple expression;
  when a step prints or branches (e.g., augur's `traverse_xrefs`), a `for` loop with a `saturating_add` counter reads
  more clearly, so keep it. Provably safe operations stay bare under
  `#[expect(clippy::arithmetic_side_effects)]` with a `reason`, rather than `checked_*` + `?`, which would turn a
  future bug into a silent `None`.
- Don't add fallbacks for cases an earlier check rules out; state the guarantee in a comment instead.
- Shadow for a clear transformation of the same value (`let port = port.trim().parse::<u16>()?;`,
  `let mut buf = buf;`); never reuse a name for an unrelated value (`shadow_unrelated` stays enabled).
- No sentinel values to force a code path (passing `BADADDR` to get `None`); express the `Option` flow directly.
- At OS, FFI, and dependency boundaries, read what the code actually does rather than assuming (e.g., a zero
  `SO_RCVTIMEO` blocks forever; a function may return `Ok(())` without writing its output).

## Performance

- Minimize FFI calls and allocations in hot paths: don't fetch the same FFI value twice, cache derived data (e.g.,
  segment ranges) once, and don't allocate a `String` just to compare a prefix.
- Under a lock, only snapshot what you need and release it before scanning or I/O; keep a check followed by a
  mutation under a single lock.
- Measure before claiming a speedup or no regression, with a differential test against the old version; report
  micro-optimizations that fixed costs dominate as code-quality improvements.

## idalib and FFI

For projects built on idalib (augur, rhabdomancer, haruspex, idalib itself), also read [idalib.md](idalib.md).

## CLI and output conventions

- Every `main.rs` has a banner (`{PROGRAM} {VERSION} - ...` and copyright with `{AUTHORS}`) from
  `env!("CARGO_BIN_NAME")`/`CARGO_PKG_VERSION`/`CARGO_PKG_AUTHORS` constants, and `main() -> ExitCode`.
- A CLI with fixed positional arguments only follows augur's template: `env::args_os()`, a `(Some(arg), None)`
  match, `-h`/`--help`, and `usage(prog) -> ExitCode` returning `ExitCode::FAILURE`. Anything more complex uses
  `clap` derive (see singsing-rs's `zucchini`), with validation and defaults typed in clap (`value_parser!`,
  `FromStr` newtypes, `default_value_t = CHECKED_CONST`, not `default_value = "15"`).
- Results go to stdout (`println!`); everything else (banner, progress, summary, timing, errors) to stderr.
  Prefixes: `[*]` progress, `[+]` success/summary, `[-]` information, `[!]` warning/error; errors as
  `eprintln!("[!] Error: {err:#}")`; elapsed time as `{:.1} seconds`. No emojis or decorations unless requested
  (as in [jiggy](https://github.com/0xdea/jiggy)).
- Before refactoring code that produces output, decide whether its order is a contract, and document it.
- Embed default configuration files with `include_str!`, never via a path from `env!("CARGO_MANIFEST_DIR")`,
  which breaks once the source tree moves (e.g., after `cargo install`). An environment variable selects a custom
  file, with no fallback to a file on disk; docs link to the shipped file for users to copy; keep it out of
  `Cargo.toml`'s `exclude`.
- An empty environment variable counts as unset: `env::var_os(NAME).filter(|value| !value.is_empty())`.
- Serde structs mirroring a user-written configuration file carry `#[serde(deny_unknown_fields)]`.

## Documentation and comments

- Every item has a doc comment (`missing_docs` is on), private ones and test helpers included; only `fn main()`
  and `#[test]` functions are exempt. Crate docs include the README:
  `#![cfg_attr(doc, doc = include_str!("../README.md"))]`.
- Doc comments name parameters in backticks and have `# Errors` (and `# Panics`/`# Safety`) sections.
- Comments are full sentences ending with a period, and explain _why_, not _what_. A justifying comment must hold
  on every path that reaches the code.
- `unsafe` blocks need a `// Safety:` comment (e.g., `env::set_var` in a single-threaded test binary).
- `CHANGELOG.md` follows Keep a Changelog: entries under `[Unreleased]` in `Added`/`Changed`/`Fixed`/`Removed`/
  `Security`, one short imperative sentence each, code names in backticks. Prefix each breaking change to the public
  API with `**Breaking:**` (e.g., under `Changed` or `Removed`, as in haruspex); text changes such as lowercased
  error messages aren't breaking, and past releases aren't marked retroactively.
- `Cargo.toml` has full metadata (authors, description, license, homepage, repository, keywords, categories); set
  `documentation` only when docs.rs isn't suitable.

## Tests

- Unit tests live in `#[cfg(test)] mod tests` with `use super::*;`, return `Result` where useful, and carry
  `#[expect(clippy::panic_in_result_fn, reason = "panics are allowed in test code")]` at module level.
- Test names describe the behavior (`copy_to_creates_missing_output_directory`); every assertion has a message.
- Prove a new test can fail: temporarily break what it guards, check that it fails, restore. If an earlier check
  catches the break first, skip that one too, so the new check is shown to fail on its own.
- Negative tests fail only on the targeted defect (an invalid-TOML input is otherwise a valid configuration, or a
  missing-field error keeps it green); a test checking an order asserts that its data has more than one group.
- Verify behavior-preserving refactors against `HEAD`: build it from `git archive HEAD` in a temp directory (sharing
  the target directory), run both binaries on fresh copies of the same input, `cmp` their output, and confirm the
  binaries differ. For mechanical changes, prove the scope (e.g., code with comments stripped identical to `HEAD`,
  comment text identical modulo whitespace). For intentional reorderings, compare per group, and say so if the test
  data can't exercise the reordering.
- Pin what a binary prints by running it as a subprocess (`process::Command::new(env!("CARGO_BIN_EXE_<name>"))`).
- Tests of an external contract (file formats, CLI output) use literals, not production constants.
- Check error kinds, not OS-dependent messages: downcast through the chain to `io::ErrorKind`.
- Extract time-dependent decisions into pure functions taking `now: Instant` (singsing-rs's `receive_wait`).
- File-system tests use temp directories under `env::temp_dir()`, scoped by label and process ID. A custom harness
  removes, at the top of `main()`, every environment variable the code under test reads.

## Collaboration

- Explain the plan for each change and wait for approval before implementing it.
- One concern per commit: behavior-preserving refactors, mechanical reformatting, and new behavior go in separate
  commits; start the next change only after the user has committed the previous one.
- Never `git commit` (or push); the user reviews and commits.
- Weigh a fix's complexity against how often its inputs occur: prefer the simplest fix covering realistic inputs,
  document and test the remaining limitation, and keep a fuller alternative on a branch if it may be wanted.
- For output-only improvements, prefer redundant but complete output over heuristics that could drop results or
  code that only buys cosmetics; offer "leave it and document it".
- Delete generated files by exact names or extensions, never with a glob next to tracked files; check
  `git status` afterwards.
- After a change: run the checks above, update `CLAUDE.md` and `CHANGELOG.md` when relevant, and summarize what
  changed and how it was verified.
- Before adding a rule to this skill, check whether an existing bullet already covers it or can absorb it, and
  whether Claude would follow it anyway without being told (then leave it out).
