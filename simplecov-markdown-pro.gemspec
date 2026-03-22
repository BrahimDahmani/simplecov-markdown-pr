# frozen_string_literal: true

require_relative "lib/simplecov/formatter/markdown_pro/version"

Gem::Specification.new do |spec|
  spec.name = "simplecov-markdown-pro"
  spec.version = SimpleCov::Formatter::MarkdownPro::VERSION
  spec.authors = ["Brahim"]
  spec.email = ["TODO@example.com"]

  spec.summary = "Full-featured Markdown formatter for SimpleCov with groups, summary, and branch coverage"
  spec.description = <<~DESC
    A SimpleCov formatter that generates rich Markdown coverage reports featuring
    global summary, group-aware tables, per-file missing line numbers, branch
    coverage support, and configurable output. Designed for CI/CD pipelines that
    post coverage as Markdown comments on pull requests.
  DESC
  spec.homepage = "https://github.com/TODO/simplecov-markdown-pro"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?("bin/", "spec/", ".git", ".github", "Gemfile")
    end
  end
  spec.require_paths = ["lib"]

  spec.add_dependency "simplecov", ">= 0.18"
end
