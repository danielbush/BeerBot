
require_relative '../facts.rb'
Facts = ::BeerBot::Modules::Facts

# Mock out what we expect from ::FactsDb.
#
# This allows us to test Facts.

class MockDB
  attr_accessor :terms
  def initialize
    @terms = []
  end
  def method_missing method,*args,**kargs
    case method
    when :add
      [:add,*args]
    when :get_mode
      nil
    when :term
      @terms.push([method,[*args],kargs])
      ['entry 1','entry 2']
    else
      [method,*args]
    end
  end
end

describe "Facts module" do

  before(:each) {
    @db = MockDB.new
    Facts.db = @db
  }

  describe "mockdb" do
    it "should handle arguments" do
      @db.foo(1,2,3).should == [:foo,1,2,3]
    end
  end

  describe "cmd" do

    it "should reply to 'to' if :me is false, else 'from'" do
      r1 = Facts.cmd('foo',from:'from',to:'to',me:true)
      r2 = Facts.cmd('foo',from:'from',to:'to',me:false)
      r1[0][:to].should == 'from'
      r2[0][:to].should == 'to'
    end

    it "should handle ',term'" do
      r = Facts.cmd('foo',from:'from',to:'to',me:true)
      r[1][:msg].should == "[0] entry 1"
      r[2][:msg].should == "[1] entry 2"
    end

    it "should handle ',term n'"
    it "should handle interpolation (,,)"

    it "should handle ',term is:'"
    it "should handle ',term is also:'"

    it "should handle ',forget term'"
    it "should handle ',forget term m'"

    it "should handle ',term swap m n'"
    it "should handle ',term m before n'"

    it "should handle ',term?'"

    it "should handle ',term <mode>'"
    it "should handle ',term m s///'"

    describe "param expansion" do
      it "should substitute" do
        puts "\n--------\n"
        def @db.term *args,**kargs
          ["::1 ::2 ::from ::unk|::1 ::unk2 ::3|::1"]
        end
        def @db.get_mode *args,**kargs
          'reply'  # so param expansion will work
        end
        r = Facts.cmd('foo arg1 arg2',from:'from1',to:'to1',me:true)
        r.size.should == 1
        reply = r[0]
        reply[:msg].should == "arg1 arg2 from1 arg1 ::unk2 arg1"
      end
    end

  end

end
