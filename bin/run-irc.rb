# The files in this directory are part of BeerBot, a a ruby irc bot library.
# Copyright (C) 2013,2014 Daniel Bush
# This program is distributed under the terms of the GNU
# General Public License.  A copy of the license should be
# enclosed with this project in the file LICENSE.  If not
# see <http://www.gnu.org/licenses/>.

raise "Needs ruby 2" if /^1/===RUBY_VERSION
require_relative '../lib/RunIRC'

if ARGV.size == 0 then
  puts "Usage: ruby beerbot.rb path/to/ircconf.json"
  puts "See conf/irc.json"
  exit 1
end

conffile = ARGV[0]
BeerBot::Config.load JSON.load(File.read(conffile))
BeerBot::Config.validate!

$runirc = BeerBot::RunIRC.new BeerBot::Config
$runirc.start
