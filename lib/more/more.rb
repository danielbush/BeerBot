
module BeerBot

  # A singleton object that buffers responses by key.
  #
  # For irc and other messaging the key should probably
  # be the thing you want to message eg a channel or nick.

  module More

    def self.size
      @size ||= 4  # lines
    end

    def self.buffer
      @buffer ||= Hash.new {|h,k| h[k]=[]}
    end

    # Fetch array of items from buffer for 'to'.
    #
    # 'to' should probably be
    #   prefix PRIVMSG to :msg
    #
    # Should return an array of botmsg's.

    def self.more key
      a = self.buffer[key]
      self.buffer[key] = a.slice(self.size,a.size) || []
      return a.slice(0,self.size-1)
    end

    # Filter an array of items allowing only
    # the first 'n' of these.
    #
    # The remainder are stored in a buffer and can
    # be accessed via 'key' using 'self.more'.

    def self.filter arr,key
      if arr.size <= self.size then
        self.buffer[key] = [] # reset buffer
        return arr
      end
      self.buffer[key] = arr.slice(self.size,size)
      return arr.slice(0,self.size)
    end

  end
end
