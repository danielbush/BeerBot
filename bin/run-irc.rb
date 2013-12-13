# The files in this directory are part of BeerBot, a a ruby irc bot library.
# Copyright (C) 2013 Daniel Bush
# This program is distributed under the terms of the GNU
# General Public License.  A copy of the license should be
# enclosed with this project in the file LICENSE.  If not
# see <http://www.gnu.org/licenses/>.

raise "Needs ruby 2" if /^1/===RUBY_VERSION
require 'set'
require 'rubygems'
require 'pry'
require 'json'
@path = File.expand_path(File.dirname(__FILE__)+'/..')
require @path+'/lib/connect/IRCConnection'
require @path+'/lib/world/World'
require @path+'/lib/modules/init.rb'
require @path+'/lib/parse/parse'
require @path+'/lib/scheduler/scheduler'
require @path+'/lib/more/more'


if ARGV.size == 0 then
  puts "Usage: ruby beerbot.rb path/to/ircconf.json"
  puts "See conf/irc.json"
  exit 1
end

conffile = ARGV[0]
@config = JSON.load(File.read(conffile))

# Hot reload the bot, for coding on the fly :)
#
# You can call this using pry repl below during a session.
# Note: we don't reload the irc connection, that would be silly.
#
# The connection, and the bot's world and the scheduler remain
# untouched.

def reload!

  load @path+'/lib/bot/Bot.rb'
  load @path+'/lib/dispatchers/irc.rb'

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

send_mutex = Mutex.new

# Dispatcher thread.
#
# This thread executes the bot and module code.

Thread.new {
  p "Start dispatch thread"
  begin
    loop {
      response = nil
      ircmsg,raw = @conn.queue.deq

      # Dispatcher should return nil or valid botmsg (Hash) or Array
      # of valid botmsh Hashes or possibly a Proc that might return
      # similar.

      botmsg = @dispatch.call(ircmsg)

      response = @parse.botmsg2irc(botmsg)
      send_mutex.synchronize {
        @conn.write(response) if response
      }
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

Thread.new {
  loop {
    botmsg = @scheduler.queue.deq
    begin
      response = @parse.botmsg2irc(botmsg)
    rescue => e
      puts e
      puts e.backtrace
      next
    end
    send_mutex.synchronize {
      @conn.write(response) if response
    }
  }
}



# Load the bot and irc dispatcher code.
reload!

# Set up a repl in a separate thread.
Pry.config.prompt = Proc.new {|_| ""}
Thread.new {
  binding.pry
}

# Make this available to pry so we can issue commands from pry.
# 
# eg
#   @conn.write @parse.join('#chan1')

@parse = BeerBot::Parse::IRC

# Do stuff once we've identified with the irc server...
# 
# Join channels.
# Start the scheduler.

@conn.ready? {
  channels = @config['channels']
  if channels then
    channels.each{|chan|
      @conn.write(@parse.join(chan))
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

# Start the connection.
@conn.open.join
