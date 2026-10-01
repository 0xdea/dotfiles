# idalib and FFI

Rules for projects built on [idalib](https://github.com/idalib-rs/idalib) (e.g., augur, rhabdomancer, haruspex), in
addition to `SKILL.md`.

- Types whose methods call FFI on an IDB or derived objects must be bound to the IDB lifetime
  (`struct Foo<'a> { _marker: PhantomData<&'a IDB> }` or by holding `Function<'a>`, etc.).
- Call `idalib::force_batch_mode()` before opening any database, including in test harnesses.
- `decompile()` always passes `DECOMP_NO_CACHE`, so each call is a full decompilation: decompile each function at
  most once per run, caching results and failures (e.g., augur's `DumpCache`).
- Some operations only queue work for auto-analysis (e.g., decompiling can create strings): call `idb.auto_wait()`
  before reading the results. `IDB::open` with auto-analysis already waits.
- Names from the analyzed binary (strings, function names) are untrusted: sanitize them into a single path
  component before building file names, and unit-test path traversal.
- Cache FFI results that can't change during a run as plain data, not borrowed wrappers: e.g., `.plt` segments as
  `Vec<Range<Address>>`. IDA's `range_t` is half-open (`end_ea` excluded), exactly like `Range::contains`.
- Handle `.plt` thunk indirection for ELF binaries, and skip `FunctionFlags::THUNK` functions where appropriate.
- Annotations (bookmarks, comments) must be idempotent: check before adding.
- Stop on Hex-Rays license errors, but tolerate per-function decompilation failures.
- The lowercase rule for error messages in `SKILL.md` also covers `IDAError::ffi_with` messages.
- Add `linker_messages = "allow"` to `[workspace.lints.rust]` (after the baseline in `lints.md`), with a comment
  pointing to the workaround it is for (https://github.com/idalib-rs/idalib/issues/81), until that issue is fixed.
- IDA-dependent integration tests use a custom harness (`harness = false`) because IDA is not thread-safe and CI
  has no IDA (on small inputs, auto-analysis dominates their runtime); CI only compiles them
  (`cargo test --no-run`). They clean up any `.i64` and temporary files.
- Structure the harness like augur's: documented constants at the top; a `main()` that calls
  `idalib::force_batch_mode()` and then one `test_*` function per scenario; one `check_*` function per assertion,
  each printing its own `[*] Checking ... Ok.` line. Scenarios start and end with a reset helper, write temporary
  files (e.g., configuration files) under `env::temp_dir()` rather than the source tree, `drop()` their `IDB`
  before the code under test reopens the database, and match expected errors against `{err:#}` (the full
  context chain).
- Reset and check every IDB file, packed or unpacked (`i64`, `id0`, `id1`, `id2`, `nam`, `til`), not just the
  `.i64`, so that a crashed run can't leave a stale database behind for the next scenario.
- IDA must run on the main thread ("IDA cannot function correctly when not running on the main thread"), so
  standard `#[test]` functions, which run on worker threads, can't use it. For a throwaway probe of IDA's view
  of a binary, write a temporary `examples/` program (`cargo run --example ...`), then delete it.
- `IDB::open` doesn't save the database on close; `IDB::open_with(path, true, true)` does. Test fixtures that
  must persist (e.g., a pre-existing user bookmark) need `open_with`.
- Never look a bookmark up by address: IDA overlays bookmarks added at an already bookmarked address, and
  `get_description(ea)` returns only one of them, possibly a user's own. Scan every index (`get_address(idx)` +
  `get_description_by_index(idx)`) and track your own bookmarks in a set, updated as you add them.
- ELF PLT facts to know before touching thunk handling:
  - IDA splits each lazy-binding `.plt` stub into its own function, and nothing references the stubs, so the
    stubs' `jmp PLT0` XREFs form no cycle.
  - On AArch64, a stub (`adrp`/`ldr`/`add`/`br`) can have several XREFs to its import, so traversals that follow
    stubs must deduplicate (see the visited-set rule in `SKILL.md`).
  - A bad function typically matches twice by name, as its `.plt` stub (a thunk) and as its import. Don't
    deduplicate them by name: an unrelated function can normalize to the same name, or IDA may not link the stub
    to the import, and the stub's call sites would be lost.
