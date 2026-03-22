# frozen_string_literal: true

require 'fileutils'
require 'simplecov'
require_relative 'markdown_pro/version'
require_relative 'markdown_pro/configuration'
require_relative 'markdown_pro/line_ranges'
require_relative 'markdown_pro/table_builder'

module SimpleCov
  module Formatter
    # A full-featured Markdown formatter for SimpleCov.
    #
    # Features:
    #   - Global coverage summary (line + branch)
    #   - Group-aware tables (respects SimpleCov.add_group)
    #   - Per-file missing line numbers (compressed ranges)
    #   - Branch coverage columns when enabled
    #   - Configurable output, sorting, truncation
    #
    # Usage:
    #
    #   require "simplecov/formatter/markdown_pro_formatter"
    #   SimpleCov.formatter = SimpleCov::Formatter::MarkdownProFormatter
    #
    # With multi-formatter:
    #
    #   SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new([
    #     SimpleCov::Formatter::HTMLFormatter,
    #     SimpleCov::Formatter::MarkdownProFormatter,
    #   ])
    #
    # Configuration:
    #
    #   SimpleCov::Formatter::MarkdownProFormatter.configure do |config|
    #     config.output_filename = "coverage.md"
    #     config.max_rows = 15
    #     config.sort = :coverage
    #     config.show_branch_coverage = true
    #     config.print_to_stdout = true
    #   end
    #
    class MarkdownProFormatter
      Config = MarkdownPro::Configuration

      # Yields the Configuration class for block-style setup.
      def self.configure
        yield Config
      end

      # SimpleCov calls this with a SimpleCov::Result instance.
      # Returns the Markdown string.
      def format(result)
        output = build_report(result)

        write_file(output) if Config.output_filename
        $stdout.puts(output) if Config.print_to_stdout

        output
      end

      private

      # ─── Report assembly ─────────────────────────────────────────────

      def build_report(result)
        branches = branches_enabled?(result)
        sections = []
        sections << build_title
        sections << build_summary_table(result, branches)
        sections << ''

        result.groups.each do |group_name, files|
          sections << build_group_section(group_name, files, branches)
        end

        sections.compact.join("\n")
      end

      # ─── Title ───────────────────────────────────────────────────────

      def build_title
        "# #{Config.title}\n"
      end

      # ─── Summary table ───────────────────────────────────────────────

      def build_summary_table(result, branches)
        covered = result.covered_lines
        missed = result.missed_lines
        total = covered + missed
        pct = result.covered_percent.round(2)
        file_count = result.source_files.size

        table = MarkdownPro::TableBuilder.new(
          headers: %w[Metric Value],
          aligns: %i[left left]
        )
        table.add_row(['**Line coverage**', "**#{pct}%** (#{covered}/#{total} lines)"])
        table.add_row(['**Files**', file_count.to_s])

        if branches
          stats = branch_stats(result)
          if stats
            br_total = stats[:total]
            br_covered = stats[:covered]
            br_pct = br_total.zero? ? 100.0 : (br_covered.to_f / br_total * 100).round(2)
            table.add_row(['**Branch coverage**', "**#{br_pct}%** (#{br_covered}/#{br_total} branches)"])
          end
        end

        "### Summary\n\n#{table.to_md}"
      end

      # ─── Group section ──────────────────────────────────────────────

      def build_group_section(group_name, files, branches)
        group_pct = files.covered_percent.round(2)
        total_lines = files.map(&:lines_of_code).sum
        file_count = files.size
        open_attr = group_pct < 100.0 ? ' open' : ''
        file_word = file_count == 1 ? 'file' : 'files'

        lines = []
        lines << "<details#{open_attr}>"
        lines << "<summary><strong>#{group_name}</strong> \u2014 #{group_pct}% covered " \
                 "(#{total_lines} lines across #{file_count} #{file_word})</summary>"
        lines << '' # blank line required for GitHub markdown table rendering

        filtered = filter_files(files)
        table = build_files_table(filtered, branches)
        if table.empty?
          lines << '_No files in this group._'
        else
          lines << table.to_md
          lines << hidden_count_note(files, filtered)
        end

        lines << '' # blank line before closing tag
        lines << '</details>'

        lines.compact.join("\n")
      end

      # ─── Files table ────────────────────────────────────────────────

      def build_files_table(filtered_files, branches)
        headers, aligns = table_columns(branches)
        table = MarkdownPro::TableBuilder.new(headers: headers, aligns: aligns)

        sorted = sort_files(filtered_files)
        capped = cap_rows(sorted)

        capped.each do |file|
          table.add_row(file_row(file, branches))
        end

        table
      end

      def table_columns(branches)
        if branches
          headers = ['Coverage', 'File', 'Lines', 'Missed', 'Missing', 'Branch %', 'Branches', 'Br. missed']
          aligns  = %i[right left right right left right right right]
        else
          headers = %w[Coverage File Lines Missed Missing]
          aligns  = %i[right left right right left]
        end
        [headers, aligns]
      end

      def file_row(file, branches)
        missing = compress_missing(file)
        row = [
          "#{file.covered_percent.round(2)}%",
          escape_markdown(short_filename(file)),
          file.lines_of_code.to_s,
          file.missed_lines.size.to_s,
          escape_markdown(missing)
        ]

        if branches
          bs = file_branch_stats(file)
          if bs && bs[:total].positive?
            br_pct = (bs[:covered].to_f / bs[:total] * 100).round(2)
            row += ["#{br_pct}%", bs[:total].to_s, bs[:missed].to_s]
          else
            row += ["\u2014", '0', '0']
          end
        end

        row
      end

      # ─── Sorting & filtering ────────────────────────────────────────

      def sort_files(files)
        case Config.sort
        when :path
          files.sort_by(&:filename)
        else # :coverage (default) — worst first
          files.sort_by(&:covered_percent)
        end
      end

      def filter_files(files)
        return files if Config.show_covered

        files.reject { |f| f.covered_percent >= 100.0 }
      end

      def cap_rows(files)
        max = Config.max_rows
        return files if max.nil?

        files.first(max)
      end

      def hidden_count_note(all_files, filtered_files)
        max = Config.max_rows
        return nil if max.nil?

        hidden = filtered_files.size - max
        return nil if hidden <= 0

        fully_covered = all_files.count { |f| f.covered_percent >= 100.0 }
        parts = []
        parts << "#{hidden} file(s) not shown" if hidden.positive?
        parts << "#{fully_covered} file(s) with 100% coverage" if fully_covered.positive? && !Config.show_covered
        "\n_#{parts.join(', ')}_"
      end

      # ─── Missing lines ─────────────────────────────────────────────

      def compress_missing(file)
        line_numbers = file.missed_lines.map(&:line_number)
        compressed = MarkdownPro::LineRanges.compress(line_numbers)
        truncate_missing(compressed)
      end

      def truncate_missing(str)
        max = Config.max_missing_chars
        return str if max.nil? || str.length <= max

        "#{str[0, max]}\u2026"
      end

      # ─── Branch coverage helpers ────────────────────────────────────

      def branches_enabled?(result)
        return false unless Config.show_branch_coverage

        result.respond_to?(:total_branches) &&
          result.total_branches.is_a?(Integer) &&
          result.total_branches.positive?
      end

      def branch_stats(result)
        return nil unless branches_enabled?(result)

        {
          total: result.total_branches,
          covered: result.covered_branches,
          missed: result.missed_branches
        }
      end

      def file_branch_stats(file)
        return nil unless file.respond_to?(:total_branches)

        total = file.total_branches
        covered = file.covered_branches
        missed = file.missed_branches
        return nil unless total.is_a?(Integer)

        { total: total, covered: covered, missed: missed }
      end

      # ─── Utilities ──────────────────────────────────────────────────

      def short_filename(file)
        file.filename.sub("#{SimpleCov.root}/", '')
      end

      def escape_markdown(str)
        str.gsub('\\', '\\\\\\\\')
           .gsub('|', '\\|')
           .gsub('[', '\\[')
           .gsub(']', '\\]')
           .gsub('`', '\\`')
      end

      def write_file(output)
        base = File.expand_path(SimpleCov.coverage_path)
        path = File.expand_path(Config.output_filename, base)

        unless path.start_with?("#{base}/") || path == base
          raise ArgumentError, "output_filename must not escape the coverage directory: #{Config.output_filename}"
        end

        FileUtils.mkdir_p(File.dirname(path))
        File.write(path, output)
        puts "Markdown coverage report saved to #{Config.output_filename}" unless Config.print_to_stdout
      end
    end
  end
end
