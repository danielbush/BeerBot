# The files in this directory are part of BeerBot, a a ruby irc bot library.
# Copyright (C) 2013 Daniel Bush
# This program is distributed under the terms of the GNU
# General Public License.  A copy of the license should be
# enclosed with this project in the file LICENSE.  If not
# see <http://www.gnu.org/licenses/>.

module BeerBot

  module Parse

    # Parse a string msg and look for nick or command prefix at
    # beginning.
    #
    # Use this to get commands issued to the bot through a channel.
    # msg should be :msg (or :trailing) in self.parse.
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


    module IRC

      # In coming IRC messages are parsed into hashes with several
      # additional methods.

      class IRCMessage < Hash

        # This regexp captures the basic pattern used for prefixed and
        # unprefixed irc commands sent by the server to a client.
        # 
        # See: http://tools.ietf.org/html/rfc1459.html sec 2.3.1
        #
        # NOTE: some of the opening messages sent at connection time
        # by the default debian irc server don't start with ':'.
        # So to handle these, we start with '^:?' not '^:'.

        CMD = Regexp.new(
          '^(:(?<prefix>\S+)\s+)?'+ # nick!~user@host
          '(?<command>\S+)'+  # eg 'PRIVMSG' , 3-digit code
          '(\s+(?<params>.*))?\s*'+ # bit after the command (one or more words)
          '\s:\s*(?<trailing>.*)$' # bit after second ':' the msg in PRIVMSG
          )

        def initialize raw

          @valid = false
          @has_prefix = false
          @user_prefix = false # message came from nick
          self[:prefix] = {}
          self[:command] = :unknown
          self[:raw] = raw
          self[:params] = []
          self[:trailing] = nil

          if m = CMD.match(raw) then
            @valid = true
            if m[:prefix] then
              @has_prefix = true
              nick,host = m[:prefix].split('!')
              if host then
                @user_prefix = true
                user,host = host.split('@')
                self[:prefix][:nick] = nick
                self[:prefix][:user] = user
                self[:prefix][:host] = host
              else
                # It aint a user prefix, so just bung it in host for the
                # moment.
                self[:prefix][:host] = nick
              end
            end

            self[:command] = m[:command].strip
            params = if m[:params] then m[:params].strip else "" end
            self[:params] = params.split(/\s+/)
            self[:trailing]= m[:trailing].strip
          end

        end

        # We couldn't parse the command if not valid.

        def valid?
          @valid
        end

        # Is a prefixed irc string sent by server.

        def prefix?
          @has_prefix
        end

        # Is prefixed and the prefix is nick!~user@host .

        def user_prefix?
          @user_prefix
        end

        # Check that syms exist in the hash otherwise return the missing
        # sym.  

        def check *syms
          result = true
          syms.each{|sym|
            case sym
            when :prefix,:nick,:user,:host
              return :prefix unless self[:prefix]
              case sym
              when :prefix
              else
                return sym unless self[:prefix][sym]
              end
            else
              return sym unless self[sym]
            end
          }
          result
        end

      end

      # Processes bot messages.
      #
      # Return irc string or array of these if botmsg is an array.
      #
      # botmsg is protocol agnostic.
      # We need to convert to irc.
      #
      # Generates nil if it can't handle 'botmsg'.

      def self.botmsg2irc botmsg
        case botmsg
        when Hash
          to = botmsg[:to]
          return nil unless to
          if botmsg[:action] then
            self.action(to,botmsg[:action])
          elsif botmsg[:msg] then
            self.msg(to,botmsg[:msg])
          else
            nil
          end
        when Array
          botmsg.map{|reply|
            self.botmsg2irc reply
          }
        when Proc
          #p botmsg.call
          self.botmsg2irc(botmsg.call)
        else
          nil
        end
      end

      # Convert botmsg to an array of one or more botmsg hashes.
      #
      # Proc's are executed to retrieve an array or hash.
      #
      # Array => Array
      # Hash  => [Hash]
      # Proc  => [Hash]

      def self.botmsg_to_a botmsg
        case botmsg
        when Hash
          return [botmsg]
        when Array
          return botmsg
        when Proc
          return self.botmsg_to_a(botmsg.call)
        else
          return nil
        end
      end

      # Send PRIVMSG to channel or nick.

      def self.msg to,str
        "PRIVMSG #{to} :#{str}"
      end
      class << self
        alias_method :privmsg,:msg
      end

      # Send a /me-style action to channel or nick.

      def self.action to,str
        "PRIVMSG #{to} :\u0001#{'ACTION'} #{str}\u0001"
      end

      # Join a channel

      def self.join chan
        "JOIN #{chan}"
      end

    end
  end

end
