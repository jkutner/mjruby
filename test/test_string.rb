class TestString < MTest::Unit::TestCase

  def test_chars
    assert_equal ['a', 'b', 'c', 'd'], "abcd".chars
  end

  def test_start_with
    assert_equal true, "abcd".start_with?("abc")
    assert_equal false, "abcd".start_with?("bcd")
  end

  def test_end_with
    assert_equal false, "abcd".end_with?("abc")
    assert_equal true, "abcd".end_with?("bcd")
  end
end

MTest::Unit.new.run
