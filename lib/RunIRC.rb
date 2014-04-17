# The files in this directory are part of BeerBot, a a ruby irc bot library.
# Copyright (C) 2013,2014 Daniel Bush
# This program is distributed under the terms of the GNU
# General Public License.  A copy of the license should be
# enclosed with this project in the file LICENSE.  If not
# see <http://www.gnu.org/licenses/>.

require 'set'
require 'rubygems'
require 'pry'
require 'json'
require_relative 'BeerBot'

# Run the irc bot.
#
# This class creates and coordinates all the high level components
# needed to run beerbot over irc.
#
# See bin/* .

module BeerBot; end

class BeerBot::RunIRC

  Config        = BeerBot::Config
  Utils         = BeerBot::Utils
  IRCWorld      = BeerBot::Utils::IRCWorld
  InOut         = BeerBot::Utils::InOut
  IRCConnection = BeerBot::IRCConnection
  IRC           = BeerBot::Protocol::IRC
  Bot           = BeerBot::Bot
  BotMsgMore    = BeerBot::BotMsgMore
  IRCDispatcher = BeerBot::Dispatchers::IRCDispatcher
  Scheduler     = BeerBot::Scheduler

  attr_accessor :bot,:scheduler,:dispatch,:world,:conn,:postq,:parse,:more

  # Initialize all parts of the system here.
  #
  # BeerBot::Config should already be set before we get here.

  def initialize

    @path = File.expand_path(File.dirname(__FILE__)+'/..')
    @module_path = @path+'/modules'

    # Create the bot.
    @bot = Bot.new(@module_path,Config['modules'])

    # Dispatcher which receives messages and interacts with the bot.
    @dispatch = IRCDispatcher.new(
      @bot,
      Config['nick'],
      prefix:Config['cmd_prefix'],
      world:@world
    )

    @more = BotMsgMore.new

    # Set up scheduler (this doesn't start it yet)...
    @scheduler = Scheduler.instance(Config['timezone'])
    # Create a world associated with this irc connection.
    # (lists channels and users we know about)
    @world = IRCWorld.new(Config['nick'])

    # Create but don't open the irc connection.
    @conn = IRCConnection.new(
      nick:Config['nick'],
      server:Config['server'])

    # Dispatcher thread takes stuff from @conn queue and processes
    # it...

    @dispatcher_thread = InOut.new(inq:@conn.queue,outq:@conn.writeq) {|input|
      str,raw = input
      replies = @dispatch.receive(str)

      case replies
      when String # assume irc string
        replies
      when Hash,Array,Proc
        replies = @more.filter(replies)
        BeerBot::Protocol::IRC.to_irc(replies)
      else
        nil
      end
    }
    @dispatcher_thread.start!

    # Schedule dispatcher thread.
    #
    # These are responses that were prepared and scheduled earlier and
    # which also need to be dispatched.

    @scheduler_thread = InOut.new(inq:@scheduler.queue,outq:@conn.writeq) {|cron_job|
      puts "<< scheduler #{cron_job.inspect}"
      puts "<< scheduler #{Time.now}"
      IRC.to_irc(cron_job.job)
    }
    @scheduler_thread.start!

    # Set up a repl in a separate thread.
    # 
    # In pry, you can then do:
    #   @conn.writeq.enq IRC.join('#chan1')
    #   @conn.write IRC.join('#chan1')

    Pry.config.prompt = Proc.new {|_| ""}
    @pry_thread = Thread.new {
      binding.pry
    }

    # Do stuff once we've identified with the irc server...
    # 
    # Join channels.
    # Start the scheduler.

    @conn.ready? {
      channels = Config['channels']
      if channels then
        channels.each{|chan|
          @conn.writeq.enq(IRC.join(chan))
        }
      end
      @scheduler.start
    }
  end

  # Start the connection.

  def start
    @conn.open.join
  end

  # Convenience method to say something to channel or someone.

  def say to,msg
    @conn.writeq.enq(IRC.msg(to,msg))
  end

  # Convenience method to do something (/me).

  def action to,msg
    @conn.writeq.enq(IRC.action(to,msg))
  end

end

