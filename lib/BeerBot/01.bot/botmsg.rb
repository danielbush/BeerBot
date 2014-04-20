# The files in this directory are part of BeerBot, a a ruby irc bot library.
# Copyright (C) 2013,2014 Daniel Bush
# This program is distributed under the terms of the GNU
# General Public License.  A copy of the license should be
# enclosed with this project in the file LICENSE.  If not
# see <http://www.gnu.org/licenses/>.

module BeerBot

    # BotMsg's are hashes or arrays of hashes.
    #
    # The hash is generally expected to have the following keys:
    #   :msg
    #   :to
    # but may carry additional ones like
    #   :action (will be used instead of :msg)
    #
    # The array-form of the botmsg might look like this:
    #   [msg:'ho!',to:'#chan1']
    # and it is easy to add extra messages this way:
    #   [msg:'ho!',to:'#chan1'] + [msg:'ho again!',to:'#chan1']
    # etc

    module BotMsg

      # Convert botmsg to an array of one or more botmsg hashes.
      #
      # Proc's are executed to retrieve an array or hash.
      #
      # Array => Array
      # Hash  => [Hash]
      # Proc  => [Hash]

      def self.to_a botmsg
        case botmsg
        when Hash
          return [botmsg]
        when Array
          return botmsg
        when Proc
          return self.to_a(botmsg.call)
        else
          return []
        end
      end

      # Convert botmsg to an action if it starts with '*'.

      def self.actionify botmsg
        case botmsg
        when Hash
          case botmsg[:msg]
          when /^\*\s*/
            botmsg[:action] = botmsg[:msg].sub(/^\*\s*/,'')
            botmsg[:msg] = nil
          end
          botmsg
        when Array
          botmsg.map {|b|
            self.actionify(b)
          }
        else
          botmsg
        end
      end
      
    end
    
end
