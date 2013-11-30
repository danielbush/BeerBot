# The files in this directory are part of BeerBot, a a ruby irc bot library.
# Copyright (C) 2013 Daniel Bush
# This program is distributed under the terms of the GNU
# General Public License.  A copy of the license should be
# enclosed with this project in the file LICENSE.  If not
# see <http://www.gnu.org/licenses/>.

module BeerBot

  # There should be one world per connection instance tracking
  # the channels joined and users on those channels.

  class World < Hash

    def initialize name,nick
      self[:name] = name
      self[:nick] = nick

      # An index/lookup for channels we know about.
      self[:channels] = Hash.new {|h,k| h[k] = {users:Set.new}}

      # An index/lookup for users we know about.
      self[:users] = Hash.new {|h,k| h[k] = {channels:Set.new}}

    end

    # Fetch a user.
    def user user
      if self[:users].has_key?(user) then
        self[:users][user]
      else
      end
    end

    # Fetch a channel.
    def channel channel
      if self[:channels].has_key?(channel) then
        self[:channels][channel]
      else
      end
    end

    # Someone joins nick.
    def join nick,channel
      self[:channels][channel][:users].add(nick)
      self[:users][nick][:channels].add(channel)
      self
    end

    # Someone leaves nick.
    def part nick,channel
      self[:channels][channel][:users].delete(nick)
      self[:users][nick][:channels].delete(channel)
      self
    end

    # Someone changes nick.
    def nick oldnick,nick
      self[:channels].each_pair{|name,chan|
        if chan.member?(oldnick) then
          chan.delete(oldnick)
          chan.add(nick)
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

    # TODO: User quits altogether.
    def quit user
    end

  end

  # The chief specialisation of IRCWorld is to handle user names which
  # are sometimes prepended with characters like '@'.
  #
  # TODO: are there any more?

  class IRCWorld < World
    def remove_op nick
      nick.sub(/^@/,'')
    end

    def user nick
      nick = self.remove_op(nick)
      super
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
  end

end

