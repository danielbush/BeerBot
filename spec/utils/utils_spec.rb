require File.dirname(__FILE__)+"/../../lib/utils/utils.rb"
require 'pp'
require 'byebug'
Utils = BeerBot::Utils

describe "general utils", :utils => true do

  describe "scan param" do
    it "should handle single :: params" do
      m = Utils.scan_param("bar ::foo ::baz")
      m.should == [['::foo',['foo']],['::baz',['baz']]]
    end
    it "should handle numeric :: params" do
      m = Utils.scan_param("bar ::1 ::baz")
      m.should == [['::1',[1]],['::baz',['baz']]]
    end
    it "should handle pipe delimited params" do
      m = Utils.scan_param("bar ::1|::baz")
      m.should == [['::1|::baz',[1,'baz']]]
      m = Utils.scan_param("bar ::1|::baz|::foo")
      m.should == [['::1|::baz|::foo',[1,'baz','foo']]]
      m = Utils.scan_param("bar ::1|::baz|::3")
      m.should == [['::1|::baz|::3',[1,'baz',3]]]
    end
  end

  describe "num expand" do
    it "should expand numeric parameters" do
      Utils.expand("::1 => ::2",'a','b')[0].should == "a => b"
    end
    it "should handle repeated numeric parameters" do
      Utils.expand("::1 => ::1",'a','b')[0].should == "a => a"
    end
    it "should tell not sub missing parameters by default" do
      Utils.expand("::1 => ::3",'a','b')[0].should == "a => ::3"
    end
    it "should set err with missing parameters if pass it in" do
      msg,err = Utils.expand("::1 => ::3",'a','b')
      err.should == [3]
    end
  end

  describe "key expand" do
    it "should expand key parameters" do
      Utils.expand("::foo => ::bar",foo:'a',bar:'b')[0].should == "a => b"
    end
  end

  describe "multi expand" do
    it "should expand large items first" do
      #byebug
      Utils.expand("::1 ::foo ::bar|::1",'a',foo:'b')[0].should == "a b a"
    end
  end

end

