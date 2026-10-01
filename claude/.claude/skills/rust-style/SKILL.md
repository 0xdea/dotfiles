---
name: rust-style
description: raptor's Rust style guide. Use whenever writing, reviewing, or refactoring Rust code.
---

# Rust style guide

Primary source: the official [Rust Style Guide](https://doc.rust-lang.org/style-guide/), the baseline for
formatting and style (`rustfmt` enforces most of it; see the Rust Style Guide section below for what it doesn't).

Other sources: [idalib-rust-style](https://github.com/idalib-rs/idalib/blob/master/skills/idalib-rust-style/SKILL.md),
[xorpse/rust-style](https://github.com/xorpse/rust-style) lints,
[Rust API Guidelines](https://rust-lang.github.io/api-guidelines/checklist.html), and conventions established in
these representative projects:
[augur](https://github.com/0xdea/augur), [rhabdomancer](https://github.com/0xdea/rhabdomancer),
[haruspex](https://github.com/0xdea/haruspex), [idalib](https://github.com/idalib-rs/idalib),
[zed-highlight](https://github.com/0xdea/zed-highlight), and [singsing-rs](https://github.com/0xdea/singsing-rs).
When unsure how something is usually done, look at how these projects do it (local clones may exist under
`~/RustroverProjects/`).

## New projects

Start new projects from [raptor-rust-template](https://github.com/0xdea/raptor-rust-template) with
[cargo-generate](https://crates.io/crates/cargo-generate), then adapt it rather than building the scaffolding
(Cargo.toml metadata and lints, CI workflows, CHANGELOG, README) by hand:

```sh
cargo install cargo-generate
cargo generate --git https://github.com/0xdea/raptor-rust-template
```

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
  `restriction`) plus the curated baseline allow list in [lints.md](lints.md), in line with augur's
  `[workspace.lints]` block. If a project is missing an entry from that list, point it out rather than silently
  adding it.
- Suppress a lint locally with `#[expect(clippy::lint_name, reason = "...")]`, never `#[allow]`, and only when it
  genuinely cannot be avoided. Prefer restructuring code so the `#[expect]` is not needed (for arithmetic, see
  Expressions and idioms). Put the `#[expect]` on the narrowest item that needs it (e.g., the single `use` item),
  not on the whole crate. Clippy skips some lints in test builds (e.g., `wildcard_imports`), which leaves a plain
  `#[expect]` unfulfilled under `--all-targets`; use `#[cfg_attr(not(test), expect(...))]` for those. The `reason`
  must say why the lint is harmless at every site it covers; recheck it whenever the code under it changes. A lint
  that fights idiomatic code everywhere gets a case-by-case allow in `Cargo.toml` instead (see [lints.md](lints.md)).
- Always pass `--locked` to cargo commands that support it. Before declaring work done, run:
  ```sh
  cargo fmt --all --check
  cargo clippy --workspace --all-targets --locked -- -D warnings
  RUSTDOCFLAGS="-D warnings" cargo doc --workspace --no-deps --locked
  cargo test --workspace --locked   # or the project's custom harness, e.g. `cargo test --test tests --locked`
  ```
  Keep `--workspace` (in a non-virtual workspace, omitting it silently skips every crate but the root), and also
  run any extra CI steps (e.g., a WASM target build).
- Optional extra checks: `cargo fmt -- --config imports_granularity=Module,group_imports=StdExternalCrate` and
  `cargo dylint --git https://github.com/xorpse/rust-style --pattern '*'` (install with
  `cargo install cargo-dylint dylint-link`).
- Dependabot cargo updates stay ungrouped.
- Clippy quirks that come up often with this lint set:
  - `renamed_function_params`: trait impls keep the trait's own parameter names (e.g., `f` in `fmt::Display::fmt`);
    `min_ident_chars` doesn't flag them.
  - `single_range_in_vec_init`: in tests, build a `Vec` of ranges from `(start, end)` pairs through a small helper
    rather than writing `vec![start..end]`.
  - `ref_patterns`: rely on default binding modes and dereference with `*` instead of `ref` bindings.
  - `wildcard_enum_match_arm` also flags catch-all _binding_ arms (`entry => ...`), not just `_`: use an `if let`
    chain (or explicit arms) instead.
  - `double_must_use`: don't add `#[must_use]` to functions returning `impl Iterator` or other must-use types.
  - `too_many_lines`: split a custom test harness's `main()` into `test_*` scenario functions and `check_*`
    assertion functions.
  - `doc_markdown`: flags mixed-case words in doc comments (e.g., "AArch64") as identifiers missing backticks;
    rephrase the word (e.g., "ARM64") rather than backticking something that isn't code.

## Rust Style Guide

The [Rust Style Guide](https://doc.rust-lang.org/style-guide/) applies in full. `rustfmt` enforces most of it
(indentation, block indent, trailing commas, blank lines, trailing whitespace, attribute layout); follow these
parts by hand, since it doesn't:

- Line width: code lines are at most 100 characters. Comment-only lines are at most 80 characters excluding
  indentation (sigils included) and never more than 100 in total, i.e., a top-level `///` line has 80 characters
  and a doc comment on a method indented by 4 has 84. `rustfmt` doesn't reflow comments on stable, so wrap them
  by hand, filling lines close to the limit. It can't split string literals either: keep assertion messages,
  error messages, and other literals short enough to fit, rather than exceeding the limit or splitting them with
  `\` continuations. Markdown files (`README.md`, `CHANGELOG.md`, `CLAUDE.md`) keep their own wrapping.
- Comments: use line comments (`//`, `///`), not block comments (`/* */`, `/** */`); use inner doc comments
  (`//!`) only for crate or module docs. Put comments on their own line; a comment after code is preceded by a
  single space.
- Doc comments go before attributes (`/// ...`, then `#[must_use]`), and each attribute goes on its own line.
- A single `#[derive(...)]` attribute per item; when merging several, keep their order.
- Prefer Rust's expression-oriented style: `let x = if y { 1 } else { 0 };`, not a `let x;` assigned in each
  branch.
- Names that clash with a reserved word use a raw identifier (`r#crate`) or a trailing underscore (`crate_`),
  never a misspelling (`krate`).
- Avoid `#[path]` module attributes.
- Not adopted for now: the guide's
  [`Cargo.toml` conventions](https://doc.rust-lang.org/style-guide/cargo.html) (`[package]` key order with
  `description` last, version-sorted keys in other sections). Keep each project's existing `Cargo.toml` layout,
  including the curated order of the baseline clippy allow list, and don't reorder `Cargo.toml` keys.

## Imports

- Three groups separated by a blank line: 1) `std`/`core`/`alloc`, 2) external crates, 3) `crate::`/`self::`/`super::`.
- Group sibling leaf items only; never nest multi-segment paths inside braces, and never repeat the same prefix:
  ```rust
  use std::collections::{BTreeMap, HashSet};
  use std::path::{Path, PathBuf};
  use std::{env, mem};

  use anyhow::Context as _;
  use idalib::idb::IDB;
  use idalib::{Address, IDAError};
  ```
  Not `use std::{collections::HashMap, path::PathBuf};`, and not two separate `use std::collections::...` lines.
- Import traits used only for their methods as `_` (`use anyhow::Context as _;`).
- Don't write fully qualified type paths in signatures (`std::path::PathBuf`); import the type, or shorten to a
  single disambiguating module (`io::Result`, `fmt::Result`).
- No useless imports such as `use log;`.

## Module layout

- A module that has (or may have) submodules is a directory with `mod.rs`; a leaf module is `module_name.rs`.
  Don't use the newer `module_name.rs` + `module_name/` layout for modules with submodules.
- Items in a file follow this order, as in the template's `src/lib.rs` (clippy's `arbitrary_source_item_ordering`
  is allowed because this order replaces its fixed one):
  1. Inner attributes and crate or module docs (`#![doc = ...]`, `//!`).
  2. Imports (see Imports).
  3. Module declarations (`mod`, `pub mod`), then public re-exports (`pub use`), next to the modules they expose.
  4. `macro_rules!` macros: their scope is textual, so they come before any code that uses them.
  5. `const`s, then `static`s.
  6. Type aliases.
  7. Error types.
  8. Traits, before the types that implement them.
  9. Structs and enums, each followed by its impls: the inherent `impl`, then `impl` blocks with trait bounds, then
     trait impls (std traits, then external crates', then the crate's own). Inside an impl: associated constants,
     constructors (`new`, `with_*`, `from_*`), other associated functions, then methods (getters and setters
     first).
  10. Free functions, public ones (e.g., `run`) first.
  11. `#[cfg(test)] mod tests` last (clippy's `items_after_test_module` enforces it): `use super::*;`, test
      constants, helpers, then tests.

## Naming

- No single-character identifiers (`clippy::min_ident_chars`): `name`, `func`, `idx`, `addr`, `segm`, `err`, not
  `s`, `f`, `a`, `e`. Clippy's default exemptions (`i`, `j`, `n`, `w`, `x`, `y`, `z`) are fine, and so are
  single-char lifetimes (`'a`).
- Casing per RFC 430 (C-CASE). Use consistent word order across the codebase (C-WORD-ORDER).
- Getters have no `get_` prefix: `timeout()`, `set_timeout()`, builder-style `with_timeout()` delegating to the
  setter (C-GETTER). Conversions follow `as_` (cheap borrow), `to_` (expensive), `into_` (consuming) (C-CONV).
- Iterator-producing methods are `iter`/`iter_mut`/`into_iter` (C-ITER). Wrapper types around a collection
  expose `iter()` yielding flat tuples of every stored field (e.g., `(priority, id, func, name)`) instead of
  letting other types reach into the inner map.
- Error types have descriptive names (`HaruspexError`), never a bare `pub` `Error`.
- Name variables for what they hold, matching the domain: `func_name`, `from`, `first_xref`, `dirpath`,
  `string_uses_count`, `marked`.

## Types and API design

- Accept borrowed types (C-GENERIC): `impl AsRef<Path>`/`&Path` over `&PathBuf`, `&str`/`impl AsRef<str>` over
  `&String`, `&[u8]` over `&Vec<u8>`. Public functions taking a path use `impl AsRef<Path>` and convert it once at
  the top by shadowing the parameter: `let filepath = filepath.as_ref();`.
- `pub` struct fields are acceptable when a setter wouldn't add any checking logic: don't write trivial
  getters/setters that just read or assign a field. Enforce invariants with the type system instead of run-time
  checks in setters: newtypes, enums instead of flags or magic values, `NonZero*`, and constructors that validate
  once, so that an invalid value can't be built in the first place. Keep a field private behind an accessor only when
  it guards an invariant the type system can't express, or when the representation may change (C-STRUCT-PRIVATE).
  `pub(crate)` is acceptable internally.
- Encode an invariant in a type only when the excluded value is genuinely invalid (zero bandwidth, port zero), not
  merely unusual (a zero timeout can be meaningful); a CLI may still narrow the accepted range. Once encoded, it
  must hold on every path: a check that only a parser performs, while a `pub` field accepts anything, is a hole.
  Write validated literals as compile-time-checked consts (`const HTTPS: NonZeroU16 = NonZeroU16::new(443).unwrap();`,
  allowed by clippy's default `allow-unwrap-in-consts`), including in doc examples, rather than a runtime `unwrap`.
- Types eagerly derive common traits (C-COMMON-TRAITS): small enums are `Debug, Copy, Clone, PartialEq, Eq` (and
  `Ord`/`Hash` when useful) and are passed by value. All public types implement `Debug` (C-DEBUG). Keep derives in
  alphabetical order. Derive `Default` (and drop a hand-written `new()` that only builds defaults) when every field
  has a suitable default; clippy's `new_without_default` only flags public types.
- Use `#[non_exhaustive]` on public enums that may grow, and on public structs with `pub` fields that may gain more
  fields (then provide a constructor, since other crates can't use a struct literal). Use `#[must_use]` on pure
  functions whose result matters, private ones included (clippy only flags public ones), and `const fn` wherever
  possible.
- Functions with a clear receiver are methods (C-METHOD). Constructors are static inherent methods (C-CTOR).
- Return values instead of taking out-parameters (C-NO-OUT): a traversal returns `Result<usize, _>` rather than
  incrementing a `&mut usize`. Don't store state in a struct field just to return it once.
- When a method updates state while it works (e.g., a set of already processed items), take `&mut self`
  rather than reaching for interior mutability (`RefCell`): iterator adapters such as
  `.map(|item| self.step(item)).sum()` can still borrow `self` mutably, since their closures are `FnMut`.
- Use types, not `bool`/`Option` flags, to convey meaning in arguments (C-CUSTOM-TYPE); newtypes for static
  distinctions (C-NEWTYPE).
- Prefer one data structure keyed by a composite or enum key over parallel structures dispatched by `match`
  (e.g., one `BTreeMap<(Priority, FunctionId), _>` instead of three maps).
- Type aliases with a doc comment for recurring complex types (`type DumpCache = HashMap<Address, Option<...>>;`).
- Only use `#[repr(u8)]`/explicit discriminants when the numeric values are actually used or are an external
  contract (e.g., they match SDK constants, documented in a comment). Otherwise, map variants to numeric codes
  (e.g., a tag digit) with an explicit `match`, never a cast, so the codes don't depend on declaration order.
- Keep data separate from context: data structs hold results (e.g., the functions found), while a context struct
  holds the borrowed handle they're used with (e.g., `&IDB`) plus caches derived from it (e.g., `.plt` ranges), so
  methods don't thread the handle through every call and derived state doesn't leak into unrelated data.
- Derive strings from their constants in a single `format!` (e.g., `format!("{PREFIX}{}] {name}", level)`) instead
  of hardcoding copies that must be kept in sync.
- Validate deserialized input once, at the boundary: deserialize a raw struct shaped like the file and convert it
  with `#[serde(try_from = "RawConfig")]`, so an invalid value can't be built. `From`/`TryFrom` impls must be pure
  (no printing or other side effects). A private `TryFrom` used only by serde can use `type Error = String`, since
  serde keeps only the error's `Display`.

## Structs and enums layout

- No blank lines between consecutive fields or variants; doc comments between them are fine.
- Enum variants in alphabetical order only when their order means nothing. When the order carries meaning
  (priority, severity, log level, state machine, FFI), keep it and never alphabetize it just to satisfy xorpse's
  `sorted_enum_variants` lint (e.g., `Priority { High, Medium, Low }` stays as is); derive `Ord` from it and pin
  the order with a unit test.

## Error handling

- Never `unwrap`, `expect`, `panic!`, `todo!`, `unimplemented!`, `unreachable!`, or `dbg!` outside tests.
- Propagate with `?`. Binaries and top-level `run` functions use `anyhow` with `.context(...)`/
  `.with_context(|| format!(...))`; libraries define `thiserror` enums and constructor methods for variants with
  fields. Each variant should describe what failed in its own message, carry the relevant context in named fields,
  and chain the underlying error as `#[source]` rather than repeating its message (see singsing-rs):
  ```rust
  #[error("failed to read {}", path.display())]
  ServicesFileRead {
      path: PathBuf,
      #[source]
      source: io::Error,
  },
  ```
  Use `#[error(transparent)]` only when the variant adds nothing, e.g. it wraps a same-crate error that already
  describes the failure (singsing-rs's `ScanError::Incomplete`). Use `#[from]` only for a single, unambiguous
  conversion.
- Lower layers return concrete error types (e.g., `Result<_, IDAError>`), even when a top-level caller uses
  `anyhow`: only the top level converts to `anyhow` and adds context, so the concrete type isn't erased early and
  combinators such as `.sum()` over `Result` work without conversions.
- Error messages are always lowercase unless they start with a proper noun or acronym
  (`"no type definitions generated"`, `"I/O error: ..."`). This applies everywhere: `thiserror` messages, `anyhow`
  context strings (`.context("failed to load known bad API function names")`), and `anyhow::ensure!`/`bail!`
  messages. User-facing `eprintln!` output lines are not error messages and keep their
  prefix style (`[!] Error: {err:#}`).
- Never silently ignore errors. When an error is deliberately ignored (best-effort work), say so in a comment and
  match the ignored variants explicitly rather than using `_` for everything.
- Use `inspect_err` for cleanup-on-failure, and report (don't propagate) a failure during cleanup. Cleanup must
  never delete pre-existing data: create the output directory before, and outside, the path the cleanup covers.
- Use `Result<Option<T>, E>` to separate fatal errors from an expected absence (like `Child::try_wait`), rather
  than an error that callers must classify.
- Use `anyhow::ensure!` for precondition checks.

## Expressions and idioms

- Rely on inference; never annotate `let` bindings. Use turbofish or literal suffixes instead:
  `Vec::<u8>::new()`, `.collect::<Vec<_>>()`, `0_usize`, not `let count: usize = 0;`. When a method call needs a
  type alias's concrete type, start from its default (`let mut marked = BookmarkIndex::default();` before
  `saturating_add`) rather than a suffix like `0_u32`, which hardcodes the alias's definition.
- Inline format arguments: `format!("{name}")`, `println!("{from:#X} in {caller}")`, `{err:#}` for anyhow chains.
- `to_owned()`/`String::from` on `&str`, never `to_string()`. `clone_into` to reuse an existing allocation.
- `Vec::new()` over `vec![]` for empty vectors (`vec![first]` for a non-empty literal is fine).
- Prefer combinators that state intent: `is_some_and`, `map_or`, `map_or_else`, `unwrap_or_default`,
  `and_then`, `filter_map` + `bool::then`, `Option::map_or(Ok(()), ...)` for optional fallible work.
- `let ... else` for early returns; `if let ... && ...` chains (edition 2024) instead of nested `if let`.
- Walk linked chains with `iter::successors(first, Next::next)` (e.g., XREF chains with `XRef::next_to`) instead of
  manual `while let` loops. Use an explicit `Vec` work stack instead of recursion for unbounded depth.
- For graph-like traversals, use a worklist of keys (e.g., addresses) plus a visited set seeded with the start
  (`HashSet::from([start])`), and queue a key only `if visited.insert(key)`: that single guard bounds the work,
  makes cycles terminate, and keeps the same node from being walked (and reported) twice.
- Use the `Entry` API instead of `contains_key` + `insert`, e.g., for first-wins duplicate detection in one
  expression: `*map.entry(key).or_insert(value) != value` keeps the first value and tells whether a later one
  differs.
- Arithmetic: prefer code that needs none (e.g., total fallible counts with `.map(fallible).sum()` into a
  `Result`, which stops at the first error), then `saturating_*` for counters, then `checked_*` when overflow is an
  error. When an operation provably cannot overflow, keep it bare under `#[expect(clippy::arithmetic_side_effects)]`
  with a `reason` saying why (e.g., "`end` is at most `line.len()`") rather than `checked_*` + `?`, which would turn
  a future bug into a silent `None`.
- Don't add fallbacks for cases an earlier check rules out (e.g., `.filter(|word| !word.is_empty())` after a check
  that guarantees a non-empty match); state the guarantee in a comment instead.
- Shadow a variable for a clear transformation of the same value instead of inventing a new name: conversions
  (`let filepath = filepath.as_ref();`), parsing and trimming (`let port = port.trim().parse::<u16>()?;`), wrapping
  (`let path = PathBuf::from(path);`), or changing mutability (`let mut buf = buf;`). Never reuse a name for an
  unrelated value (`shadow_unrelated` stays enabled).
- Don't use sentinel values to force a code path (e.g., passing `BADADDR` to get `None`); express the `Option`
  flow directly with `and_then`.
- At OS/FFI and dependency boundaries, read what the dependency actually does rather than assuming: e.g., a
  `Duration` timeout passed as `SO_RCVTIMEO` is truncated to microseconds, and a zero timeout blocks forever
  (clamp or stop early so such values never reach the call); haruspex's `decompile_to_file` returns `Ok(())` even
  when the `.h` file wasn't written.

## Performance

- Hoist loop-invariant work out of hot loops; compute once, store plain data, and query it cheaply.
- Minimize FFI calls and allocations in hot paths (e.g., don't fetch the same FFI-backed value twice, and don't
  allocate a `String` per iteration just to compare a prefix).
- Prefer a single lookup (`HashMap<String, Priority>`) over several sequential ones.
- Linear scans over tiny collections (a handful of ranges) beat hashing or sorting.
- Under a lock, only snapshot what you need (clone `Arc`s, copy `Copy` values) and release it before scanning or
  I/O; keep a check followed by a mutation under a single lock.
- Measure before claiming a speedup or no regression: style refactors of hot code can rescan input or compare more
  fields. Check behavior with a differential test against the old version, judge regressions against what users can
  notice, and report micro-optimizations that fixed costs dominate honestly as code-quality improvements.

## idalib and FFI

For projects built on idalib (augur, rhabdomancer, haruspex, idalib itself), also read [idalib.md](idalib.md).

## CLI and output conventions

- Every `main.rs` has a banner (`{PROGRAM} {VERSION} - ...` and copyright with `{AUTHORS}`) from
  `env!("CARGO_BIN_NAME")`/`CARGO_PKG_VERSION`/`CARGO_PKG_AUTHORS` constants, and `main() -> ExitCode`.
- Argument parsing: a CLI as simple as augur's (fixed positional arguments only) follows its template, with
  `env::args_os()`, a `(Some(arg), None)` match, `-h`/`--help` handling, and a `usage(prog) -> ExitCode` returning
  `ExitCode::FAILURE`. Anything more complex uses `clap` derive (see singsing-rs's `zucchini`), with validation
  pushed into clap (`value_parser!`, `FromStr` newtypes, typed fields such as `NonZeroU64`) rather than checked
  afterward. Defaults are typed too: `default_value_t = DEFAULT_BANDWIDTH_KIB` (a checked const), not a
  `default_value = "15"` string that clap only parses at runtime.
- Results go to stdout (`println!`); everything else (banner, progress, summary, timing, errors) goes to stderr
  (`eprintln!`).
- Before refactoring code that produces output, decide whether its order is a contract (e.g., the order of
  listed results), and document the decision either way.
- Message prefixes: `[*]` progress, `[+]` success/summary, `[-]` information, `[!]` warning/error. Report errors as
  `eprintln!("[!] Error: {err:#}")`. Print elapsed time with `{:.1} seconds`.
- No emojis and no decorations around printed output, unless they are explicitly requested (see
  [jiggy](https://github.com/0xdea/jiggy) for an example).

## Documentation and comments

- Every item has a doc comment (`missing_docs` is on), including private ones. The exceptions are a binary's
  `fn main()` and unit test functions (`#[test]`), whose descriptive names already document them; helper
  functions in test modules still get a doc comment. Crate docs include the README:
  `#![cfg_attr(doc, doc = include_str!("../README.md"))]`.
- Doc comments describe behavior, parameters by name in backticks, and return values; add `# Errors` (and
  `# Panics`/`# Safety` when relevant) sections (C-FAILURE). Use intra-doc links (`[`Type`]`, `[`Type::method`]`)
  (C-LINK).
- Comments are full sentences ending with a period; non-doc comments appear only where needed to explain _why_
  rather than _what_: prefer self-explanatory code. Keep doc comments accurate when code changes. A comment that
  justifies something (e.g., why ignoring an error is safe) must hold on every path that reaches the code, not
  just the common one; check each caller before writing it.
- `unsafe` blocks need a `// Safety:` comment (e.g., `env::set_var` in a single-threaded test binary).
- `CHANGELOG.md` follows Keep a Changelog: entries under `[Unreleased]` in `Added`/`Changed`/`Fixed`/`Removed`/
  `Security`, one short imperative sentence each ("Optimize ...", "Refactor ...", "Update ..."), with code names in
  backticks (C-RELNOTES).
- `Cargo.toml` includes full metadata: authors, description, license, homepage, repository, keywords, categories
  (C-METADATA). `documentation` is optional: crates.io links to the crate's docs.rs page by default, so set it only
  when that default is not suitable (e.g., docs hosted elsewhere).

## Tests

- Unit tests live in `#[cfg(test)] mod tests` with `use super::*;`, return `Result` where useful, and carry
  `#[expect(clippy::panic_in_result_fn, reason = "panics are allowed in test code")]` at module level.
- Test names describe the behavior (`copy_to_creates_missing_output_directory`). Every assertion has a message.
- Prove a new regression test can fail: temporarily break the behavior it guards, check that it fails, restore.
- Verify behavior-preserving refactors against the last commit: build `HEAD` from `git archive HEAD` into a temp
  directory (sharing the target directory), run both binaries on fresh copies of the same input, `cmp` their output,
  and confirm the two binaries actually differ so the comparison isn't vacuous.
- Prove the scope of mechanical changes (reflows, renames): e.g., for a comments-only diff, the code with comments
  stripped must be identical to `HEAD`, and the comment text must be identical modulo whitespace.
- When a change intentionally reorders output, compare it per group (e.g., each header's set of lines) instead
  of byte for byte, and say so if the test data can't actually exercise the reordering.
- When the behavior under test is what a binary prints, and the library prints it directly, run the real binary
  as a subprocess (`process::Command::new(env!("CARGO_BIN_EXE_<name>"))`) and pin its stdout with a literal.
- Tests that pin an external contract (wire names, file formats, CLI output) use literal values, not the production
  constants, so an accidental change to a constant fails the test.
- Extract time-dependent decisions out of I/O loops into pure functions that take `now: Instant` as a parameter
  (e.g., singsing-rs's `receive_wait`), so every edge case is unit-testable without real clocks, sockets, or
  privileges.
- File-system tests use per-test temp directories under `env::temp_dir()`, scoped by label and process ID.

## Collaboration

- Explain the plan for each change and wait for approval before implementing it.
- One concern per commit: behavior-preserving refactors, mechanical reformatting (e.g., comment reflows), and new
  behavior go in separate commits; start the next change only after the user has committed the previous one.
- Weigh a fix's complexity against how often its inputs occur in the tool's domain: prefer the simplest fix that
  covers realistic inputs, document the remaining limitation and pin it with a test, and keep a more complete
  alternative on a branch if it might be wanted later.
- For output-only improvements (shorter or tidier output), prefer redundant but complete output over any
  heuristic that could drop results, and over code that only buys cosmetics; offer "leave it and document it" as
  an option.
- Never `git commit` (or push); the user reviews and commits.
- After a change: run the checks above, update `CLAUDE.md` and `CHANGELOG.md` when relevant, and summarize what
  changed and how it was verified.
