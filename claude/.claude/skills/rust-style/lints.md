# Baseline lints

Every project uses the lint setup of the [raptor-rust-template](https://github.com/0xdea/raptor-rust-template)
`Cargo.toml`, made of the blocks below. Any other allow is decided case by case: when a project allows an extra lint,
don't flag it as drift, but ask about it if it looks unnecessary. A lint that fights idiomatic code everywhere (e.g.,
`pattern_type_mismatch` vs default binding modes) belongs in the allow list, not in scattered `#[expect]`s.

The crate opts into the workspace lints; without this, the `[workspace.lints]` tables have no effect on it:

```toml
[lints]
workspace = true
```

rustc lints:

```toml
[workspace.lints.rust]
missing_docs = { level = "warn" }
elided_lifetimes_in_paths = { level = "warn" }
bare_trait_objects = { level = "warn" }
explicit_outlives_requirements = { level = "warn" }
```

Clippy lints: all groups are enabled as warnings with `priority = -1`, so that the individual allows take precedence
over them (keys in a TOML table have no order, so their position in the file doesn't decide it; clippy's
`lint_groups_priority` flags a group left at the default priority), followed by the baseline allow list, wanted in
every project and kept in this curated order (don't sort it; see the Rust Style Guide section of `SKILL.md`):

```toml
[workspace.lints.clippy]
all = { level = "warn", priority = -1 }
pedantic = { level = "warn", priority = -1 }
nursery = { level = "warn", priority = -1 }
cargo = { level = "warn", priority = -1 }
restriction = { level = "warn", priority = -1 }
# allow some lints
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
