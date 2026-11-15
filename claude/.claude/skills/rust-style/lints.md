# Baseline lints

Every project uses the lint setup of the [raptor-rust-template](https://github.com/0xdea/raptor-rust-template)
`Cargo.toml`, made of the blocks below. Any other allow is decided case by case: when a project allows an extra lint,
don't flag it as drift, but ask about it if it looks unnecessary. A lint that fights idiomatic code everywhere (e.g.,
`pattern_type_mismatch` vs default binding modes, or `rest_pattern_accessible_field` vs `unneeded_field_pattern`,
which ban `..` and `field: _` respectively) belongs in the allow list, not in scattered `#[expect]`s.

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
every project and kept in this curated order (don't sort it; see the Formatting by hand section of `SKILL.md`):

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
rest_pattern_accessible_field = "allow"
shadow_reuse = "allow"
shadow_same = "allow"
print_stdout = "allow"
print_stderr = "allow"
single_char_lifetime_names = "allow"
impl_trait_in_params = "allow"
missing_inline_in_public_items = "allow"
inline_modules = "allow"
mod_module_files = "allow"
single_call_fn = "allow"
separated_literal_suffix = "allow"
default_numeric_fallback = "allow"
multiple_crate_versions = "allow"
```

Cargo lints (Rust 1.100+; older Cargo only warns about an unused manifest key) follow the same pattern with the
groups Cargo has: `default` is its `all` (`correctness`, `suspicious`, `style`), and it has no `nursery`, `cargo`,
`complexity`, or `perf` (they are reported as unknown lints). Its `restriction` group contradicts itself, with both
kebab-case and snake_case naming lints for packages and features: package names are kebab-case, so the snake_case
lints are allowed. `-D warnings` doesn't reach these lints, so CI's clippy step sets `CARGO_BUILD_WARNINGS=deny`,
which fails on Cargo lint and compiler warnings (not on Cargo's general warnings, such as ignored profiles):

```toml
[workspace.lints.cargo]
default = { level = "warn", priority = -1 }
pedantic = { level = "warn", priority = -1 }
restriction = { level = "warn", priority = -1 }
# allow some lints
non_snake_case_packages = "allow"
non_snake_case_features = "allow"
```

```yaml
      - name: clippy
        env:
          CARGO_BUILD_WARNINGS: deny
        run: cargo clippy --workspace --all-targets --locked -- -D warnings
```
