require_relative "../../lib/BeerBot/00.utils/world/World"
require 'pp'

World = ::BeerBot::Utils::World

describe "world" do

  it "should join channels" do
    w = World.new('mynick')
    w.join('user1','chan1')
    w[:users]['user1'][:channels].member?('chan1').should == true
  end

  it "should change nicks" do
    w = World.new('mynick')
    w.join('user1','chan1')
    w.join('user1','chan2')
    w[:users]['user1'][:channels].to_a.sort.should == ['chan1','chan2']
    w[:channels].each_pair{|_,chan|
      chan[:users].member?('user1').should == true
      chan[:users].member?('user1a').should == false
    }

    w.nick('user1','user1a')

    w[:users].has_key?('user1').should == false
    w[:users]['user1a'][:channels].to_a.sort.should == ['chan1','chan2']
    w[:channels].each_pair{|_,chan|
      chan[:users].member?('user1').should == false
      chan[:users].member?('user1a').should == true
    }
  end

  it "should part channels" do
    w = World.new('mynick')
    w.join('user1','chan1')
    w.join('user1','chan2')
    w[:users]['user1'][:channels].member?('chan1').should == true
    w[:users]['user1'][:channels].member?('chan2').should == true
    w.part('user1','chan1')
    w[:users]['user1'][:channels].member?('chan1').should == false
    w[:users]['user1'][:channels].member?('chan2').should == true
  end

  it "should quit users" do
    w = World.new('mynick')
    w.join('user1','chan1')
    w.join('user1','chan2')
    w[:channels].select{|name,chan| chan[:users].member?('user1')}
      .map{|name,_| name}.sort.should == ['chan1','chan2']
    w.quit('user1')
    w[:channels].select{|name,chan| chan[:users].member?('user1')}
      .map{|name,_| name}.sort.should == []
  end

end
