# frozen_string_literal: true

module SimpleCov
  module Formatter
    module MarkdownPro
      # Compresses an array of integers into human-readable ranges.
      #
      #   LineRanges.compress([1, 2, 3, 5, 8, 9, 10])
      #   # => "1-3, 5, 8-10"
      #
      module LineRanges
        module_function

        def compress(numbers)
          return '' if numbers.nil? || numbers.empty?

          sorted = numbers.sort.uniq
          ranges = []
          range_start = sorted.first
          range_end = sorted.first

          sorted.drop(1).each do |n|
            if n == range_end + 1
              range_end = n
            else
              ranges << format_range(range_start, range_end)
              range_start = n
              range_end = n
            end
          end
          ranges << format_range(range_start, range_end)

          ranges.join(', ')
        end

        def format_range(range_start, range_end)
          range_start == range_end ? range_start.to_s : "#{range_start}-#{range_end}"
        end
        private_class_method :format_range
      end
    end
  end
end
