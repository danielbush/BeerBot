require File.dirname(__FILE__)+"/../lib/more/more.rb"
require 'pp'

More = ::BeerBot::More

describe "More buffering" do
  it "should buffer" do
    More.size.should == 4

    a = More.filter([1,2,3,4,5,6],:mine)
    a.should == [1,2,3,4]
    b = More.more(:mine)
    b.should == [5,6]

    a = More.filter([1,2,3],:mine)
    a.should == [1,2,3]
    b = More.more(:mine)
    b.should == []
  end
end
