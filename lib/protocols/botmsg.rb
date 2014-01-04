# The files in this directory are part of BeerBot, a a ruby irc bot library.
# Copyright (C) 2013 Daniel Bush
# This program is distributed under the terms of the GNU
# General Public License.  A copy of the license should be
# enclosed with this project in the file LICENSE.  If not
# see <http://www.gnu.org/licenses/>.

module BeerBot

  module Protocol

    module BotMsg

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

      # Return irc-conformat string from a botmsg hash.
      #
      # Generates nil if it can't handle 'botmsg'.

      def self.botmsg2irc botmsg
        protocol = BeerBot::Protocol::IRC
        case botmsg
        when Hash
          to = botmsg[:to]
          return nil unless to
          if botmsg[:action] then
            protocol.action(to,botmsg[:action])
          elsif botmsg[:msg] then
            protocol.msg(to,botmsg[:msg])
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

    end
  end
end
