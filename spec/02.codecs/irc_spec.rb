require_relative "../../lib/beerbot/02.codecs/irc"
require 'pp'

# http://www.mirc.org/mishbox/reference/rawhelp3.htm#raw353

describe "IRC codec",:irc => true do

  IRC = BeerBot::Codecs::IRC
  Message = BeerBot::Codecs::IRC::IRCMessage

  samples = {
    :quit => [
      # QUIT always seems to use trailing, unlike PART which seems to
      # vary.
      ":thursday!~bevan@172.17.217.13 QUIT :Quit: Leaving.\r\n",
      # But throw some params in anyway...
      ":thursday!~bevan@172.17.217.13 QUIT foo bar :Quit: Leaving.\r\n",
    ],
    :part => [
      # I get param-based PART on debian irc server...
      ":timprice!~tprice@172.17.217.13 PART #sydney :\r\n",
      # I get trailing on cat server...
      ":timprice!~tprice@172.17.217.13 PART :#sydney\r\n",
    ],
    :invite => [
      ":danb!~danb@127.0.0.1 INVITE beerbot :#chan3\r\n",
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
    :action => [
      ":danb!~danb@localhost.iiNet PRIVMSG #foo :\u0001ACTION does something\u0001"
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

  describe "decode",:decode => true do

    it "should handle PRIVMSG's" do
      event,*args = IRC.decode(samples[:privmsg][0])
      event.should == :msg
      args.should == ['adamr','#sydney','because we have?']
    end
    it "should handle actions" do
      event,*args = IRC.decode(samples[:action][0])
      event.should == :action
      args.should == ['danb','#foo','does something']
    end

    it "should handle 353's (chanlists)" do
      event,*args = IRC.decode(samples[:irc353][0])
      event.should == :chanlist
      args.should == ['#chan1',['foo','bar','baz','danb']]
    end

    it "should handle QUIT's" do
      event,*args = IRC.decode(samples[:quit][0])
      event.should == :quit
      args.should == ['thursday','Quit: Leaving.']

      # Variation 1:
      event,*args = IRC.decode(samples[:quit][1])
      event.should == :quit
      args.should == ['thursday','Quit: Leaving.']
    end

    it "should handle PART's" do
      event,*args = IRC.decode(samples[:part][0])
      event.should == :part
      args.should == ['timprice','#sydney']

      # Variation 1:
      event,*args = IRC.decode(samples[:part][1])
      event.should == :part
      args.should == ['timprice','#sydney']
    end
  
    it "should handle INVITE's" do
      event,*args = IRC.decode(samples[:invite][0])
      event.should == :invite
      args.should == ['#chan3']
    end


  end

  describe "irc utils",:irc => true do
    it "can detect action-based privmsg's" do
      m = IRC.match_action("PRIVMSG foo :\u0001ACTION does something\u0001")
      m.should == "does something"
    end
  end

end
