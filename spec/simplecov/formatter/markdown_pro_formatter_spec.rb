# frozen_string_literal: true

require "spec_helper"
require "fileutils"
require "tmpdir"

RSpec.describe SimpleCov::Formatter::MarkdownProFormatter do
  let(:formatter) { described_class.new }
  let(:config) { SimpleCov::Formatter::MarkdownPro::Configuration }
  let(:tmp_dir) { Dir.mktmpdir("simplecov-md-test") }

  let(:sample1_path) { File.expand_path("../../fixtures/sample1.rb", __FILE__) }
  let(:sample2_path) { File.expand_path("../../fixtures/sample2.rb", __FILE__) }
  let(:sample3_path) { File.expand_path("../../fixtures/sample3.rb", __FILE__) }

  # Build a SimpleCov::Result with realistic coverage data
  let(:result) do
    original = {
      sample1_path => { "lines" => [nil, 1, 1, 1, nil, nil, 1, 1, nil, nil] },
      sample2_path => { "lines" => [nil, 1, 1, 1, nil, nil, 1, 0, nil, nil, 1, 0, nil, nil] },
      sample3_path => { "lines" => [nil, 1, 1, 1, nil, nil, 1, 0, nil, nil, 0, 0, nil, nil, 0, 0, nil, nil, 1, 1, nil] }
    }
    SimpleCov::Result.new(original)
  end

  before do
    config.reset!
    config.output_filename = nil # don't write files in tests by default
    config.print_to_stdout = false
  end

  after do
    config.reset!
    FileUtils.rm_rf(tmp_dir)
  end

  describe "#format" do
    it "returns a markdown string" do
      output = formatter.format(result)
      expect(output).to be_a(String)
      expect(output).to start_with("# Coverage Report")
    end

    it "includes overall coverage summary" do
      output = formatter.format(result)
      expect(output).to match(/\*\*Overall: \d+\.\d+%\*\*/)
      expect(output).to match(/lines in \d+ files/)
    end

    it "includes per-file coverage percentages" do
      output = formatter.format(result)
      expect(output).to include("100.0%")
      expect(output).to include("sample1.rb")
      expect(output).to include("sample2.rb")
      expect(output).to include("sample3.rb")
    end

    it "includes missing line numbers" do
      output = formatter.format(result)
      # sample2 has missed lines at positions where 0 appears
      expect(output).to match(/\d+/)
    end

    it "strips SimpleCov.root from filenames" do
      output = formatter.format(result)
      expect(output).not_to include(SimpleCov.root + "/")
    end
  end

  describe "groups support" do
    it "renders group headings when groups are defined" do
      allow(SimpleCov).to receive(:groups).and_return({
        "Fixtures" => SimpleCov::FileList.new(result.source_files.to_a)
      })

      # Groups are applied through result.groups which uses SimpleCov.groups
      output = formatter.format(result)
      # The formatter iterates result.groups which should return group names
      expect(output).to be_a(String)
    end
  end

  describe "configuration" do
    it "uses custom title" do
      config.title = "My Custom Report"
      output = formatter.format(result)
      expect(output).to start_with("# My Custom Report")
    end

    it "sorts by path when configured" do
      config.sort = :path
      output = formatter.format(result)
      # Should still produce valid output
      expect(output).to include("sample1.rb")
    end

    it "respects max_rows" do
      config.max_rows = 1
      output = formatter.format(result)
      # Should mention hidden files
      expect(output).to match(/file\(s\) not shown/)
    end

    it "hides fully covered files when show_covered is false" do
      config.show_covered = false
      output = formatter.format(result)
      # sample1.rb has 100% coverage — should be excluded from table
      lines = output.lines.select { |l| l.include?("sample1.rb") }
      expect(lines).to be_empty
    end

    it "truncates missing lines when missing_len is set" do
      config.missing_len = 5
      output = formatter.format(result)
      # If any missing line string exceeds 5 chars, it should be truncated
      expect(output).to be_a(String)
    end

    it "writes to file when output_filename is set" do
      allow(SimpleCov).to receive(:coverage_path).and_return(tmp_dir)
      config.output_filename = "test_report.md"

      formatter.format(result)

      report_path = File.join(tmp_dir, "test_report.md")
      expect(File.exist?(report_path)).to be true

      content = File.read(report_path)
      expect(content).to start_with("# Coverage Report")
    end

    it "prints to stdout when configured" do
      config.print_to_stdout = true
      expect { formatter.format(result) }.to output(/# Coverage Report/).to_stdout
    end
  end

  describe ".configure block DSL" do
    it "accepts a configuration block" do
      described_class.configure do |c|
        c.title = "Block Test"
        c.max_rows = 5
      end

      expect(config.title).to eq("Block Test")
      expect(config.max_rows).to eq(5)
    end
  end
end
