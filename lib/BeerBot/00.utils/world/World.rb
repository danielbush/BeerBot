# The files in this directory are part of BeerBot, a a ruby irc bot library.
# Copyright (C) 2014 Daniel Bush
# This program is distributed under the terms of the GNU
# General Public License.  A copy of the license should be
# enclosed with this project in the file LICENSE.  If not
# see <http://www.gnu.org/licenses/>.

module BeerBot

  module Utils

    # There should be one world per connection instance tracking
    # the channels joined and users on those channels.

    class World < Hash

      def initialize nick
        self[:nick] = nick

        # An index/lookup for channels we know about.
        self[:channels] = Hash.new {|h,k| h[k] = {users:Set.new}}

        # An index/lookup for users we know about.
        self[:users] = Hash.new {|h,k| h[k] = {channels:Set.new}}

      end

      # Someone joins channel.
      def join nick,channel
        self[:channels][channel][:users].add(nick)
        self[:users][nick][:channels].add(channel)
        self[:users][nick][:quit] = false
        self
      end

      # Someone leaves channel.
      def part nick,channel
        self[:channels][channel][:users].delete(nick)
        self[:users][nick][:channels].delete(channel)
        self
      end

      # Someone changes nick.
      def nick oldnick,nick
        self[:channels].each_pair{|name,chan|
          if chan[:users].member?(oldnick) then
            chan[:users].delete(oldnick)
            chan[:users].add(nick)
          end
        }
        self[:users][nick] = self[:users][oldnick]
        self[:users].delete(oldnick)
        # If it's us, update our nick:
        if self[:nick] == oldnick then
          self[:nick] = nick
        end
        self
      end

      def quit nick
        self[:channels].each_pair{|name,chan|
          chan[:users].delete(nick)
        }
        self[:users][nick][:channels] = Set.new
        self[:users][nick][:quit] = true
        self
      end

    end

  end

end

