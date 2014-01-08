# The files in this directory are part of BeerBot, a a ruby irc bot library.
# Copyright (C) 2013 Daniel Bush
# This program is distributed under the terms of the GNU
# General Public License.  A copy of the license should be
# enclosed with this project in the file LICENSE.  If not
# see <http://www.gnu.org/licenses/>.

module BeerBot

  # A singleton object that buffers responses by key.
  #
  # For irc and other messaging the key should probably
  # be the thing you want to message eg a channel or nick.

  class More

    attr_accessor :size
    attr_reader :buffer

    def size
      @size ||= 7  # lines
    end

    def buffer
      @buffer ||= Hash.new {|h,k| h[k]=[]}
    end

    # Fetch array of items from buffer for key 'key'.
    #
    # 'key' should probably be a person or channel you are messaging.
    #
    # Should return an array of items (eg of botmsg hashes).

    def more key
      a = self.buffer[key]
      self.buffer[key] = a.slice(self.size,a.size) || []
      return a.slice(0,self.size-1)
    end

    # Filter an array of items allowing only
    # the first 'n' of these.
    #
    # The remainder are stored in a buffer and can
    # be accessed via 'key' using 'self.more'.

    def filter arr,key
      if arr.size <= self.size then
        self.buffer[key] = [] # reset buffer
        return arr
      end
      self.buffer[key] = arr.slice(self.size,size)
      return arr.slice(0,self.size)
    end

  end
end
