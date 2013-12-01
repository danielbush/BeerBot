require File.dirname(__FILE__)+"/../lib/dispatchers/irc.rb"
require 'pp'

describe "dispatching irc" do
  d = BeerBot::Dispatchers
  it "should dispatch valid IRCMessage instances" do
    # BotBase WorldBase
    bot = (Class.new {
      def cmd *args
        p 'cmd'
      end
      def hear *args
        p 'hear'
      end
    }).new
    disp = d.makeIRCDispatcher(bot,'beerbot',',',nil)
    # TODO ...
    #disp.call()
  end
end
