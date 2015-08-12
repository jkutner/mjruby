class String
  def chars
    ary = []
    (0..size-1).each {|i| ary << self[i] }
    ary
  end

  def start_with?(s)
    self[0..(s.size-1)] == s
  end

  def end_with?(s)
    self[(0-s.size)..-1] == s
  end
end
