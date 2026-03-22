# frozen_string_literal: true

# Sample class with partial coverage
class Sample2
  def initialize
    @value = 'world'
  end

  def shout
    @value.upcase
  end

  def whisper
    @value.downcase
  end
end
