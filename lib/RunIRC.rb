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

  Utils         = BeerBot::Utils
  IRCWorld      = BeerBot::Utils::IRCWorld
  InOut         = BeerBot::Utils::InOut
  IRCConnection = BeerBot::IRCConnection
  IRC           = BeerBot::Protocol::IRC
  Bot           = BeerBot::Bot
  IRCDispatcher = BeerBot::Dispatchers::IRCDispatcher
  Scheduler     = BeerBot::Scheduler

  attr_accessor :config,:bot,:scheduler,:dispatcher,:world,:conn,:postq,:parse,:more

  # Initialize all parts of the system here.
  #
  # config should be a hash, normally BeerBot::Config.
  # 
  # Note BeerBot::Config should be loaded before we initialize here.

  def initialize config

    @path = File.expand_path(File.dirname(__FILE__)+'/..')
    @module_path = config['moduledir']
    @config = config

    # Create the bot.
    @bot = Bot.new(@module_path,config['modules'])

    # Create a world associated with this irc connection.
    # (lists channels and users we know about)
    @world = IRCWorld.new(config['nick'])

    # Dispatcher which receives messages and interacts with the bot.
    @dispatcher = IRCDispatcher.new(
      @bot,
      config['nick'],
      prefix:config['cmd_prefix'],
      world:@world
    )

    # Set up scheduler (this doesn't start it yet)...
    @scheduler = Scheduler.instance(config['timezone'])

    # Create but don't open the irc connection.
    @conn = IRCConnection.new(
      nick:config['nick'],
      server:config['server'])

    # Dispatcher thread takes stuff from @conn queue and processes
    # it...

    @dispatcher_thread = InOut.new(inq:@conn.queue,outq:@conn.writeq) {|input|
      str,raw = input
      replies = @dispatcher.receive(str)
    }
    @dispatcher_thread.start!

    # Schedule dispatcher thread.
    #
    # These are responses that were prepared and scheduled earlier and
    # which also need to be dispatched.

    @scheduler_thread = InOut.new(inq:@scheduler.queue,outq:@conn.writeq) {|cron_job|
      puts "<< scheduler #{cron_job.inspect}"
      puts "<< scheduler #{@scheduler.time}"
      IRC.to_irc(cron_job.job)
    }
    @scheduler_thread.start!

    # Set up a repl in a separate thread.
    # 
    # In pry, you can then do:
    #   @conn.writeq.enq IRC.join('#chan1')
    #   @conn.write IRC.join('#chan1')

    Pry.config.prompt = Proc.new {|_| "pry> "}
    @pry_thread = Thread.new {
      binding.pry
    }

    # Do stuff once we've identified with the irc server...
    # 
    # Join channels.
    # Start the scheduler.

    @conn.ready? {
      channels = config['channels']
      if channels then
        channels.each{|chan|
          self.join(chan)
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

  # Convenience method to join a channel.

  def join chan
    @conn.writeq.enq(IRC.join(chan))
  end

  # Reload @bot using module list 'modules'.
  #
  # You could use

  def reload! modules=[]
    @config['modules'] = modules
    @bot = Bot.new(@module_path,modules)
    @dispatcher.bot = @bot
  end

end

