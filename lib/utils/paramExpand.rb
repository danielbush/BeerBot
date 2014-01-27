
module BeerBot

  module Utils

    # Randomly generate sentences.
    #
    # See spec examples in spec/.
    # 
    # Take a spec which is of form
    #   [<sentence>,<hash>]
    # where <sentence> is a string and
    # each entry in <hash>
    #   <key> => <value>
    # where <key> is a symbol, and <value>
    # is an array of <sentence>'s.
    # 
    # <sentence> is a sentence or phrase.
    # If a word starts with ':' it will be looked up
    # in <hash>, an entry from <value> will be randomly
    # selected.
    # The entry from <value> will also undergo the
    # same ':' substitution.

    module ParamExpand

      # Recursively expand a sentence with parameters starting with
      # ':' using values sampled from params.
      # 
      # Split, map and rejoin a sentence (str).
      #
      # After splitting, apply expand on parameter words ":word".
      #
      # Watch out, throws error, be prepared.

      def self.expand(str,params,raise_error=false)
        words = str.split(/\s+/)  # not great, we lose additional spaces
        words.map {|word|
          if word[0] == ':' then
            if word[1] == ':' then
              word  # let the bot code gsub this; ::from , ::to
            else
              self.expand(
                self.lookup(word[1..-1],params,raise_error),
                params,raise_error
              )
            end
          else
            word
          end
        }.select{|word| word != nil && word != ""}.join(' ').strip
      end
      
      # Randomly select entry from params.

      def self.lookup(str,params,raise_error=false)
        if not params.has_key?(str) then
          if raise_error then
            raise "'#{str}' has no corresponding symbol in params #{params}"
          else
            return ""
          end
        end
        result = params[str].sample
        result ? result : ""
      end

    end
  end
end
