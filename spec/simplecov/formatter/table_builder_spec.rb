# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SimpleCov::Formatter::MarkdownPro::TableBuilder do
  it 'generates a markdown table with headers and rows' do
    table = described_class.new(
      headers: %w[Name Score],
      aligns: %i[left right]
    )
    table.add_row(%w[Alice 95])
    table.add_row(%w[Bob 87])

    expected = <<~MD.chomp
      | Name | Score |
      | :-- | --: |
      | Alice | 95 |
      | Bob | 87 |
    MD

    expect(table.to_md).to eq(expected)
  end

  it 'returns empty string with no headers' do
    table = described_class.new(headers: [])
    expect(table.to_md).to eq('')
  end

  it 'reports empty? correctly' do
    table = described_class.new(headers: ['A'], aligns: [:left])
    expect(table).to be_empty

    table.add_row(['x'])
    expect(table).not_to be_empty
  end

  it 'defaults alignment to left' do
    table = described_class.new(headers: %w[A B])
    table.add_row(%w[1 2])

    expect(table.to_md).to include(':--')
  end
end
