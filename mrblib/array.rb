class Array
  def compact
    select{|x| !x.nil? }
  end
end
