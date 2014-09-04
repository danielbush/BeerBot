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

require_relative '00.utils/utils'
require_relative '00.utils/InOut'
require_relative '01.bot/botmsg'
require_relative '70.scheduler/scheduler'

# Run the bot.
#
# This class creates and coordinates all the high level components
# needed to run beerbot.
#
# See bin/* .

module BeerBot; end

class BeerBot::Kernel

  Utils         = BeerBot::Utils
  InOut         = BeerBot::Utils::InOut
  BotMsg        = BeerBot::BotMsg
  Scheduler     = BeerBot::Scheduler

  attr_accessor :config, :bot, :scheduler, :dispatcher, :conn, :codec

  # Initialize all parts of the system here.
  #
  # config should be a hash, normally BeerBot::Config.
  # 
  # Note BeerBot::Config should be loaded before we initialize here.

  def initialize config, conn, codec, bot, dispatcher

    @echo = true
    @path = File.expand_path(File.dirname(__FILE__)+'/..')
    @module_path = config['moduledir']
    @config = config
    @bot = bot
    @conn = conn
    @codec = codec
    @dispatcher = dispatcher

    # Set up scheduler (this doesn't start it yet)...

    @scheduler = Scheduler.instance(config['timezone'])
    config.scheduler = @scheduler

    # Dispatcher thread takes stuff coming from the connection and does
    # something with it...

    @dispatcher_thread = InOut.new(inq:@conn.queue,outq:@conn.writeq) {|input|
      str,raw = input
      event,*args = @codec.decode(str)
      replies = @dispatcher.receive(event,args)
      @codec.encode(replies)
    }
    @dispatcher_thread.start!

    # Schedule dispatcher thread.
    #
    # These are responses that were prepared and scheduled earlier and
    # which also need to be dispatched.

    @scheduler_thread = InOut.new(inq:@scheduler.queue,outq:@conn.writeq) {|cron_job|
      puts "<< scheduler #{cron_job.inspect}" if @echo
      puts "<< scheduler #{@scheduler.time}" if @echo
      @codec.encode(cron_job.run)
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
        @codec.encode(BotMsg.to_a(replies))
      else
        []
      end
    }
    @active_thread.start!

    # Set up a repl in a separate thread.
    # 
    # In pry, you can then do:
    #   @conn.writeq.enq @codec.join('#chan1')
    #   @conn.write @codec.join('#chan1')

    Pry.config.prompt = Proc.new {|_| "pry> "}
    @pry_thread = Thread.new {
      binding.pry
    }

    # Initialize bot and its modules...

    @bot.init(@config)
    @bot.update_config(@config)

    # Do stuff once we've identified with the server...
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
    @conn.writeq.enq(@codec.msg(to,msg))
  end

  # Convenience method to do something (/me).

  def action to,msg
    @conn.writeq.enq(@codec.action(to,msg))
  end

  # Convenience method to join a channel.

  def join chan
    @conn.writeq.enq(@codec.join(chan))
  end

  # Convenience method to leave a channel.

  def leave chan
    @conn.writeq.enq(@codec.leave(chan))
  end

end

