require_relative "../../lib/BeerBot/06.dispatchers/irc.rb"
require 'pp'

describe "dispatchers" do

  IRCDispatcher = BeerBot::Dispatchers::IRCDispatcher

  class MockBot
    attr_accessor :output
    def initialize
      @output = Hash.new{|h,k| h[k] = []}
    end
    def cmd msg,**kargs
      @output[:cmd].push([msg,kargs])
      nil
    end
    def hear msg,**kargs
      @output[:hear].push([msg,kargs])
      nil
    end
    def help arr
      @output[:help].push(arr)
      nil
    end
    def event event,**kargs
      @output[:event].push([event,kargs])
      nil
    end
  end

  describe "irc dispatcher" do

    before(:each) {
      @bot = MockBot.new
      @dispatcher = IRCDispatcher.new(@bot,'beerbot')
    }

    it "should dispatch valid IRCMessage instances" do
      @dispatcher = IRCDispatcher.new(@bot,'beerbot') {|event,*args|
        case event
        when :nick
          [event,*args]
        when :msg
          [event,*args]
        end
      }
      response = @dispatcher.receive(":tom!~tom@2404:130::1000:abc:4abc:fabc:fabc NICK :tom_is_away\r\n")
      response.should == [:nick,'tom','tom_is_away']
      response = @dispatcher.receive(":adamr!~adam@172.17.217.13 PRIVMSG #sydney :because we have?\r\n")
      response.should == [:msg,'adamr','#sydney','because we have?']
      
    end

    it "should handle join events" do
      @dispatcher.receive(":danb!~danb@localhost.iiNet JOIN :#chan1\r\n")
      @bot.output[:event].size.should == 1
      event,kargs = @bot.output[:event][0]
      event.should == :join
      [kargs[:me],kargs[:nick],kargs[:channel]].should == [false,'danb','#chan1']
    end

    it "should detect me in join events" do
      @dispatcher.receive(":beerbot!~foo@localhost.iiNet JOIN :#chan1\r\n")
      @bot.output[:event].size.should == 1
      event,kargs = @bot.output[:event][0]
      event.should == :join
      kargs[:me].should == true
    end

    it "should gracefully handle bad bot replies (non-nil / not botmsg)" do
      def @bot.cmd msg,**kargs
        [1,2,3]
      end
      def @bot.event event,**kargs
        [1,2,3]
      end
      expect {
        @dispatcher.receive(":foo!~foo@localhost.iiNet PRIVMSG beerbot :,do something!\r\n")
        @dispatcher.receive(":beerbot!~foo@localhost.iiNet JOIN :#chan1\r\n")
      }.not_to raise_error
    end

  end
end
