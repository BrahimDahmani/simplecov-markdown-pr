# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SimpleCov::Formatter::MarkdownPro::Configuration do
  after { described_class.reset! }

  it 'has sensible defaults' do
    expect(described_class.output_filename).to eq('coverage.md')
    expect(described_class.print_to_stdout).to eq(false)
    expect(described_class.max_rows).to be_nil
    expect(described_class.max_missing_chars).to be_nil
    expect(described_class.show_covered).to eq(true)
    expect(described_class.sort).to eq(:coverage)
    expect(described_class.title).to eq('Coverage Report')
    expect(described_class.show_branch_coverage).to eq(true)
  end

  it 'allows overriding each option' do
    described_class.output_filename = 'custom.md'
    described_class.print_to_stdout = true
    described_class.max_rows = 10
    described_class.max_missing_chars = 50
    described_class.show_covered = false
    described_class.sort = :path
    described_class.title = 'My Report'
    described_class.show_branch_coverage = false

    expect(described_class.output_filename).to eq('custom.md')
    expect(described_class.print_to_stdout).to eq(true)
    expect(described_class.max_rows).to eq(10)
    expect(described_class.max_missing_chars).to eq(50)
    expect(described_class.show_covered).to eq(false)
    expect(described_class.sort).to eq(:path)
    expect(described_class.title).to eq('My Report')
    expect(described_class.show_branch_coverage).to eq(false)
  end

  it 'resets to defaults' do
    described_class.output_filename = 'changed.md'
    described_class.reset!
    expect(described_class.output_filename).to eq('coverage.md')
  end

  describe 'backwards compatibility' do
    it 'supports missing_len= as alias for max_missing_chars' do
      described_class.missing_len = 50
      expect(described_class.max_missing_chars).to eq(50)
    end

    it 'treats missing_len of 0 as nil (unlimited)' do
      described_class.missing_len = 0
      expect(described_class.max_missing_chars).to be_nil
    end

    it 'reads missing_len from max_missing_chars' do
      described_class.max_missing_chars = 30
      expect(described_class.missing_len).to eq(30)
    end
  end

  describe 'validation' do
    it 'rejects invalid sort values' do
      expect { described_class.sort = :invalid }.to raise_error(ArgumentError, /sort must be one of/)
    end

    it 'rejects negative max_rows' do
      expect { described_class.max_rows = -1 }.to raise_error(ArgumentError, /max_rows must be a positive Integer/)
    end

    it 'rejects zero max_rows' do
      expect { described_class.max_rows = 0 }.to raise_error(ArgumentError, /max_rows must be a positive Integer/)
    end

    it 'rejects negative max_missing_chars' do
      expect do
        described_class.max_missing_chars = -5
      end.to raise_error(ArgumentError, /max_missing_chars must be a positive Integer/)
    end

    it 'rejects empty title' do
      expect { described_class.title = '' }.to raise_error(ArgumentError, /title must be a non-empty String/)
    end

    it 'rejects non-string title' do
      expect { described_class.title = 42 }.to raise_error(ArgumentError, /title must be a non-empty String/)
    end

    it 'rejects output_filename with path traversal' do
      expect do
        described_class.output_filename = '../../evil.md'
      end.to raise_error(ArgumentError, /must not contain '\.\.'/)
    end

    it 'rejects empty output_filename' do
      expect { described_class.output_filename = '' }.to raise_error(ArgumentError, /must not be empty/)
    end

    it 'allows nil output_filename to skip file output' do
      described_class.output_filename = nil
      expect(described_class.output_filename).to be_nil
    end

    it 'allows nil max_rows for unlimited' do
      described_class.max_rows = nil
      expect(described_class.max_rows).to be_nil
    end
  end
end
