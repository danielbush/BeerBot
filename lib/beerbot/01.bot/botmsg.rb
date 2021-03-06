# The files in this directory are part of BeerBot, a a ruby irc bot library.
# Copyright (C) 2013,2014 Daniel Bush
# This program is distributed under the terms of the GNU
# General Public License.  A copy of the license should be
# enclosed with this project in the file LICENSE.  If not
# see <http://www.gnu.org/licenses/>.

module BeerBot

    # BotMsg's are hashes or arrays of hashes and represent a bot
    # response (usually to some input eg from an irc server).
    #
    # The hash is generally expected to have the following keys:
    # 
    #   :msg
    #   :to
    #   
    # but may carry additional ones like
    # 
    #   :action (will be used instead of :msg)
    #
    # The array-form of the botmsg might look like this:
    # 
    #   [msg:'ho!',to:'#chan1']
    #   
    # and it is easy to add extra messages this way:
    # 
    #   [msg:'ho!',to:'#chan1'] + [msg:'ho again!',to:'#chan1']
    #   
    # etc

    module BotMsg

      # Determine if botmsg is a valid botmsg.

      def self.valid? botmsg
        case botmsg
        when Hash
          a = botmsg.has_key?(:to)
          b = (botmsg.has_key?(:msg) || botmsg.has_key?(:action))
          a && b
        when Array
          botmsg.inject(true){|s,v|
            # Members must be hash... 
            break false unless v.kind_of?(Hash)
            s = s && self.valid?(v);
            break false unless s;
            s
          }
        when Proc
          false
        else
          false
        end
      end

      # Convert botmsg to an array of one or more botmsg hashes.
      #
      # Returns array of botmsg hashes or empty array if not given
      # something that is valid.
      #
      # Proc's are executed to retrieve an array or hash.
      #
      # Array => Array
      # Hash  => [Hash]
      # Proc  => [Hash]

      def self.to_a botmsg
        case botmsg
        when Hash
          return [] unless self.valid?(botmsg)
          return [botmsg]
        when Array
          return [] unless self.valid?(botmsg)
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

      # Transform a botmsg (aka SINGLE RETURN FORMAT) or ARRAY FORMAT
      # to ARRAY FORMAT (described below).
      #
      # Background:
      # Bot modules may reply in either format. But we convert it
      # here. The single return format is the simplest, which is why
      # we have 2 formats.
      # 
      # ARRAY FORMAT
      # 
      #   [<bool>,<reply>]
      # 
      # where bool  = true  => "use <reply> and keep going"
      #             = false => "use <reply> but stop here"
      # where reply = whatever the bot returns.
      # 
      # NOTE: any other type of array will assumed to be in
      # single return form...
      #
      # SINGLE RETURN FORMAT
      # 
      # This form assumes you return one thing, either nil/false or a
      # botmsg. Returning nil/false won't suppress subsequent modules
      # from being evaluated.
      #
      # Note, that "whatever the bot returns" will need to be one of the
      # valid forms of a botmsg for it to get sent out.

      def self.to_reply_format thing
        case thing
        when Array
          bool,botmsg = thing
          case bool
          when TrueClass,FalseClass
            # Assume array format:
            [bool,self.to_a(botmsg)]
          else
            # Assume single return format...
            # Array of any sort is truthy, so suppress.
            [true,self.to_a(thing)]
          end
        else
          # Asume single return format...
          # 
          # Look at truthiness of thing to determine whether to suppress
          # further responses (true) or continue (false).
          if thing then
            [true,self.to_a(thing)]
          else
            [false,self.to_a(thing)]
          end
        end
      end
      
    end
    
end
