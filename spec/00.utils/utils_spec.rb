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

end

