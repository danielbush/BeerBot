require_relative "../../lib/00.utils/world/World"
require 'pp'

World = ::BeerBot::Utils::World

describe "world" do

  it "should join channels" do
    w = World.new('test','mynick')
    w.join('user1','chan1')
    w.user('user1')[:channels].member?('chan1').should eq(true)
  end

  it "should change nicks" do
    w = World.new('test','mynick')
    w.join('user1','chan1')
    w.join('user1','chan2')
    w.user('user1')[:channels].to_a.sort.should eq(['chan1','chan2'])
    w.join('user2','chan1')
    w.nick('user1','user1a')
    w.user('user1').should eq(nil)
    w.user('user1a')[:channels].to_a.sort.should eq(['chan1','chan2'])
  end

  it "should part channels" do
    w = World.new('test','mynick')
    w.join('user1','chan1')
    w.join('user1','chan2')
    w.part('user1','chan1')
    w.user('user1')[:channels].member?('chan1').should eq(false)
    w.user('user1')[:channels].member?('chan2').should eq(true)
  end
end
