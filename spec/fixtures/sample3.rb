# Sample class with low coverage
class Sample3
  def initialize
    @data = []
  end

  def add(item)
    @data << item
  end

  def remove(item)
    @data.delete(item)
  end

  def clear
    @data.clear
  end

  def size
    @data.size
  end
end
