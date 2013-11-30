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

      # This regexp captures the basic pattern used for prefixed irc
      # commands sent by the server to a client.
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

      # Parse irc messages received from the irc server.

      def self.parse msg
        if m = CMD.match(msg) then

          if m[:prefix] then
            nick,host = m[:prefix].split('!')
            if host then
              user,host = host.split('@')
            else
              host = nick
              nick = user = nil
            end
          else
            nick = user = host = nil
          end

          command = m[:command].strip
          params = if m[:params] then m[:params].strip else "" end
          trailing = m[:trailing].strip
          params = params.split(/\s+/)

          result = {
            prefix:{
              nick:nick,
              user:user,
              host:host
            },
            command:command,
            params:params,
            trailing:trailing
          }
          result
        else
          {command: :unknown, raw: msg}
        end
      end

      # Check the result of 'parse' for relevant parts.
      # 
      # Return false if 'items' aren't found in 'm'.
      # Use this to check what we got back from parsing.
      #
      # @see parse.

      def self.check m,items
        result = true
        items.each{|item|
          case item
          when :prefix,:nick,:user,:host
            return :prefix unless m[:prefix]
            case item
            when :prefix
            else
              return item unless m[:prefix][item]
            end
          else
            return item unless m[item]
          end
        }
        result
      end

      # Processes bot messages.
      #
      # Return irc string or array of these if botmsg is an array.
      #
      # botmsg is protocol agnostic.
      # We need to convert to irc.
      #
      # Generates nil if it can't handle 'botmsg'.

      def self.botmsg botmsg
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
            self.botmsg reply
          }
        when Proc
          p botmsg.call
          self.botmsg(botmsg.call)
        else
          nil
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
