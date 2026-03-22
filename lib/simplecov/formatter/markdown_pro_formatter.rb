# frozen_string_literal: true

require "simplecov"
require_relative "markdown_pro/version"
require_relative "markdown_pro/configuration"
require_relative "markdown_pro/line_ranges"
require_relative "markdown_pro/table_builder"

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
        sections = []
        sections << build_title
        sections << build_global_summary(result)
        sections << build_branch_summary(result) if show_branches?(result)
        sections << "" # blank line before groups

        result.groups.each do |group_name, files|
          sections << build_group_section(group_name, files, result)
        end

        # If no groups are defined, SimpleCov returns a single "Ungrouped" group
        # only when there are files. Handle edge case of empty results.
        sections.compact.join("\n")
      end

      # ─── Title ───────────────────────────────────────────────────────

      def build_title
        "# #{Config.title}\n"
      end

      # ─── Global summary ─────────────────────────────────────────────

      def build_global_summary(result)
        covered = result.covered_lines
        missed = result.missed_lines
        total = covered + missed
        pct = result.covered_percent.round(2)
        file_count = result.source_files.size

        "**Overall: #{pct}%** — #{covered}/#{total} lines in #{file_count} files"
      end

      # ─── Branch summary ─────────────────────────────────────────────

      def build_branch_summary(result)
        stats = branch_stats(result)
        return nil unless stats

        covered = stats[:covered]
        total = stats[:total]
        pct = total.zero? ? 100.0 : (covered.to_f / total * 100).round(2)

        "**Branch coverage: #{pct}%** — #{covered}/#{total} branches"
      end

      # ─── Group section ──────────────────────────────────────────────

      def build_group_section(group_name, files, result)
        group_pct = files.covered_percent.round(2)
        lines = []
        lines << "## #{group_name} (#{group_pct}%)\n"

        table = build_files_table(files, result)
        if table.empty?
          lines << "_No files in this group._\n"
        else
          lines << table.to_md
          lines << hidden_count_note(files)
          lines << ""
        end

        lines.compact.join("\n")
      end

      # ─── Files table ────────────────────────────────────────────────

      def build_files_table(files, result)
        headers, aligns = table_columns(result)
        table = TableBuilder.new(headers: headers, aligns: aligns)

        sorted = sort_files(files)
        filtered = filter_files(sorted)
        capped = cap_rows(filtered)

        capped.each do |file|
          table.add_row(file_row(file, result))
        end

        table
      end

      def table_columns(result)
        if show_branches?(result)
          headers = ["Coverage", "File", "Lines", "Missed", "Missing", "Branch %", "Branches", "Br. missed"]
          aligns  = [:right,     :left,  :right,  :right,   :left,     :right,     :right,     :right]
        else
          headers = ["Coverage", "File", "Lines", "Missed", "Missing"]
          aligns  = [:right,     :left,  :right,  :right,   :left]
        end
        [headers, aligns]
      end

      def file_row(file, result)
        missing = compress_missing(file)
        row = [
          "#{file.covered_percent.round(2)}%",
          short_filename(file),
          file.lines_of_code.to_s,
          file.missed_lines.size.to_s,
          missing
        ]

        if show_branches?(result)
          bs = file_branch_stats(file)
          if bs && bs[:total] > 0
            br_pct = (bs[:covered].to_f / bs[:total] * 100).round(2)
            row += ["#{br_pct}%", bs[:total].to_s, bs[:missed].to_s]
          else
            row += ["—", "0", "0"]
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
        return files if max.nil? || max < 0

        files.first(max)
      end

      def hidden_count_note(files)
        max = Config.max_rows
        return nil if max.nil? || max < 0

        filtered = Config.show_covered ? files : files.reject { |f| f.covered_percent >= 100.0 }
        hidden = filtered.size - max
        return nil if hidden <= 0

        fully_covered = files.count { |f| f.covered_percent >= 100.0 }
        parts = []
        parts << "#{hidden} file(s) not shown" if hidden > 0
        parts << "#{fully_covered} file(s) with 100% coverage" if fully_covered > 0 && !Config.show_covered
        "\n_#{parts.join(", ")}_"
      end

      # ─── Missing lines ─────────────────────────────────────────────

      def compress_missing(file)
        line_numbers = file.missed_lines.map(&:line_number)
        compressed = MarkdownPro::LineRanges.compress(line_numbers)
        truncate_missing(compressed)
      end

      def truncate_missing(str)
        max = Config.missing_len
        return str if max.nil? || max <= 0 || str.length <= max

        "#{str[0, max]}…"
      end

      # ─── Branch coverage helpers ────────────────────────────────────

      def show_branches?(result)
        return false unless Config.show_branch_coverage

        result.respond_to?(:total_branches) &&
          result.total_branches.is_a?(Integer) &&
          result.total_branches > 0
      rescue StandardError
        false
      end

      def branch_stats(result)
        return nil unless show_branches?(result)

        {
          total: result.total_branches,
          covered: result.covered_branches,
          missed: result.missed_branches
        }
      rescue StandardError
        nil
      end

      def file_branch_stats(file)
        return nil unless file.respond_to?(:total_branches)

        total = file.total_branches
        covered = file.covered_branches
        missed = file.missed_branches
        return nil unless total.is_a?(Integer)

        { total: total, covered: covered, missed: missed }
      rescue StandardError
        nil
      end

      # ─── Utilities ──────────────────────────────────────────────────

      def short_filename(file)
        file.filename.sub("#{SimpleCov.root}/", "")
      end

      def write_file(output)
        path = File.join(SimpleCov.coverage_path, Config.output_filename)
        File.write(path, output)
        puts "Markdown coverage report saved to #{path}" unless Config.print_to_stdout
      end
    end
  end
end
