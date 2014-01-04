# The files in this directory are part of BeerBot, a a ruby irc bot library.
# Copyright (C) 2013 Daniel Bush
# This program is distributed under the terms of the GNU
# General Public License.  A copy of the license should be
# enclosed with this project in the file LICENSE.  If not
# see <http://www.gnu.org/licenses/>.

require 'set'
require 'rubygems'
require 'pry'
require 'json'
path = File.expand_path(File.dirname(__FILE__)+'/..')
require path+'/connect/IRCConnection'
require path+'/world/World'
require path+'/modules/init.rb'
require path+'/protocols/botmsg'
require path+'/protocols/irc'
require path+'/scheduler/scheduler'

# Run the irc bot.
#
# This class creates and coordinates all the high level components
# needed to run beerbot over irc.
#
# See bin/* .

class RunIRC

  attr_accessor :config,:bot,:scheduler,:dispatch,:world,:conn,:parse

  # Initialize all parts of the system here.
  #
  # config: Hash of irc json config

  def initialize config
    @config = config
    @path = File.expand_path(File.dirname(__FILE__)+'/..')
    @bot = nil # see reload!
    @dispatch = nil # see reload!
    # Set up scheduler (this doesn't start it yet)...
    @scheduler = BeerBot::Scheduler.instance
    # Create a world associated with this irc connection.
    # (lists channels and users we know about)
    @world = BeerBot::IRCWorld.new(@config['name'],@config['nick'])
    # Create but don't open the irc connection.
    @conn = BeerBot::IRCConnection.new(
      @config['name'],
      nick:@config['nick'],
      server:@config['server'])

    # Make parser available to pry.

    @botmsg = BeerBot::Protocol::BotMsg
    @irc = BeerBot::Protocol::IRC

    # Dispatcher thread.
    #
    # This thread executes the bot and module code, gets
    # a response and enqueues it.

    @dispatch_thread = Thread.new {
      p "Start dispatch thread"
      begin
        loop {
          response = nil
          str,raw = @conn.queue.deq

          # Dispatcher should return nil or valid botmsg (Hash) or Array
          # of valid botmsh Hashes or possibly a Proc that might return
          # similar.

          result = @dispatch.call(str)
          case result
          when String
            response = result  # assume irc string
          else
            response = @botmsg.botmsg2irc(result)
          end

          if response then
            @conn.writeq.enq(response)
          else
            if result then
              p "Dispatcher returned #{result.inspect} which could not be converted to irc string"
            end
          end
        }
      rescue => e
        puts e
        puts e.backtrace
        exit 1
      end
    }

    # Schedule dispatcher thread.
    #
    # These are responses that were prepared and scheduled earlier and
    # which also need to be dispatched.

    @scheduler_thread = Thread.new {
      loop {
        botmsg = @scheduler.queue.deq
        begin
          response = @botmsg.botmsg2irc(botmsg)
        rescue => e
          puts e
          puts e.backtrace
          next
        end
        @conn.writeq.enq(response) if response
      }
    }
    
    # Load the bot and irc dispatcher code.
    reload!

    # Set up a repl in a separate thread.
    # 
    # In pry, you can then do:
    #   @conn.writeq.enq @irc.join('#chan1')
    #   @conn.write @irc.join('#chan1')

    Pry.config.prompt = Proc.new {|_| ""}
    @pry_thread = Thread.new {
      binding.pry
    }

    # Do stuff once we've identified with the irc server...
    # 
    # Join channels.
    # Start the scheduler.

    @conn.ready? {
      channels = @config['channels']
      if channels then
        channels.each{|chan|
          @conn.writeq.enq(@irc.join(chan))
        }
      end
      @scheduler.start
      # TODO: example scheduling, remove this...
      if false then
        @scheduler.add(
          {msg:"hi",to:"#chan1"},
          DateTime.now+Rational(0,24*60))
        @scheduler.add_perm(
          lambda{|now,h|
            {to:'#chan1',msg:"#{now}"} })
      end
    }
  end

  # Hot reload the bot, for coding on the fly :)
  #
  # You can call this using pry repl below during a session.
  # Note: we don't reload the irc connection, that would be silly.
  #
  # The connection, and the bot's world and the scheduler remain
  # untouched.

  def reload!
    load @path+'/bot/Bot.rb'
    load @path+'/dispatchers/irc.rb'

    # Create the bot.

    @bot = BeerBot::Bot.new(@config['nick'],modules:@config['modules'])

    # Dispatcher which receives messages and interacts with the bot.

    @dispatch = BeerBot::Dispatchers.makeIRCDispatcher(
      @bot,
      @config['nick'],
      @config['cmd_prefix'],
      @world
      )
  end

  # Start the connection.
  def start
    @conn.open.join
  end

  # Convenience method to say something to channel or someone.
  def say to,msg
    @conn.writeq.enq(@irc.msg(to,msg))
  end

end
