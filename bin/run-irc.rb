# The files in this directory are part of BeerBot, a a ruby irc bot library.
# Copyright (C) 2013 Daniel Bush
# This program is distributed under the terms of the GNU
# General Public License.  A copy of the license should be
# enclosed with this project in the file LICENSE.  If not
# see <http://www.gnu.org/licenses/>.

path = File.expand_path(File.dirname(__FILE__))
require path+'/../lib/run/RunIRC'

if ARGV.size == 0 then
  puts "Usage: ruby beerbot.rb path/to/ircconf.json"
  puts "See conf/irc.json"
  exit 1
end

conffile = ARGV[0]
config = JSON.load(File.read(conffile))

@run = RunIRC.new(config)
@run.start
