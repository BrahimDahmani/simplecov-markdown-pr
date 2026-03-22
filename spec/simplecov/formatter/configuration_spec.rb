# frozen_string_literal: true

require "spec_helper"

RSpec.describe SimpleCov::Formatter::MarkdownPro::Configuration do
  after { described_class.reset! }

  it "has sensible defaults" do
    expect(described_class.output_filename).to eq("coverage.md")
    expect(described_class.print_to_stdout).to eq(false)
    expect(described_class.max_rows).to be_nil
    expect(described_class.missing_len).to eq(0)
    expect(described_class.show_covered).to eq(true)
    expect(described_class.sort).to eq(:coverage)
    expect(described_class.title).to eq("Coverage Report")
    expect(described_class.show_branch_coverage).to eq(true)
  end

  it "allows overriding each option" do
    described_class.output_filename = "custom.md"
    described_class.print_to_stdout = true
    described_class.max_rows = 10
    described_class.missing_len = 50
    described_class.show_covered = false
    described_class.sort = :path
    described_class.title = "My Report"
    described_class.show_branch_coverage = false

    expect(described_class.output_filename).to eq("custom.md")
    expect(described_class.print_to_stdout).to eq(true)
    expect(described_class.max_rows).to eq(10)
    expect(described_class.missing_len).to eq(50)
    expect(described_class.show_covered).to eq(false)
    expect(described_class.sort).to eq(:path)
    expect(described_class.title).to eq("My Report")
    expect(described_class.show_branch_coverage).to eq(false)
  end

  it "resets to defaults" do
    described_class.output_filename = "changed.md"
    described_class.reset!
    expect(described_class.output_filename).to eq("coverage.md")
  end
end
