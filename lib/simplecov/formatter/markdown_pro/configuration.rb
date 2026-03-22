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
        VALID_SORT_OPTIONS = %i[coverage path].freeze

        # Defines a configuration option with a default value and optional validation.
        def self.option(name, default:, &validator)
          ivar = :"@#{name}"

          define_singleton_method(name) do
            instance_variable_defined?(ivar) ? instance_variable_get(ivar) : default
          end

          define_singleton_method(:"#{name}=") do |value|
            validator&.call(value)
            instance_variable_set(ivar, value)
          end
        end

        # Where to write the report file. Relative to SimpleCov.coverage_path.
        # Set to nil to skip file output (format returns the string only).
        option :output_filename, default: 'coverage.md' do |v|
          next if v.nil?

          raise ArgumentError, 'output_filename must be a String' unless v.is_a?(String)
          raise ArgumentError, 'output_filename must not be empty' if v.empty?
          raise ArgumentError, "output_filename must not contain '..'" if v.include?('..')
        end

        # Also print report to $stdout (useful in CI logs).
        option :print_to_stdout, default: false

        # Maximum number of files to display per group.
        # nil means show all files.
        option :max_rows, default: nil do |v|
          next if v.nil?

          raise ArgumentError, 'max_rows must be a positive Integer' unless v.is_a?(Integer) && v.positive?
        end

        # Maximum characters for the "Missing" column before truncation.
        # nil means no limit.
        option :max_missing_chars, default: nil do |v|
          next if v.nil?

          raise ArgumentError, 'max_missing_chars must be a positive Integer' unless v.is_a?(Integer) && v.positive?
        end

        # Show files that have 100% coverage in the tables.
        option :show_covered, default: true

        # Sort order for files in each group table.
        # :coverage (worst first, default) or :path (alphabetical).
        option :sort, default: :coverage do |v|
          unless VALID_SORT_OPTIONS.include?(v)
            raise ArgumentError, "sort must be one of: #{VALID_SORT_OPTIONS.join(', ')}"
          end
        end

        # Report title shown as the H1 heading.
        option :title, default: 'Coverage Report' do |v|
          raise ArgumentError, 'title must be a non-empty String' unless v.is_a?(String) && !v.empty?
        end

        # Include branch coverage section when SimpleCov has branch data.
        option :show_branch_coverage, default: true

        # Backwards compatibility alias for the old name.
        def self.missing_len=(value)
          self.max_missing_chars = value.nil? || value <= 0 ? nil : value
        end

        def self.missing_len
          max_missing_chars
        end

        # Reset all options to defaults. Useful in tests.
        def self.reset!
          %i[
            output_filename print_to_stdout max_rows max_missing_chars
            show_covered sort title show_branch_coverage
          ].each do |ivar|
            remove_instance_variable(:"@#{ivar}") if instance_variable_defined?(:"@#{ivar}")
          end
        end
      end
    end
  end
end
