# frozen_string_literal: true

module SimpleCov
  module Formatter
    module MarkdownPro
      # Configuration object for MarkdownProFormatter.
      #
      # All options can be set via class-level accessors:
      #
      #   SimpleCov::Formatter::MarkdownPro::Configuration.output_filename = "coverage.md"
      #   SimpleCov::Formatter::MarkdownPro::Configuration.max_rows = 20
      #
      # Or via the block DSL:
      #
      #   SimpleCov::Formatter::MarkdownProFormatter.configure do |config|
      #     config.output_filename = "coverage.md"
      #     config.max_rows = 20
      #   end
      #
      class Configuration
        class << self
          # Where to write the report file. Relative to SimpleCov.coverage_path.
          # Set to nil to skip file output (format returns the string only).
          attr_writer :output_filename

          def output_filename
            defined?(@output_filename) ? @output_filename : "coverage.md"
          end

          # Also print report to $stdout (useful in CI logs).
          attr_writer :print_to_stdout

          def print_to_stdout
            defined?(@print_to_stdout) ? @print_to_stdout : false
          end

          # Maximum number of files to display per group.
          # nil or -1 means show all files.
          attr_writer :max_rows

          def max_rows
            defined?(@max_rows) ? @max_rows : nil
          end

          # Maximum characters for the "Missing" column before truncation.
          # 0 or nil means no limit.
          attr_writer :missing_len

          def missing_len
            defined?(@missing_len) ? @missing_len : 0
          end

          # Show files that have 100% coverage in the tables.
          attr_writer :show_covered

          def show_covered
            defined?(@show_covered) ? @show_covered : true
          end

          # Sort order for files in each group table.
          # :coverage (worst first, default) or :path (alphabetical).
          attr_writer :sort

          def sort
            defined?(@sort) ? @sort : :coverage
          end

          # Report title shown as the H1 heading.
          attr_writer :title

          def title
            defined?(@title) ? @title : "Coverage Report"
          end

          # Include branch coverage section when SimpleCov has branch data.
          attr_writer :show_branch_coverage

          def show_branch_coverage
            defined?(@show_branch_coverage) ? @show_branch_coverage : true
          end

          # Reset all options to defaults. Useful in tests.
          def reset!
            %i[
              output_filename print_to_stdout max_rows missing_len
              show_covered sort title show_branch_coverage
            ].each do |ivar|
              remove_instance_variable(:"@#{ivar}") if instance_variable_defined?(:"@#{ivar}")
            end
          end
        end
      end
    end
  end
end
