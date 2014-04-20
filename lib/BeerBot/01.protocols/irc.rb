# The files in this directory are part of BeerBot, a a ruby irc bot library.
# Copyright (C) 2013,2014 Daniel Bush
# This program is distributed under the terms of the GNU
# General Public License.  A copy of the license should be
# enclosed with this project in the file LICENSE.  If not
# see <http://www.gnu.org/licenses/>.

module BeerBot

  module Protocol

    module IRC

      # This class represents an irc message broken down into its
      # major constituent parts.
      #
      # These include the prefix, command, parameters and trailing
      # components of an irc message.

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

      # Parse raw irc string and then yield or return for various events.
      #
      # Parse's job is to take the constituents parts of an irc
      # message, identify the type of event and return a generic
      # representation of it.
      #
      # So for instance, a message is represented as
      #   [:msg,from,to,msg]
      # 
      # The lambda receives an incoming irc string, tries to parse
      # it and act on it.
      # The lambda should return nil or a botmsg hash.
      # Note that connection readiness and PONG protocol are handled by
      # the irc connection, not here.

      def self.parse str,&block

        m = IRCMessage.new(str)
        #puts "[parse] #{m}"
        result = []

        case m[:command]

        when 'NICK'  # change of nick
          case s=m.check(:prefix,:nick,:trailing)
          when Symbol
            puts "* NICK expected #{s}"
            return nil
          end
          old = m[:prefix][:nick]
          nick = m[:trailing]
          result = [:nick,old,nick]

        when 'PART' # someone leaves channel
          case s=m.check(:prefix,:nick,:params)
          when Symbol
            puts "* PART expected #{s}"
            return nil
          end
          channel = m[:params][0]
          nick = m[:prefix][:nick]
          result = [:part,nick,channel]

        when 'JOIN' # someone joins channel
          case s=m.check(:prefix,:nick,:trailing)
          when Symbol
            puts "* JOIN expected #{s}"
            return nil
          end
          channel = m[:trailing]
          nick = m[:prefix][:nick]
          result = [:join,nick,channel]

        when '353'  # channel user list when we join the channel
          case s=m.check(:params,:trailing)
          when Symbol
            puts "* 353 expected #{s}"
            return nil
          end
          channel = m[:params][2]
          users = m[:trailing].split(/\s+/)
          result = [:chanlist,channel,users]
          #puts "[parse/353] #{result}"

        when '366'  # end of 353
          result = [:chanlistend]

        when 'PRIVMSG'
          case s=m.check(:prefix,:nick,:params,:trailing)
          when Symbol
            #puts "* PRIVMSG expected #{s}"
            return nil
          end

          msg  = m[:trailing].strip
          from = m[:prefix][:nick].strip
          to   = m[:params][0].strip unless m[:params].empty?
          result = [:msg,from,to,msg]

        else # command we don't handle
          result = [:default,m]
        end

        if block_given? then
          yield result
        else
          result
        end
      end

      # Return irc-conformat string from a botmsg hash.
      #
      # Generates nil if it can't handle 'botmsg'.

      def self.to_irc botmsg
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
            self.to_irc reply
          }
        when Proc
          #p botmsg.call
          self.to_irc(botmsg.call)
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
