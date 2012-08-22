require 'test_helper'

class ApplicationHelperTest < ActionView::TestCase
  test "should show date" do
    date = Date.today
    assert_equal date.strftime("%b %d"), simple_date(date)
  end
  
  test "should show full date from last year" do
    date = Date.today - 1.year
    assert_equal date.strftime("%b %d, %Y"), simple_date(date)
  end
  
  test "should show time" do
    time = Time.now
    assert_equal time.strftime("at %I:%M %p"), simple_time(time)
  end
  
  test "should show full time from yesterday" do
    time = Time.now - 1.day
    assert_equal time.strftime("on %b %d, %Y at %I:%M %p"), simple_time(time)
  end
  
  test "should show sort field helper" do
    assert sort_field_helper("first_name DESC", "last_name", "First Name").kind_of?(String)
  end
  
  test "should show sort field helper with same order" do
    assert sort_field_helper("first_name", "first_name", "First Name").kind_of?(String)
  end
  
  test "should show recent activity" do
    assert recent_activity(nil).kind_of?(String)
    assert recent_activity('').kind_of?(String)
    assert recent_activity(Time.now).kind_of?(String)
    assert recent_activity(Time.now - 1.day).kind_of?(String)
    assert recent_activity(Time.now - 2.days).kind_of?(String)
    assert recent_activity(Time.now - 1.week).kind_of?(String)
    assert recent_activity(Time.now - 1.month).kind_of?(String)
    assert recent_activity(Time.now - 1.year).kind_of?(String)
    assert recent_activity(Time.now - 2.year).kind_of?(String)
  end
  
end