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
require File.dirname(__FILE__)+'/lib/connect/IRCConnection'
require File.dirname(__FILE__)+'/lib/world/World'
require File.dirname(__FILE__)+'/lib/modules/init.rb'
require File.dirname(__FILE__)+'/lib/parse/parse'

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

def reload!

  load File.dirname(__FILE__)+'/lib/bot/Bot.rb'
  load File.dirname(__FILE__)+'/lib/dispatchers/irc.rb'

  # Create the bot.

  @bot = BeerBot::Bot.new(@config['nick'],modules:@config['modules'])

  # Dispatcher which receives messages and interacts with the bot.

  @dispatch = BeerBot::Dispatchers::IRC.new(
    @bot,
    @config['nick'],
    @config['cmd_prefix'] )

  # Get connection to emit to dispatcher.
  # Return value of receive will be processed by @conn if not nil.

  @conn.set_emit {|m,raw|
    # TODO: add flag to disable receive
    @dispatch.receive(m,raw,@world)
  }

end

# Create a world associated with this irc connection.
# (lists channels and users we know about)
@world = BeerBot::IRCWorld.new(@config['name'])

# Create but don't open the irc connection.
@conn = BeerBot::IRCConnection.new(
  @config['name'],
  nick:@config['nick'],
  server:@config['server'])

# Load the bot and ircdispatcher code.
reload!

# Set up a repl in a separate thread.
Pry.config.prompt = Proc.new {|_| ""}
Thread.new {
  binding.pry
}

# Make this available to pry so we can issue commands from pry.
@parse = BeerBot::Parse::IRC

# Join channels.
@conn.ready? {
  channels = @config['channels']
  if channels then
    channels.each{|chan|
      @conn.write(@parse.join(chan))
    }
  end
}

# Start the connection.
@conn.open.join
