# The files in this directory are part of BeerBot, a a ruby irc bot library.
# Copyright (C) 2014 Daniel Bush
# This program is distributed under the terms of the GNU
# General Public License.  A copy of the license should be
# enclosed with this project in the file LICENSE.  If not
# see <http://www.gnu.org/licenses/>.

require_relative 'World'

module BeerBot

  module Utils

    # The chief specialisation of IRCWorld is to handle user names which
    # are sometimes prepended with characters like '@'.
    #
    # TODO: are there any more?

    class IRCWorld < World
      def remove_op nick
        nick.sub(/^@/,'')
      end

      def nick oldnick,nick
        oldnick = self.remove_op(oldnick)
        nick = self.remove_op(nick)
        super
      end

      def part nick,channel
        nick = self.remove_op(nick)
        super
      end
      
      def join nick,channel
        nick = self.remove_op(nick)
        super
      end

      def quit nick
        nick = self.remove_op(nick)
        super
      end
    end

  end
end
