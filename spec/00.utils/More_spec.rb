require_relative "../../lib/BeerBot/00.utils/More"
require 'pp'

More = ::BeerBot::Utils::More

describe "More buffering" do
  it "should buffer" do
    more = More.new
    more.size.should == 5
    more.size = 4

    a = more.filter([1,2,3,4,5,6],:mine)
    a.should == [1,2,3,4]
    b = more.more(:mine)
    b.should == [5,6]

    a = more.filter([1,2,3],:mine)
    a.should == [1,2,3]
    b = more.more(:mine)
    b.should == []
  end
end
