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
# 

module BeerBot
  module Utils
    module ParamSentence

      # Generate a sentence.

      def self.gen(spec)
        sentence,params = spec
        self.transform(sentence,params).strip
      end

      def self.expand(str,params)
        sym = str.to_sym
        if not params.has_key?(sym) then
          raise "'#{str}' has no corresponding symbol in params #{params}"
        end
        result = params[str.to_sym].sample
        result ? result : ""
      end

      # Split, map and rejoin a sentence (str).
      #
      # After splitting, apply expand on parameter words ":word".
      #
      # Watch out, throws error, be prepared.

      def self.transform(str,params)
        words = str.split(/\s+/)  # not great, we lose additional spaces
        words.map {|word|
          if word[0] == ':' then
            if word[1] == ':' then
              word  # let the bot code gsub this; ::from , ::to
            else
              #p "expanding #{word}"
              self.transform(self.expand(word[1..-1],params),params)
            end
          else
            word
          end
        }.select{|word| word != nil && word != ""}.join(' ')
      end
      
    end
  end
end
