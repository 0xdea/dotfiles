---
name: rust-style
description: raptor's Rust style guide (idiomatic Rust, performance, docs, lints, CLI/output conventions, idalib/FFI rules). Use whenever writing, reviewing, or refactoring Rust code in any of raptor's projects (rhabdomancer, augur, haruspex, idalib, zed-highlight, singsing-rs, etc.) or starting a new one.
---

# Rust style guide

Sources: [idalib-rust-style](https://github.com/idalib-rs/idalib/blob/master/skills/idalib-rust-style/SKILL.md),
[xorpse/rust-style](https://github.com/xorpse/rust-style) lints,
[Rust API Guidelines](https://rust-lang.github.io/api-guidelines/checklist.html), and conventions established in
these representative projects:
[augur](https://github.com/0xdea/augur), [rhabdomancer](https://github.com/0xdea/rhabdomancer),
[haruspex](https://github.com/0xdea/haruspex), [idalib](https://github.com/idalib-rs/idalib),
[zed-highlight](https://github.com/0xdea/zed-highlight), and [singsing-rs](https://github.com/0xdea/singsing-rs). When unsure
how something is usually done, look at how these projects do it (local clones may exist under `~/RustroverProjects/`).

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
   win over this guide. Clippy with the project's lints is the minimum bar: if code passes
   `cargo clippy --all-targets --locked -- -D warnings` but violates a rule below, still fix it.

## Tooling

- Every project uses workspace lints with all clippy groups enabled (`all`, `pedantic`, `nursery`, `cargo`,
  `restriction`) plus a short, curated allow list. Keep new projects in line with augur's `[workspace.lints]` block.
  The baseline clippy allow list, wanted in every project:
  ```toml
  blanket_clippy_restriction_lints = "allow"
  std_instead_of_core = "allow"
  std_instead_of_alloc = "allow"
  arbitrary_source_item_ordering = "allow"
  implicit_return = "allow"
  question_mark_used = "allow"
  pattern_type_mismatch = "allow"
  shadow_reuse = "allow"
  shadow_same = "allow"
  print_stdout = "allow"
  print_stderr = "allow"
  single_char_lifetime_names = "allow"
  impl_trait_in_params = "allow"
  missing_inline_in_public_items = "allow"
  inline_modules = "allow"
  single_call_fn = "allow"
  separated_literal_suffix = "allow"
  default_numeric_fallback = "allow"
  ```
  If a project is missing an entry from this list, point it out rather than silently adding it.
- Suppress a lint locally with `#[expect(clippy::lint_name, reason = "...")]`, never `#[allow]`, and only when it
  genuinely cannot be avoided. Prefer restructuring code so the `#[expect]` is not needed (e.g., `saturating_add`
  instead of `+=` with `#[expect(clippy::arithmetic_side_effects)]`).
- A lint that fights idiomatic code everywhere (e.g., `pattern_type_mismatch` vs default binding modes) belongs
  in the `Cargo.toml` allow list, not in scattered `#[expect]`s.
- Always pass `--locked` to cargo commands that support it. Before declaring work done, run:
  ```sh
  cargo fmt --all --check
  cargo clippy --all-targets --locked -- -D warnings
  RUSTDOCFLAGS="-D warnings" cargo doc --locked
  cargo test --locked   # or the project's custom harness, e.g. `cargo test --test tests --locked`
  ```
- Optional extra checks: `cargo fmt -- --config imports_granularity=Module,group_imports=StdExternalCrate` and
  `cargo dylint --git https://github.com/xorpse/rust-style --pattern '*'` (install with
  `cargo install cargo-dylint dylint-link`).

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

## Naming

- No single-character identifiers (`clippy::min_ident_chars`): `name`, `func`, `idx`, `addr`, `segm`, `err`, not
  `s`, `f`, `i`, `a`. Single-char lifetimes (`'a`) are fine.
- Casing per RFC 430 (C-CASE). Use consistent word order across the codebase (C-WORD-ORDER).
- Getters have no `get_` prefix: `timeout()`, `set_timeout()`, builder-style `with_timeout()` delegating to the
  setter (C-GETTER). Conversions follow `as_` (cheap borrow), `to_` (expensive), `into_` (consuming) (C-CONV).
- Iterator-producing methods are `iter`/`iter_mut`/`into_iter` (C-ITER).
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
- Types eagerly derive common traits (C-COMMON-TRAITS): small enums are `Debug, Copy, Clone, PartialEq, Eq` (and
  `Ord`/`Hash` when useful) and are passed by value. All public types implement `Debug` (C-DEBUG). Keep derives in
  alphabetical order.
- Use `#[non_exhaustive]` on public enums that may grow, and on public structs with `pub` fields that may gain more
  fields (adding a field would otherwise break struct literals and exhaustive destructuring in other crates; since
  other crates then can't build the struct with a literal, provide a constructor). Use `#[must_use]` on pure
  functions whose result matters, and `const fn` wherever possible.
- Functions with a clear receiver are methods (C-METHOD). Constructors are static inherent methods (C-CTOR).
- Return values instead of taking out-parameters (C-NO-OUT): a traversal returns `Result<usize, _>` rather than
  incrementing a `&mut usize`. Don't store state in a struct field just to return it once.
- Use types, not `bool`/`Option` flags, to convey meaning in arguments (C-CUSTOM-TYPE); newtypes for static
  distinctions (C-NEWTYPE).
- Prefer one data structure keyed by a composite or enum key over parallel structures dispatched by `match`
  (e.g., one `BTreeMap<(Priority, FunctionId), _>` instead of three maps).
- Type aliases with a doc comment for recurring complex types (`type DumpCache = HashMap<Address, Option<...>>;`).
- Only use `#[repr(u8)]`/explicit discriminants when the numeric values are actually used or are an external
  contract (e.g., they match SDK constants, documented in a comment).

## Structs and enums layout

- No blank lines between consecutive fields or variants; doc comments between them are fine.
- Enum variants in alphabetical order only when their order means nothing. When the order carries meaning
  (priority, severity, log level, state machine, FFI), keep the meaningful order and never alphabetize it just to
  satisfy xorpse's `sorted_enum_variants` lint (e.g., `Priority { High, Medium, Low }` stays as is).
- Every field and variant has a doc comment.

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
  Use `#[error(transparent)]` only when the variant adds nothing to the wrapped error, e.g. it wraps another error
  type of the same crate that already fully describes the failure (as in singsing-rs's `ScanError::Incomplete`,
  which wraps `IncompleteScanError`). Use `#[from]` only when a single, unambiguous conversion makes `?`
  convenient; it implies `#[source]`, and several variants can't all use `#[from]` for the same source type.
- Error messages are always lowercase unless they start with a proper noun or acronym (`"no type definitions
generated"`, `"I/O error: ..."`). This applies everywhere: `thiserror` messages, `anyhow` context strings
  (`.context("failed to load known bad API function names")`), `anyhow::ensure!`/`bail!` messages, and
  `IDAError::ffi_with` messages. User-facing `eprintln!` output lines are not error messages and keep their prefix
  style (`[!] Error: {err:#}`).
- Never silently ignore errors. When an error is deliberately ignored (best-effort work), say so in a comment and
  match the ignored variants explicitly rather than using `_` for everything.
- Use `inspect_err` for cleanup-on-failure, and report (don't propagate) a failure during cleanup.
- Use `anyhow::ensure!` for precondition checks.

## Expressions and idioms

- Rely on inference; never annotate `let` bindings. Use turbofish or literal suffixes instead:
  `Vec::<u8>::new()`, `.collect::<Vec<_>>()`, `0_usize`, not `let count: usize = 0;`.
- Inline format arguments: `format!("{name}")`, `println!("{from:#X} in {caller}")`, `{err:#}` for anyhow chains.
- `to_owned()`/`String::from` on `&str`, never `to_string()`. `clone_into` to reuse an existing allocation.
- `Vec::new()` over `vec![]` for empty vectors (`vec![first]` for a non-empty literal is fine).
- Prefer combinators that state intent: `is_some_and`, `map_or`, `map_or_else`, `unwrap_or_default`,
  `and_then`, `filter_map` + `bool::then`, `Option::map_or(Ok(()), ...)` for optional fallible work.
- `let ... else` for early returns; `if let ... && ...` chains (edition 2024) instead of nested `if let`.
- Walk linked chains with `iter::successors(first, Next::next)` (e.g., XREF chains with `XRef::next_to`) instead of
  manual `while let` loops. Use an explicit `Vec` work stack instead of recursion for unbounded depth.
- Use the `Entry` API instead of `contains_key` + `insert`.
- Counters use `saturating_add` (or `checked_*` when overflow is an error), not bare arithmetic.
- Shadow a variable for a clear transformation of the same value instead of inventing a new name: conversions
  (`let filepath = filepath.as_ref();`), parsing and trimming (`let port = port.trim().parse::<u16>()?;`), wrapping
  (`let path = PathBuf::from(path);`), or changing mutability (`let mut buf = buf;`). `shadow_reuse` and
  `shadow_same` are in the baseline allow list for this reason. Never reuse a name for an unrelated value
  (`shadow_unrelated` stays enabled).
- Don't use sentinel values to force a code path (e.g., passing `BADADDR` to get `None`); express the `Option`
  flow directly with `and_then`.

## Performance

- Hoist loop-invariant work out of hot loops; compute once, store plain data, and query it cheaply.
- Minimize FFI calls and allocations in hot paths (e.g., don't call `name()` twice for the same function, don't
  allocate a `String` per iteration just to compare a prefix).
- Prefer a single lookup (`HashMap<String, Priority>`) over several sequential ones.
- Linear scans over tiny collections (a handful of ranges) beat hashing or sorting.
- Measure before claiming speedups; on small inputs, IDA auto-analysis dominates runtime, so report
  micro-optimizations honestly as code-quality improvements.

## idalib and FFI

- Types whose methods call FFI on an IDB or derived objects must be bound to the IDB lifetime
  (`struct Foo<'a> { _marker: PhantomData<&'a IDB> }` or by holding `Function<'a>`, etc.).
- Call `idalib::force_batch_mode()` before opening any database.
- Cache FFI results that can't change during a run as plain data, not borrowed wrappers: e.g., `.plt` segments as
  `Vec<Range<Address>>`. IDA's `range_t` is half-open (`end_ea` excluded), exactly like `Range::contains`.
- Handle `.plt` thunk indirection for ELF binaries, and skip `FunctionFlags::THUNK` functions where appropriate.
- Annotations (bookmarks, comments) must be idempotent: check before adding.
- Stop on Hex-Rays license errors, but tolerate per-function decompilation failures.

## CLI and output conventions

- `main.rs` follows the augur template: banner (`{PROGRAM} {VERSION} - ...` and copyright with `{AUTHORS}`) from
  `env!("CARGO_BIN_NAME")`/`CARGO_PKG_VERSION`/`CARGO_PKG_AUTHORS` constants, `env::args_os()` parsing with a
  `(Some(arg), None)` match and `-h`/`--help` handling, `main() -> ExitCode`, and a `usage(prog) -> ExitCode`
  that prints usage and returns `ExitCode::FAILURE`.
- Results go to stdout (`println!`); everything else (banner, progress, summary, timing, errors) goes to stderr
  (`eprintln!`).
- Message prefixes: `[*]` progress, `[+]` success/summary, `[-]` information, `[!]` warning/error. Report errors as
  `eprintln!("[!] Error: {err:#}")`. Print elapsed time with `{:.1} seconds`.
- No emojis and no decorations around printed output, unless they are explicitly requested (see
  [jiggy](https://github.com/0xdea/jiggy) for an example).

## Documentation and comments

- Every item has a doc comment (`missing_docs` is on), including private ones. Crate docs include the README:
  `#![cfg_attr(doc, doc = include_str!("../README.md"))]`.
- Doc comments describe behavior, parameters by name in backticks, and return values; add `# Errors` (and
  `# Panics`/`# Safety` when relevant) sections (C-FAILURE). Use intra-doc links (`[`Type`]`, `[`Type::method`]`)
  (C-LINK).
- Comments are full sentences ending with a period, explain _why_ rather than _what_, and stay sparse: prefer
  self-explanatory code. Keep doc comments accurate when code changes.
- Limit non-doc comments to where they are needed to explain _why_ rather than _what_.
- `unsafe` blocks need a `// Safety:` comment (e.g., `env::set_var` in a single-threaded test binary).
- Keep the project `CLAUDE.md` in sync with the code after every change.
- `CHANGELOG.md` follows Keep a Changelog: entries under `[Unreleased]` in `Added`/`Changed`/`Fixed`/`Removed`/
  `Security`, one short imperative sentence each ("Optimize ...", "Refactor ...", "Update ..."), with code names in
  backticks (C-RELNOTES).
- `Cargo.toml` includes full metadata: authors, description, license, homepage, documentation, repository,
  keywords, categories (C-METADATA).

## Tests

- Unit tests live in `#[cfg(test)] mod tests` with `use super::*;`, return `Result` where useful, and carry
  `#[expect(clippy::panic_in_result_fn, reason = "panics are allowed in test code")]` at module level.
- Test names describe the behavior (`copy_to_creates_missing_output_directory`). Every assertion has a message.
- IDA-dependent integration tests use a custom harness (`harness = false`) because IDA is not thread-safe and CI
  has no IDA; CI only compiles them (`cargo test --no-run`). They clean up any `.i64` and temporary files.
- File-system tests use per-test temp directories under `env::temp_dir()`, scoped by label and process ID.

## Collaboration

- Explain the plan for each change and wait for approval before implementing it.
- Never `git commit` (or push); the user reviews and commits.
- After a change: run the checks above, update `CLAUDE.md` and `CHANGELOG.md` when relevant, and summarize what
  changed and how it was verified.
- Dependabot cargo updates stay ungrouped.
