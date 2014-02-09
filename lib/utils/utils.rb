
module BeerBot
  module Utils

    # Look for parameters in a string.
    #
    # Numeric parameters => "... ::1 ... ::2 "
    # Key parameters => "... ::foo ... ::bar "
    # Multi => "... ::foo|::1 ... ::bar|::foo|::1 "
    # 
    # (?: ) is a non-capturing group.

    def self.scan_param msg
      matches = msg.scan(/(?:::[^\W\s:|]+(?:\|::[^\W\s:|]+)*)/)
      matches.map{|m|
        a = m.split('|').map{|m2|
          m2 = m2.sub('::','')
          case m2
          when /\d+/
            m2.to_i
          else
            m2
          end
        }
        [m,a]
      }
    end

    # Expand a string with numeric and key parameters using data
    # provided.
    #
    # Parameters should be preceded with a double-colon in the msg.
    # Numeric parameters are matched to 'args'.
    # So ::1 => args[0] etc
    #
    # 'expand' will return the expanded string as best it can and an
    # error object.
    # The error object will tell you if there weren't enough
    # parameters in args to satisfy the numeric parameters in the
    # string.
    # 
    # ("::1 ::foo ::bar|::1",'a',foo:'b') => "a b a"

    def self.expand msg,*args,**kargs
      err = []
      params = self.scan_param(msg)
      # Do the big ones first.
      params = params.sort{|a,b|b[1].size<=>a[1].size}
      params.each {|i|
        # pattern: "::1|::foo"
        # parts: [1,'foo']
        pattern,parts = i
        found = false
        errargs = []
        errkargs = []
        parts.each {|part|
          v = nil
          case part
          when Fixnum
            v = args[part-1]
            errargs.push(part) unless v
          else
            v = kargs[part.to_sym]
            errkargs.push(part) unless v
          end
          if v then
            msg = msg.gsub(pattern,v)
            found = true
          end
        }
        unless found then
          err += errargs
        end
      }
      [msg,err]
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
