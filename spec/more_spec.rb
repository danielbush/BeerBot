require File.dirname(__FILE__)+"/../lib/more/more.rb"
require 'pp'

More = ::BeerBot::More

describe "More buffering" do
  it "should buffer" do
    more = More.new
    more.size.should == 4

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
