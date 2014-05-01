require_relative "../../lib/BeerBot/02.protocols/irc.rb"
require_relative "../../lib/BeerBot/06.dispatchers/dispatcher.rb"
require 'pp'

describe "dispatchers",:dispatchers => true do

  Dispatcher = BeerBot::Dispatchers::Dispatcher

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

  describe "irc dispatcher",:dispatcher => true do

    before(:each) {
      @bot = MockBot.new
      @dispatcher = Dispatcher.new(@bot,'beerbot')
    }

    it "should dispatch valid various generic events with parameters" do
      @dispatcher = Dispatcher.new(@bot,'beerbot') {|event,*args|
        case event
        when :nick
          [event,*args]
        when :msg
          [event,*args]
        end
      }
      response = @dispatcher.receive(:nick,['tom','tom_is_away'])
      response.should == [:nick,'tom','tom_is_away']

      response = @dispatcher.receive(:msg,["adamr", "#sydney", "because we have?"])
      response.should == [:msg,'adamr','#sydney','because we have?']
      
    end

    it "should handle action events" do
      @dispatcher = Dispatcher.new(@bot,'beerbot') {|event,*args|
        case event
        when :action
          [event,*args]
        end
      }
      response = @dispatcher.receive(:action,["danb", "#sydney", "does something"])
      response.should == [:action,"danb", "#sydney", "does something"]
    end

    it "should handle join events" do
      @dispatcher.receive(:join,['danb','#chan1'])
      @bot.output[:event].size.should == 1
      event,kargs = @bot.output[:event][0]
      event.should == :join
      [kargs[:me],kargs[:nick],kargs[:channel]].should == [false,'danb','#chan1']
    end

    it "should detect me in join events" do
      @dispatcher.receive(:join,['beerbot','#chan1']).should == []
      @bot.output[:event].size.should == 1
      event,kargs = @bot.output[:event][0]
      event.should == :join
      kargs[:me].should == true
    end

    it "should gracefully handle bad bot replies (non-nil / not botmsg)" do
      def @bot.cmd msg,**kargs
        [1,2,3] # invalid
      end
      def @bot.event event,**kargs
        [1,2,3] # invalid
      end
      @dispatcher.receive(:msg,["foo", "beerbot", ",do something!"]).should == []
      @dispatcher.receive(:join,["beerbot", "#chan1"]).should == []
    end

  end
end
