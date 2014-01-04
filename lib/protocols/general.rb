# The files in this directory are part of BeerBot, a a ruby irc bot library.
# Copyright (C) 2013 Daniel Bush
# This program is distributed under the terms of the GNU
# General Public License.  A copy of the license should be
# enclosed with this project in the file LICENSE.  If not
# see <http://www.gnu.org/licenses/>.

module BeerBot

  module Protocol

    # Return a parser that takes string msg and extracts a specified
    # prefix at beginning.
    #
    # The prefix might be a nick or a command prefix.
    #
    # Use this to get commands issued to the bot through a channel.
    #
    # TODO: make sure this returns msg without the prefix, or nil
    # otherwise.

    def self.make_prefix_parser prefix
      rx = Regexp.new("^#{prefix}\\W?(.*)",'i')
      lambda {|msg|
        if m = rx.match(msg) then
          m[1].strip
        end
      }
    end

  end

end
