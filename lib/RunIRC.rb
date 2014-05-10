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
require_relative 'beerbot'

# Run the irc bot.
#
# This class creates and coordinates all the high level components
# needed to run beerbot over irc.
#
# See bin/* .

module BeerBot; end

class BeerBot::RunIRC

  Utils         = BeerBot::Utils
  InOut         = BeerBot::Utils::InOut
  IRCConnection = BeerBot::IRCConnection
  IRC           = BeerBot::Protocol::IRC
  Bot           = BeerBot::Bot
  BotMsg        = BeerBot::BotMsg
  Dispatcher    = BeerBot::Dispatchers::Dispatcher
  Scheduler     = BeerBot::Scheduler

  attr_accessor :config,:bot,:scheduler,:dispatcher,:conn,:postq,:parse,:more

  # Initialize all parts of the system here.
  #
  # config should be a hash, normally BeerBot::Config.
  # 
  # Note BeerBot::Config should be loaded before we initialize here.

  def initialize config

    @echo = true
    @path = File.expand_path(File.dirname(__FILE__)+'/..')
    @module_path = config['moduledir']
    @config = config

    # Create the bot.
    @bot = Bot.new(@module_path,config['modules'])
    config.bot = @bot
    @bot.update_config(@config)

    # Dispatcher which receives messages and interacts with the bot.
    @dispatcher = Dispatcher.new(
      @bot,
      config['nick'],
      prefix:config['cmd_prefix'],
      config:config
    )

    # Set up scheduler (this doesn't start it yet)...
    @scheduler = Scheduler.instance(config['timezone'])
    config.scheduler = @scheduler

    # Create but don't open the irc connection.
    @conn = IRCConnection.new(
      nick:config['nick'],
      server:config['server'])

    # Dispatcher thread takes stuff coming from the irc connection and does
    # something with it...

    @dispatcher_thread = InOut.new(inq:@conn.queue,outq:@conn.writeq) {|input|
      str,raw = input
      event,*args = IRC.parse(str)
      replies = @dispatcher.receive(event,args)
      IRC.to_irc(replies)
    }
    @dispatcher_thread.start!

    # Schedule dispatcher thread.
    #
    # These are responses that were prepared and scheduled earlier and
    # which also need to be dispatched.

    @scheduler_thread = InOut.new(inq:@scheduler.queue,outq:@conn.writeq) {|cron_job|
      puts "<< scheduler #{cron_job.inspect}" if @echo
      puts "<< scheduler #{@scheduler.time}" if @echo
      IRC.to_irc(cron_job.run)
    }
    @scheduler_thread.start!

    # Active messaging queue.
    #
    # 'config' will be injected into bot modules.
    # config.out should be a queue that we can dequeue.

    @active_thread = InOut.new(inq:@config.out,outq:@conn.writeq) {|replies|
      puts "<< active #{replies}" if @echo
      # TODO: almost identical logic in the dispatcher class (in
      # @dispatcher_thread).
      case replies
      when String # assume protocol string eg irc
        replies
      when Hash,Array,Proc
        IRC.to_irc(BotMsg.to_a(replies))
      else
        []
      end
    }
    @active_thread.start!

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

  # Toggle whether inputs and outputs show on the repl screen.
  #
  # Call this from the pry repl.

  def echo
    @echo = !@echo
    @conn.echo = @echo
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

  # Convenience method to leave a channel.

  def leave chan
    @conn.writeq.enq(IRC.leave(chan))
  end

end

