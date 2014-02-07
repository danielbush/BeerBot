require File.dirname(__FILE__)+"/../lib/protocols/irc"
require 'pp'

describe "IRC parsing" do

  describe "main irc regex parser",:parse => true do
    it "should parse prefixed and unprefixed irc strings" do

      IRC = BeerBot::Protocol::IRC::IRCMessage

      samples = [
        ":thursday!~bevan@172.17.217.13 QUIT :Quit: Leaving.\r\n",
        ":tom!~tom@2404:130::1000:222:4dff:fe56:f81d NICK :tom_is_away\r\n",
        ":adamr!~adam@172.17.217.13 PRIVMSG #sydney :because we have?\r\n",
        ":timprice!~tprice@172.17.217.13 PART :#sydney\r\n",
        ":irc.localhost 020 * :Please wait while we process your connection.\r\n",
        ":thursday!~bevan@172.17.217.13 QUIT foo bar :Quit: Leaving.\r\n",
        # Colons in this example:
        ":danb!~danb@localhost.iiNet PRIVMSG #chan1 :,test1 is also:* hugs ::1\r\n",
      ]

      IRC.new(samples[0])[:prefix][:nick].should eq('thursday')
      IRC.new(samples[0])[:prefix][:user].should eq('~bevan')
      IRC.new(samples[0])[:command].should eq('QUIT')
      IRC.new(samples[0]).prefix?.should eq(true)
      IRC.new(samples[0]).user_prefix?.should eq(true)

      IRC.new(samples[1])[:prefix][:nick].should eq('tom')
      IRC.new(samples[1])[:prefix][:host].should eq('2404:130::1000:222:4dff:fe56:f81d')
      IRC.new(samples[1])[:command].should eq('NICK')
      IRC.new(samples[1]).prefix?.should eq(true)
      IRC.new(samples[1]).user_prefix?.should eq(true)

      IRC.new(samples[2])[:command].should eq('PRIVMSG')
      IRC.new(samples[2])[:params].should eq(['#sydney'])
      IRC.new(samples[2])[:trailing].should eq('because we have?')

      IRC.new(samples[4])[:prefix][:nick].should eq(nil)
      IRC.new(samples[4])[:prefix][:host].should eq('irc.localhost')
      IRC.new(samples[4]).prefix?.should eq(true)
      IRC.new(samples[4]).user_prefix?.should eq(false)
      IRC.new(samples[4])[:prefix][:user].should eq(nil)

      IRC.new(samples[5])[:params].should eq(['foo','bar'])

      IRC.new(samples[6])[:command].should == 'PRIVMSG'
      IRC.new(samples[6])[:params].should == ['#chan1']
      IRC.new(samples[6])[:trailing].should == ",test1 is also:* hugs ::1"

      # No prefix
      samples = [
        # Command with no prefix.
        "PING :irc.dmz.wgtn.cat-it.co.nz\r\n",
        "PING foo bar :irc.dmz.wgtn.cat-it.co.nz\r\n",
      ]
      IRC.new(samples[0])[:command].should eq('PING')
      IRC.new(samples[0]).prefix?.should eq(false)
      IRC.new(samples[0]).user_prefix?.should eq(false)
      IRC.new(samples[0])[:trailing].should eq('irc.dmz.wgtn.cat-it.co.nz')
      IRC.new(samples[1])[:command].should eq('PING')
      IRC.new(samples[1])[:params].should eq(['foo','bar'])

    end
  end

  describe "make_prefix_parser" do

    it "should return message without the prefix" do

      fn = BeerBot::Protocol.make_prefix_parser(',')
      fn.call(',hello').should eq('hello')
      fn.call(',hello ').should eq('hello')

      fn = BeerBot::Protocol.make_prefix_parser('Beerbot')
      fn.call('Beerbot: hello').should eq('hello')
      fn.call('Beerbot hello').should eq('hello')
    end

  end

end
