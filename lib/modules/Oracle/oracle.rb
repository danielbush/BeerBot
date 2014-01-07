# The files in this directory are part of BeerBot, a a ruby irc bot library.
# Copyright (C) 2013 Daniel Bush
# This program is distributed under the terms of the GNU
# General Public License.  A copy of the license should be
# enclosed with this project in the file LICENSE.  If not
# see <http://www.gnu.org/licenses/>.

module BeerBot; module Modules; end; end

# This module responds to messages that end with 2 or more question
# marks eg ??, ??? etc.
#
# If we're lucky, it may make the bot sound vaguely human :D

module BeerBot::Modules::Oracle

  # Answers that tend towards yes/no/in-between type answers.
  @@binaries = [

    "No",
    "No.",
    "Definitely not!",
    "I don't think so",
    "Hell no",
    "Nope",
    "I have grave doubts",
    "I have my doubts",

    "Yes",
    "Yes.",
    "yup",
    "Sure",
    "I concur",
    "I think so",
    "I'd say so",
    #"Clearly",
    "Absolutely",
    "Definitely",
    "fo' shizzle man",
    "Undoubtedly",

    "Maybe",
    "pass",
    "I'll take a pass on that one :from",
    "Well, maybe",
    "Meh!",
    "Perhaps",
    "Possibly",
    "Possible perhaps",
    "I don't know",
    "I'd have to think about it :from",
    "I'm not so sure",
    "I need to think about it some more",
    "hmmm",
    "errr...",

  ]

  # Answers that try to deal with non-binary type questions.
  @@playfortime = [
    "It's obvious",
    #"why not?",
    #"Because",
    "I don't know",
    "I think you must search deep inside yourself to find the answer to that one",
    "Maybe you're going to have to rephrase that :from",
    "I know but I'm not sure I should be telling you",
    "Ask somebody else :from",
    "Look into my eyes :from",
    "The truth will emerge eventually :from",
    "The truth will out some day",
    "You'll have to find out for yourself :from",
    "I think the answer is clear to everybody :from",
    "I think you're going to have to think about this some more :from",
    "I think we'll all have to ponder on that one",
    "I'm unable to divulge that information :from",
    "The answer is elementary",
    "That's classified",
    "I can tell you, but I may have to kill you :from",
    "If I knew that answer... well I'm just saying :from",
    "I'm afraid I can't say :from",
    "I think this is a question that will remain unresolved for some time :from",
    "If you don't know already, then I can't help you",
    "I think the answer is right in front of you :from",
  ]

  def self.hear msg,to:nil,from:nil,world:nil
    case msg

    # binary
    when /^(\s*\S+\s+)?what about(\s.*)?\?{2,}\s*$/i
      response = @@binaries.sample.gsub(/:from/,from)
      [to:to,msg:response]

    # "why ... ??"
    # "so why ... ??"
    # "what's ... ??"
    when /^(\s*\S+\s+)?where(\S*)?(\s.*)?\?{2,}\s*$/i,
         /^(\s*\S+\s+)?why(\S*)?(\s.*)?\?{2,}\s*$/i,
         /^(\s*\S+\s+)?when(\S*)?(\s.*)?\?{2,}\s*$/i,
         /^(\s*\S+\s+)?what(\S*)?(\s.*)?\?{2,}\s*$/i,
         /^(\s*\S+\s+)?who(\S*)?(\s.*)?\?{2,}\s*$/i,
         /^(\s*\S+\s+)?how(\S*)?(\s.*)?\?{2,}\s*$/i
      response = @@playfortime.sample.gsub(/:from/,from)
      [to:to,msg:response]

    # binary
    when /\?{2,}\s*$/i
      response = @@binaries.sample.gsub(/:from/,from)
      [to:to,msg:response]
    end
  end

  # Route messages like "beerbot: why ... " etc
  #
  # Assumes: msg has "beerbot: " stripped out via the dispatcher.

  def self.cmd msg,from:nil,to:nil,me:false,world:nil
    self.hear msg,from:from,to:to,world:world
  end

  def self.help details=nil
    ["Ask the bot questions ending in ??"]
  end

end
