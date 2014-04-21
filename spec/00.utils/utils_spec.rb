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

