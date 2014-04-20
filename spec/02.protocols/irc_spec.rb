require_relative "../../lib/BeerBot/02.protocols/irc"
require 'pp'

# http://www.mirc.org/mishbox/reference/rawhelp3.htm#raw353

describe "IRC parsing" do

  IRC = BeerBot::Protocol::IRC
  Message = BeerBot::Protocol::IRC::IRCMessage

  samples = {
    :quit => [
      ":thursday!~bevan@172.17.217.13 QUIT :Quit: Leaving.\r\n",
      ":thursday!~bevan@172.17.217.13 QUIT foo bar :Quit: Leaving.\r\n",
    ],
    :nick => [
      # ip6
      ":tom!~tom@2404:130::1000:222:4dff:fe56:f81d NICK :tom_is_away\r\n",
      ":danb!~danb@localhost.iiNet NICK :foo\r\n",
    ],
    :privmsg => [
      ":adamr!~adam@172.17.217.13 PRIVMSG #sydney :because we have?\r\n",
      # Colons in this example:
      ":danb!~danb@localhost.iiNet PRIVMSG #chan1 :,test1 is also:* hugs ::1\r\n",
    ],
    :part => [
      ":timprice!~tprice@172.17.217.13 PART :#sydney\r\n",
    ],
    :misc => [
      ":irc.localhost 020 * :Please wait while we process your connection.\r\n",
    ],
    :join => [
      ":danb!~danb@localhost.iiNet JOIN :#chan1\r\n",
    ],
    :irc353 => [
      ":danb!~danb@localhost.iiNet 353 danb = #chan1 :foo bar baz danb\r\n",
    ],
    # No prefix...
    :ping => [
      "PING :irc.dmz.wgtn.cat-it.co.nz\r\n",
      "PING foo bar :irc.dmz.wgtn.cat-it.co.nz\r\n",
    ],
  }

  describe "IRCMessage",:parse => true do

    it "should parse prefixed and unprefixed irc strings" do

      Message.new(samples[:quit][0])[:prefix][:nick].should eq('thursday')
      Message.new(samples[:quit][0])[:prefix][:user].should eq('~bevan')
      Message.new(samples[:quit][0])[:command].should eq('QUIT')
      Message.new(samples[:quit][0]).prefix?.should eq(true)
      Message.new(samples[:quit][0]).user_prefix?.should eq(true)
      Message.new(samples[:quit][1])[:params].should eq(['foo','bar'])

      Message.new(samples[:nick][0])[:prefix][:nick].should eq('tom')
      Message.new(samples[:nick][0])[:prefix][:host].should eq('2404:130::1000:222:4dff:fe56:f81d')
      Message.new(samples[:nick][0])[:command].should eq('NICK')
      Message.new(samples[:nick][0]).prefix?.should eq(true)
      Message.new(samples[:nick][0]).user_prefix?.should eq(true)

      Message.new(samples[:privmsg][0])[:command].should eq('PRIVMSG')
      Message.new(samples[:privmsg][0])[:params].should eq(['#sydney'])
      Message.new(samples[:privmsg][0])[:trailing].should eq('because we have?')
      Message.new(samples[:privmsg][1])[:command].should == 'PRIVMSG'
      Message.new(samples[:privmsg][1])[:params].should == ['#chan1']
      Message.new(samples[:privmsg][1])[:trailing].should == ",test1 is also:* hugs ::1"

      Message.new(samples[:misc][0])[:prefix][:nick].should eq(nil)
      Message.new(samples[:misc][0])[:prefix][:host].should eq('irc.localhost')
      Message.new(samples[:misc][0]).prefix?.should eq(true)
      Message.new(samples[:misc][0]).user_prefix?.should eq(false)
      Message.new(samples[:misc][0])[:prefix][:user].should eq(nil)

      Message.new(samples[:ping][0])[:command].should eq('PING')
      Message.new(samples[:ping][0]).prefix?.should eq(false)
      Message.new(samples[:ping][0]).user_prefix?.should eq(false)
      Message.new(samples[:ping][0])[:trailing].should eq('irc.dmz.wgtn.cat-it.co.nz')
      Message.new(samples[:ping][1])[:command].should eq('PING')
      Message.new(samples[:ping][1])[:params].should eq(['foo','bar'])

    end
  end

  describe "parse",:parse => true do

    it "should handle privmsg's" do
      result = []
      IRC.parse(samples[:privmsg][0]) {|event,*args|
          result.push(args) if event == :msg
      }
      result[0].should == ['adamr','#sydney','because we have?']
    end

    it "should handle 353's" do
      result = []
      IRC.parse(samples[:irc353][0]) {|event,*args|
        result.push(args) if event == :chanlist
      }
      result[0].should == ['#chan1',['foo','bar','baz','danb']]
    end
  
  end

end
