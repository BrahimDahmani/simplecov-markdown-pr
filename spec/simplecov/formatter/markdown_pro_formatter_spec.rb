# frozen_string_literal: true

require 'spec_helper'
require 'fileutils'
require 'tmpdir'

RSpec.describe SimpleCov::Formatter::MarkdownProFormatter do
  let(:formatter) { described_class.new }
  let(:config) { SimpleCov::Formatter::MarkdownPro::Configuration }
  let(:tmp_dir) { Dir.mktmpdir('simplecov-md-test') }

  let(:sample1_path) { File.expand_path('../../fixtures/sample1.rb', __dir__) }
  let(:sample2_path) { File.expand_path('../../fixtures/sample2.rb', __dir__) }
  let(:sample3_path) { File.expand_path('../../fixtures/sample3.rb', __dir__) }

  # Build a SimpleCov::Result with realistic coverage data.
  # Must be called after filters are cleared so fixture files aren't excluded.
  def build_result
    original = {
      sample1_path => { 'lines' => [nil, 1, 1, 1, nil, nil, 1, 1, nil, nil] },
      sample2_path => { 'lines' => [nil, 1, 1, 1, nil, nil, 1, 0, nil, nil, 1, 0, nil, nil] },
      sample3_path => { 'lines' => [nil, 1, 1, 1, nil, nil, 1, 0, nil, nil, 0, 0, nil, nil, 0, 0, nil, nil, 1, 1, nil] }
    }
    SimpleCov::Result.new(original)
  end

  let(:result) { build_result }

  before do
    config.reset!
    config.output_filename = nil # don't write files in tests by default
    config.print_to_stdout = false
    @original_filters = SimpleCov.filters.dup
    SimpleCov.filters.clear
    SimpleCov.groups.clear
    SimpleCov.add_group 'All', /.*/
  end

  after do
    config.reset!
    SimpleCov.filters.replace(@original_filters)
    SimpleCov.groups.clear
    FileUtils.rm_rf(tmp_dir)
  end

  describe '#format' do
    it 'returns a markdown string starting with the title' do
      output = formatter.format(result)
      expect(output).to be_a(String)
      expect(output).to start_with('# Coverage Report')
    end

    it 'includes a summary table with line coverage and file count' do
      output = formatter.format(result)
      expect(output).to include('### Summary')
      expect(output).to include('**Line coverage**')
      expect(output).to include('**Files**')
      expect(output).to match(/\*\*\d+\.\d+%\*\*/)
    end

    it 'includes per-file coverage percentages' do
      output = formatter.format(result)
      expect(output).to include('100.0%')
      expect(output).to include('sample1.rb')
      expect(output).to include('sample2.rb')
      expect(output).to include('sample3.rb')
    end

    it 'includes compressed missing line ranges for files with missed lines' do
      output = formatter.format(result)
      # sample3 has missed lines — verify actual range format (e.g. "8, 11-12, 15-16")
      expect(output).to match(/\d+-\d+/)
    end

    it 'strips SimpleCov.root from filenames' do
      output = formatter.format(result)
      expect(output).not_to include("#{SimpleCov.root}/")
    end

    it 'renders a valid markdown table with pipe-delimited columns' do
      output = formatter.format(result)
      table_lines = output.lines.select { |l| l.strip.start_with?('|') }
      # Summary table (3 lines) + group table (5 lines: header + sep + 3 rows)
      expect(table_lines.size).to be >= 6
      table_lines.each do |line|
        expect(line.strip).to start_with('|').and end_with('|')
      end
    end
  end

  describe 'collapsible groups' do
    it 'wraps groups in <details> tags' do
      output = formatter.format(result)
      expect(output).to include('<details')
      expect(output).to include('</details>')
    end

    it 'includes group name and coverage % in <summary>' do
      output = formatter.format(result)
      expect(output).to match(%r{<summary><strong>All</strong>.*\d+\.\d+% covered})
    end

    it 'includes line count and file count in <summary>' do
      output = formatter.format(result)
      expect(output).to match(/\d+ lines across \d+ files?\)/)
    end

    it 'uses <details open> for groups below 100% coverage' do
      output = formatter.format(result)
      # The "All" group has < 100% coverage, should be open
      expect(output).to include('<details open>')
    end

    it 'uses <details> (collapsed) for groups at 100% coverage' do
      all_covered = {
        sample1_path => { 'lines' => [nil, 1, 1, 1, nil, nil, 1, 1, nil, nil] }
      }
      covered_result = SimpleCov::Result.new(all_covered)
      output = formatter.format(covered_result)
      # 100% group should be collapsed (no "open" attribute)
      expect(output).to include('<details>')
      expect(output).not_to include('<details open>')
    end
  end

  describe 'configuration' do
    it 'uses custom title' do
      config.title = 'My Custom Report'
      output = formatter.format(result)
      expect(output).to start_with('# My Custom Report')
    end

    it 'sorts by path when configured' do
      config.sort = :path
      output = formatter.format(result)
      file_rows = output.lines.select { |l| l.include?('sample') }
      filenames = file_rows.map { |l| l[/sample\d\.rb/] }.compact
      expect(filenames).to eq(filenames.sort)
    end

    it 'respects max_rows and shows hidden count' do
      config.max_rows = 1
      output = formatter.format(result)
      expect(output).to match(/\d+ file\(s\) not shown/)
      # Only 1 file row should appear in the table (plus header + separator)
      data_rows = output.lines.select { |l| l.include?('sample') && l.strip.start_with?('|') }
      expect(data_rows.size).to eq(1)
    end

    it 'hides fully covered files when show_covered is false' do
      config.show_covered = false
      output = formatter.format(result)
      # sample1.rb has 100% coverage — should be excluded from table rows
      table_rows = output.lines.select { |l| l.strip.start_with?('|') && l.include?('sample1.rb') }
      expect(table_rows).to be_empty
    end

    it 'truncates missing lines when max_missing_chars is set' do
      config.max_missing_chars = 3
      output = formatter.format(result)
      # sample3 has long missing ranges — should be truncated with ellipsis
      expect(output).to include("\u2026") # Unicode ellipsis
    end

    it 'supports missing_len= for backwards compatibility' do
      config.missing_len = 3
      output = formatter.format(result)
      expect(output).to include("\u2026")
    end

    it 'writes to file when output_filename is set' do
      allow(SimpleCov).to receive(:coverage_path).and_return(tmp_dir)
      config.output_filename = 'test_report.md'

      formatter.format(result)

      report_path = File.join(tmp_dir, 'test_report.md')
      expect(File.exist?(report_path)).to be true

      content = File.read(report_path)
      expect(content).to start_with('# Coverage Report')
    end

    it 'prints to stdout when configured' do
      config.print_to_stdout = true
      expect { formatter.format(result) }.to output(/# Coverage Report/).to_stdout
    end
  end

  describe 'security' do
    it 'rejects output_filename that escapes coverage directory' do
      allow(SimpleCov).to receive(:coverage_path).and_return(tmp_dir)
      config.output_filename = 'safe.md'

      # This should work fine
      expect { formatter.format(result) }.not_to raise_error

      # But path traversal in the config setter is caught
      expect { config.output_filename = '../../evil.md' }.to raise_error(ArgumentError)
    end

    it 'escapes pipe characters in filenames for markdown table safety' do
      pipe_file = double(
        'source_file',
        filename: "#{SimpleCov.root}/app/models|test.rb",
        covered_percent: 75.0,
        lines_of_code: 10,
        missed_lines: [],
        covered_lines: double(size: 8),
        lines: double(size: 10)
      )

      escaped = formatter.send(:escape_markdown, formatter.send(:short_filename, pipe_file))
      expect(escaped).to include('\\|')
      expect(escaped).not_to include('models|test') # unescaped pipe
    end
  end

  describe 'edge cases' do
    it 'handles result where all files have 100% coverage with show_covered false' do
      all_covered = {
        sample1_path => { 'lines' => [nil, 1, 1, 1, nil, nil, 1, 1, nil, nil] }
      }
      covered_result = SimpleCov::Result.new(all_covered)
      config.show_covered = false
      output = formatter.format(covered_result)
      expect(output).to include('_No files in this group._')
    end

    it 'handles max_rows larger than file count gracefully' do
      config.max_rows = 100
      output = formatter.format(result)
      expect(output).not_to include('file(s) not shown')
    end
  end

  describe '.configure block DSL' do
    it 'accepts a configuration block' do
      described_class.configure do |c|
        c.title = 'Block Test'
        c.max_rows = 5
      end

      expect(config.title).to eq('Block Test')
      expect(config.max_rows).to eq(5)
    end
  end
end
