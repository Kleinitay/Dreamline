# == Schema Information
#
# Table name: time_segments
#
#  id         :integer(4)      not null, primary key
#  taggee_id  :integer(4)
#  begin      :integer(4)
#  end        :integer(4)
#  created_at :datetime
#  updated_at :datetime
#

require 'test_helper'

class TimeSegmentTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "the truth" do
    assert true
  end
end
