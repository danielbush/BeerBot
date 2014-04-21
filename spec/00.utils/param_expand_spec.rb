require_relative "../../lib/BeerBot/00.utils/param_expand.rb"
require 'pp'
require 'byebug'

ParamExpand = BeerBot::Utils::ParamExpand

describe "param expansion" do

  describe "scan param" do

    it "should handle single :: params" do
      m = ParamExpand.scan_param("bar ::foo ::baz")
      m.should == [['::foo',['foo']],['::baz',['baz']]]
      m = ParamExpand.scan_param("bar ::unk2")
      m.should == [['::unk2',['unk2']]]
    end

    it "should handle numeric :: params" do
      m = ParamExpand.scan_param("bar ::1 ::baz")
      m.should == [['::1',[1]],['::baz',['baz']]]
    end

    it "should handle pipe delimited params" do
      m = ParamExpand.scan_param("bar ::1|::baz")
      m.should == [['::1|::baz',[1,'baz']]]
      m = ParamExpand.scan_param("bar ::1|::baz|::foo")
      m.should == [['::1|::baz|::foo',[1,'baz','foo']]]
      m = ParamExpand.scan_param("bar ::1|::baz|::3")
      m.should == [['::1|::baz|::3',[1,'baz',3]]]
    end

    it "should ignore non-text characters in params" do
      m = ParamExpand.scan_param("bar ::1,")
      m.should == [['::1',[1]]]
    end

    it "should handle blank ('::') param" do
      m = ParamExpand.scan_param("bar :: ::baz")
      m.should == [['::',['']],['::baz',['baz']]]
    end

  end

  describe "num expand" do

    it "should expand numeric parameters" do
      ParamExpand.expand("::1 => ::2",'a','b')[0].should == "a => b"
    end

    it "should handle repeated numeric parameters" do
      ParamExpand.expand("::1 => ::1",'a','b')[0].should == "a => a"
    end

    it "should tell not sub missing parameters by default" do
      ParamExpand.expand("::1 => ::3",'a','b')[0].should == "a => ::3"
    end

    it "should set err with missing parameters if pass it in" do
      msg,err = ParamExpand.expand("::1 => ::3",'a','b')
      err.should == [3]
    end

  end

  describe "key expand" do

    it "should expand key parameters" do
      ParamExpand.expand("::foo => ::bar",foo:'a',bar:'b')[0].should == "a => b"
    end

  end

  describe "optional expand" do

    it "should expand large items first" do
      ParamExpand.expand("::1 ::foo ::bar|::1",'a',foo:'b')[0].should == "a b a"
    end

    it "should not set err with missing num parameter is substitued by other optional" do
      msg,err = ParamExpand.expand("::2|::foo",'a',foo:'b')
      msg.should == "b"
      err.should == []
    end

  end

  describe "blank expand" do

    it "should expand '::' to nothing" do
      msg,err = ParamExpand.expand("foo :: bar")
      msg.should == "foo bar"
    end

    it "can be used in an optional expand where all other args are not found" do
      #byebug
      msg,err = ParamExpand.expand("foo ::foo|::1|:: bar")
      msg.should == "foo bar"
      err.should == []
    end

  end

end
