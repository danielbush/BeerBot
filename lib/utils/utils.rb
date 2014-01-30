
module BeerBot
  module Utils

    # Expand a string containing parameters starting with '::'.
    def self.expand msg,**kargs
      #matches = msg.scan(/\b::[A-z][A-z0-9]*\?\b/)
      kargs.each_pair{|key,val|
        msg = msg.gsub(/::#{key}/,val.to_s)
      }
      msg
    end

    # Convert botmsg to an action if it starts with '*'.
    def self.actionify botmsg
      case botmsg
      when Hash
        case botmsg[:msg]
        when /^\s*\*\s*/
          botmsg[:action] = botmsg[:msg].sub(/^\s*\*\s*/,'')
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
        return []
      end
    end



  end
end
