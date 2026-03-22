# Changelog

All notable changes to this project will be documented in this file.

## [0.1.0] - 2026-03-22

### Added

- Initial release
- Global coverage summary (line count + percentage)
- Branch coverage summary and per-file branch columns (when SimpleCov branch coverage is enabled)
- Group-aware output: respects `SimpleCov.add_group` definitions with per-group headings and coverage %
- Per-file missing line numbers with compressed ranges (e.g. `1-3, 5, 8-10`)
- Configurable options:
  - `output_filename` — output file name (relative to `SimpleCov.coverage_path`)
  - `print_to_stdout` — also print to STDOUT for CI logs
  - `max_rows` — cap files shown per group
  - `missing_len` — truncate long missing-lines strings
  - `show_covered` — hide/show 100% covered files
  - `sort` — `:coverage` (worst first) or `:path` (alphabetical)
  - `title` — custom report heading
  - `show_branch_coverage` — toggle branch columns
- Block DSL for configuration via `MarkdownProFormatter.configure { |c| ... }`
- Compatible with `SimpleCov::Formatter::MultiFormatter`
