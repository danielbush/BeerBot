require_relative "../../lib/BeerBot/00.utils/utils.rb"
require 'pp'
require 'byebug'

Utils = BeerBot::Utils

describe "general utils", :utils => true do

  describe "make_prefix_parser" do

    it "should return message without the prefix" do
      fn = BeerBot::Utils.make_prefix_parser(',')
      fn.call(',hello').should eq('hello')
      fn.call(',hello ').should eq('hello')

      fn = BeerBot::Utils.make_prefix_parser('Beerbot')
      fn.call('Beerbot: hello').should eq('hello')
      fn.call('Beerbot hello').should eq('hello')
    end

  end

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
    it "should ignore non-text characters in params" do
      m = Utils.scan_param("bar ::1,")
      m.should == [['::1',[1]]]
    end
    it "should handle blank ('::') param" do
      m = Utils.scan_param("bar :: ::baz")
      m.should == [['::',['']],['::baz',['baz']]]
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

  describe "optional expand" do

    it "should expand large items first" do
      Utils.expand("::1 ::foo ::bar|::1",'a',foo:'b')[0].should == "a b a"
    end

    it "should not set err with missing num parameter is substitued by other optional" do
      msg,err = Utils.expand("::2|::foo",'a',foo:'b')
      msg.should == "b"
      err.should == []
    end

  end

  describe "blank expand" do
    it "should expand '::' to nothing" do
      msg,err = Utils.expand("foo :: bar")
      msg.should == "foo bar"
    end
    it "can be used in an optional expand where all other args are not found" do
      #byebug
      msg,err = Utils.expand("foo ::foo|::1|:: bar")
      msg.should == "foo bar"
      err.should == []
    end
  end

  describe "sed extraction", :sed => true do
    s = [
      "s/test/foo/",
      "s#test#foo#",
      "s/test/foo/g",
      "s/test/foo/abc",
      "s/test/foo/abc ",
      ",test 1 s/test/foo/g",
      ",test 1 s#test#foo#g"
    ]
    s.map{|ss| Utils.sed_regex.match(ss)[:sep]}.should ==
      ['/','#','/','/','/','/','#']
    s.map{|ss| Utils.sed_regex.match(ss)[:pattern]}.should ==
      7.times.inject([]){|s,v| s << 'test'}
    s.map{|ss| Utils.sed_regex.match(ss)[:replacement]}.should ==
      7.times.inject([]){|s,v| s << 'foo'}
  end

end

