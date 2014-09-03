#!/usr/bin/env ruby

# The files in this directory are part of BeerBot, a a ruby irc bot library.
# Copyright (C) 2013,2014 Daniel Bush
# This program is distributed under the terms of the GNU
# General Public License.  A copy of the license should be
# enclosed with this project in the file LICENSE.  If not
# see <http://www.gnu.org/licenses/>.

# If you're running this WITHOUT the gem, you probably want to do
# something like this (in beerbot's root directory):
#
#   ruby -Ilib bin/beerbot-run-irb.rb path/to/conf.json

raise "Needs ruby 2" if /^1/===RUBY_VERSION
require 'beerbot'
require 'json'

Bot           = BeerBot::Bot
Dispatcher    = BeerBot::Dispatchers::Dispatcher
IRCConnection = BeerBot::IRCConnection
codec         = BeerBot::Codecs::IRC

if ARGV.size == 0 then
  puts "Usage: ruby beerbot.rb path/to/ircconf.json"
  puts "See conf/irc.json"
  exit 1
end

conffile = ARGV[0]
config = BeerBot::Config.new
config.load JSON.load(File.read(conffile))
config.validate!

conn = IRCConnection.new(
  nick:config['nick'],
  server:config['server']
)

# Create the bot.

bot = Bot.new
bot.load!(config['modules'], config['moduledir'])
config.bot = bot

# Dispatcher which handles events and messages (protocol/codec
# independent).

dispatcher = Dispatcher.new(
  bot,
  config['nick'],
  prefix:config['cmd_prefix'],
  config:config
)

$kernel = BeerBot::Kernel.new(config, conn, codec, bot, dispatcher)
$kernel.start
