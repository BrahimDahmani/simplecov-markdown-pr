# SimpleCov Markdown Pro

[![Gem Version](https://badge.fury.io/rb/simplecov-markdown-pro.svg)](https://badge.fury.io/rb/simplecov-markdown-pro)
[![CI](https://github.com/TODO/simplecov-markdown-pro/actions/workflows/ci.yml/badge.svg)](https://github.com/TODO/simplecov-markdown-pro/actions/workflows/ci.yml)

A full-featured Markdown formatter for [SimpleCov](https://github.com/simplecov-ruby/simplecov) that generates rich coverage reports designed for CI/CD pipelines, pull request comments, and documentation.

## Features

- **Global summary** — overall line coverage percentage, line counts, file counts
- **Branch coverage** — automatic branch coverage section and per-file columns when enabled in SimpleCov
- **Group-aware** — respects `SimpleCov.add_group` with per-group headings and group-level coverage %
- **Missing line numbers** — compressed ranges per file (e.g. `1-3, 5, 8-10`)
- **Configurable** — output path, sorting, max rows, truncation, title, stdout printing
- **MultiFormatter compatible** — use alongside `HTMLFormatter`, `JSONFormatter`, etc.

## Sample Output

```markdown
# Coverage Report

**Overall: 87.32%** — 2345/2848 lines in 111 files
**Branch coverage: 79.50%** — 159/200 branches

## Models (92.1%)

| Coverage | File | Lines | Missed | Missing | Branch % | Branches | Br. missed |
|--:|:--|--:|--:|:--|--:|--:|--:|
| 75.0% | app/models/user.rb | 40 | 10 | 12-15, 28, 33-36 | 66.67% | 6 | 2 |
| 88.2% | app/models/order.rb | 34 | 4 | 45, 47-49 | 80.0% | 5 | 1 |
| 100.0% | app/models/product.rb | 22 | 0 | | — | 0 | 0 |

## Controllers (81.5%)

| Coverage | File | Lines | Missed | Missing | Branch % | Branches | Br. missed |
|--:|:--|--:|--:|:--|--:|--:|--:|
| 65.0% | app/controllers/orders_controller.rb | 60 | 21 | 18-21, 33-40, 55-60, 62-65 | 50.0% | 8 | 4 |
| 100.0% | app/controllers/products_controller.rb | 15 | 0 | | — | 0 | 0 |
```

## Installation

Add to your Gemfile:

```ruby
group :test do
  gem "simplecov-markdown-pro", require: false
end
```

Then `bundle install`.

## Usage

### Basic

```ruby
# spec/spec_helper.rb (or test_helper.rb)
require "simplecov"
require "simplecov-markdown-pro"

SimpleCov.formatter = SimpleCov::Formatter::MarkdownProFormatter
SimpleCov.start "rails"
```

### With MultiFormatter

```ruby
require "simplecov"
require "simplecov-markdown-pro"

SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new([
  SimpleCov::Formatter::HTMLFormatter,
  SimpleCov::Formatter::MarkdownProFormatter,
])

SimpleCov.start "rails" do
  add_group "Models",       "app/models"
  add_group "Controllers",  "app/controllers"
  add_group "Interactors",  "app/interactors"
  add_group "Services",     "app/services"
  add_group "Mailers",      "app/mailers"
end
```

### With branch coverage

```ruby
SimpleCov.start "rails" do
  enable_coverage :branch
  # groups, filters, etc.
end
```

Branch columns appear automatically when SimpleCov has branch data.

## Configuration

```ruby
SimpleCov::Formatter::MarkdownProFormatter.configure do |config|
  # Output file name, relative to SimpleCov.coverage_path (default: "coverage.md")
  # Set to nil to skip file output (format returns the string only).
  config.output_filename = "coverage.md"

  # Also print the report to STDOUT — useful for CI logs (default: false)
  config.print_to_stdout = true

  # Maximum files shown per group. nil = show all (default: nil)
  config.max_rows = 15

  # Truncate "Missing" column to N characters. 0 = no limit (default: 0)
  config.missing_len = 60

  # Show files with 100% coverage in tables (default: true)
  config.show_covered = false

  # Sort order: :coverage (worst first) or :path (alphabetical) (default: :coverage)
  config.sort = :coverage

  # Report title (default: "Coverage Report")
  config.title = "Test Coverage"

  # Show branch coverage columns when data is available (default: true)
  config.show_branch_coverage = true
end
```

## CI Integration Examples

### GitHub Actions — PR comment

```yaml
- name: Run tests
  run: bundle exec rspec

- name: Post coverage comment
  uses: marocchino/sticky-pull-request-comment@v2
  if: github.event_name == 'pull_request'
  with:
    recreate: true
    path: coverage/coverage.md
```

### SemaphoreCI — artifact

```yaml
after_pipeline:
  task:
    jobs:
      - name: Coverage report
        commands:
          - cat coverage/coverage.md
          - artifact push workflow coverage/coverage.md
```

## How it works

The formatter implements SimpleCov's formatter API (`#format(result)`). When your test suite finishes:

1. SimpleCov passes a `SimpleCov::Result` to `#format`
2. The formatter iterates `result.groups` (which respects your `add_group` config)
3. For each group, it builds a Markdown table with per-file stats
4. Missing line numbers are compressed into ranges (e.g. `[1,2,3,5,8,9,10]` → `1-3, 5, 8-10`)
5. Branch coverage columns are added automatically when SimpleCov has branch data
6. The report is written to `coverage/coverage.md` (configurable) and optionally printed to STDOUT

## Development

```bash
git clone https://github.com/TODO/simplecov-markdown-pro.git
cd simplecov-markdown-pro
bundle install
bundle exec rspec
```

## Contributing

Bug reports and pull requests are welcome on GitHub.

## License

The gem is available as open source under the terms of the [MIT License](LICENSE).
