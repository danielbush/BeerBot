# The files in this directory are part of BeerBot, a a ruby irc bot library.
# Copyright (C) 2013 Daniel Bush
# This program is distributed under the terms of the GNU
# General Public License.  A copy of the license should be
# enclosed with this project in the file LICENSE.  If not
# see <http://www.gnu.org/licenses/>.

path = File.expand_path(File.dirname(__FILE__))
require path+'/../../utils/DataFile'

module BeerBot; module Modules; end; end

# This module responds to messages that end with 2 or more question
# marks eg ??, ??? etc.
#
# If we're lucky, it may make the bot sound vaguely human :D

module BeerBot::Modules::Oracle

  @@path = File.expand_path(File.dirname(__FILE__))
  @@data = BeerBot::Utils::JsonDataFile.new(@@path+'/data.json')

  def self.hear2 msg,to:nil,from:nil,world:nil
    unless /\?{2,}\s*$/i === msg
      return nil
    end
    # Answers that tend towards yes/no/in-between type answers.
    binaries = @@data.data['yesnomaybe']
    # Answers that try to deal with non-binary type questions.
    playfortime = @@data.data['playfortime']
    case msg
    when /what\s+about\s+/i
      response = binaries.sample.gsub(/:from/,from)
      [to:to,msg:response]
    when /\bwhere/i,
         /\bwhy/i,
         /\bwhen/i,
         /\bwhat[A-z']{0,3}\b/i,
         /\bwho/i,
         /\bwhom/i,
         /\bhow/i
      response = playfortime.sample.gsub(/:from/,from)
      [to:to,msg:response]
    else
      response = binaries.sample.gsub(/:from/,from)
      [to:to,msg:response]
    end
  end

  # hear2 is simpler and does the same, possibly better job than this.

  def self.hear1 msg,to:nil,from:nil,world:nil
    # Answers that tend towards yes/no/in-between type answers.
    binaries = @@data.data['yesnomaybe']
    # Answers that try to deal with non-binary type questions.
    playfortime = @@data.data['playfortime']

    case msg

    # binary
    when /^(\s*\S+\s+)?what about(\s.*)?\?{2,}\s*$/i
      response = binaries.sample.gsub(/:from/,from)
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
      response = playfortime.sample.gsub(/:from/,from)
      [to:to,msg:response]

    # binary
    when /\?{2,}\s*$/i
      response = binaries.sample.gsub(/:from/,from)
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

  class << self
    alias_method :hear , :hear2
  end

end
