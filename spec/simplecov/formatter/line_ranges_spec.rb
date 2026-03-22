# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SimpleCov::Formatter::MarkdownPro::LineRanges do
  describe '.compress' do
    it 'returns empty string for nil' do
      expect(described_class.compress(nil)).to eq('')
    end

    it 'returns empty string for empty array' do
      expect(described_class.compress([])).to eq('')
    end

    it 'handles single number' do
      expect(described_class.compress([5])).to eq('5')
    end

    it 'compresses consecutive numbers into ranges' do
      expect(described_class.compress([1, 2, 3])).to eq('1-3')
    end

    it 'handles mix of ranges and singles' do
      expect(described_class.compress([1, 2, 3, 5, 8, 9, 10])).to eq('1-3, 5, 8-10')
    end

    it 'handles non-consecutive numbers' do
      expect(described_class.compress([3, 7, 11])).to eq('3, 7, 11')
    end

    it 'handles unsorted input' do
      expect(described_class.compress([10, 1, 3, 2])).to eq('1-3, 10')
    end

    it 'handles duplicates' do
      expect(described_class.compress([1, 1, 2, 2, 3])).to eq('1-3')
    end
  end
end
