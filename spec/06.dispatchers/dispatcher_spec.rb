require_relative "../../lib/06.dispatchers/irc.rb"
require 'pp'

describe "dispatchers" do

  class MockBot
    def cmd msg,**kargs
      p 'cmd'
    end
    def hear msg,**kargs
      p 'hear'
    end
    def help arr,**kargs
      p 'help'
    end
  end

  describe "irc" do

    Dispatchers = BeerBot::Dispatchers
    IRCDispatcher = BeerBot::Dispatchers::IRCDispatcher


    before(:each) {
      @bot = MockBot.new
      @dispatcher = IRCDispatcher.new(@bot,'beerbot')
    }

    it "should dispatch valid IRCMessage instances" do
      @dispatcher = IRCDispatcher.new(@bot,'beerbot') {|event,*args|
        case event
        when :nick
          [event,*args]
        when :privmsg
          [event,*args]
        end
      }
      # @dispatcher = Dispatchers.make_irc(@bot,'beerbot',&handle)
      response = @dispatcher.receive(":tom!~tom@2404:130::1000:abc:4abc:fabc:fabc NICK :tom_is_away\r\n")
      response.should == [:nick,'tom','tom_is_away']
      response = @dispatcher.receive(":adamr!~adam@172.17.217.13 PRIVMSG #sydney :because we have?\r\n")
      response.should == [:privmsg,'adamr','#sydney','because we have?']
      
    end

  end
end
