class Maths
  attr_accessor :start, :operations, :result

  def initialize(start, &block)
    self.start = start ||= 0
    self.operations = []
    self.result = start

    instance_eval &block
  end

  def add(value)
    self.operations << ['+', value]
    self.result = self.result + value
  end

  def minus(value)
    self.operations << ['-', value]
    self.result = self.result - value
  end

  def multiply(value)
    self.operations << ['*', value]
    self.result = self.result * value
  end

  def to_s
    operations_string = ""
    operations.each do |o|
      (operations_string << " #{o[0]} #{o[1]}")
    end
    "Calculation result: #{start}#{operations_string} = #{result}"
  end
end

maths = Maths.new(2) do
  add 3
  add 1
  minus 1
  minus 1
  multiply 2
end

puts maths.to_s