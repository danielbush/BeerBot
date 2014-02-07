# The files in this directory are part of BeerBot, a a ruby irc bot library.
# Copyright (C) 2013 Daniel Bush
# This program is distributed under the terms of the GNU
# General Public License.  A copy of the license should be
# enclosed with this project in the file LICENSE.  If not
# see <http://www.gnu.org/licenses/>.

module BeerBot

  module Protocol

    module IRC

      # In coming IRC messages are parsed into hashes with several
      # additional methods.

      class IRCMessage < Hash

        # This regexp captures the basic pattern used for prefixed and
        # unprefixed irc commands sent by the server to a client.
        # 
        # See: http://tools.ietf.org/html/rfc1459.html sec 2.3.1

        CMD = Regexp.new(
          # nick!~user@host:
          '^(:(?<prefix>[^:\s]+(@\S+)?)\s+)?'+
          # eg 'PRIVMSG' , 3-digit code:
          '(?<command>[^:\s]+)'+
          # Bit after the command (one or more words):
          '(\s+(?<params>[^:\s]+(\s+[^:\s]+)*))?\s*'+
          # Bit after second ':' the msg in PRIVMSG
          '\s:\s*(?<trailing>.*)$'
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
