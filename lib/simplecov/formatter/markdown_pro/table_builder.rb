# frozen_string_literal: true

module SimpleCov
  module Formatter
    module MarkdownPro
      # Builds a Markdown table from rows of data.
      #
      #   table = TableBuilder.new(
      #     headers: ["Coverage", "File", "Lines", "Missed", "Missing"],
      #     aligns:  [:right,     :left,  :right,  :right,   :left]
      #   )
      #   table.add_row(["95.0%", "app/models/user.rb", "40", "2", "12, 15"])
      #   table.to_md
      #
      class TableBuilder
        ALIGN_MAP = {
          left: ":--",
          right: "--:",
          center: ":-:"
        }.freeze

        def initialize(headers:, aligns: nil)
          @headers = headers
          @aligns = aligns || Array.new(headers.size, :left)
          @rows = []
        end

        def add_row(values)
          @rows << values.map(&:to_s)
          self
        end

        def to_md
          return "" if @headers.empty?

          lines = []
          lines << md_row(@headers)
          lines << md_row(@aligns.map { |a| ALIGN_MAP.fetch(a, "--") })
          @rows.each { |row| lines << md_row(row) }
          lines.join("\n")
        end

        def empty?
          @rows.empty?
        end

        private

        def md_row(cells)
          "| #{cells.join(" | ")} |"
        end
      end
    end
  end
end
