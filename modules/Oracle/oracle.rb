# The files in this directory are part of BeerBot, a a ruby irc bot library.
# Copyright (C) 2013,2014 Daniel Bush
# This program is distributed under the terms of the GNU
# General Public License.  A copy of the license should be
# enclosed with this project in the file LICENSE.  If not
# see <http://www.gnu.org/licenses/>.

require 'BeerBot'

module BeerBot; module Modules; end; end

# This module responds to messages that end with 2 or more question
# marks eg ??, ??? etc.
#
# If we're lucky, it may make the bot sound vaguely human :D

module BeerBot::Modules::Oracle

  Config = ::BeerBot::Config
  BotMsg = ::BeerBot::BotMsg
  Utils  = ::BeerBot::Utils
  ParamExpand  = Utils::ParamExpand
  JsonDataFile = Utils::JsonDataFile

  # Get or set the datafile.
  #
  # If you don't specify filepath, BeerBot::Config's module_data will
  # be used, which is what should be used when running normally.

  def self.datafile filepath=nil
    if filepath then
      @filepath = filepath
      @data = nil
    else
      @filepath ||= File.join(Config.module_data('Oracle'),'data.json')
    end
  end

  # Create skeleton oracle conf file, enough for us to function.
  #
  # Returns instance of JsonDataFile with 'data' loaded into it.
  # 
  # Relies on self.datafile.

  def self.create_datafile! filepath,data=nil
    unless data then
      data = {
        yesnomaybe:["No","Yes","Maybe"],
        playfortime:[
          "Are you sure you should be asking that question ::from?",
          "* remains silent"
        ]
      }
    end
    JsonDataFile.create!(filepath,data)
  end

  # Relies on self.datafile.

  def self.data
    @data ||= JsonDataFile.new(self.datafile)
    @data.data
  end

  def self.hear msg,to:nil,from:nil,me:false,world:nil
    replyto = me ? from : to
    unless /\?{2,}\s*$/i === msg
      return nil
    end
    # Answers that tend towards yes/no/in-between type answers.
    binaries = self.data['yesnomaybe']
    # Answers that try to deal with non-binary type questions.
    playfortime = self.data['playfortime']
    selected = nil
    case msg
    when /what\s+about\s+/i
      selected = binaries
    when /\bwhere/i,
         /\bwhy/i,
         /\bwhen/i,
         /\bwhat[A-z']{0,3}\b/i,
         /\bwho[A-z']{0,3}\b/i,
         /\bwhich/i,  # which + ?? = probably a question with which
         /\bwhom/i,
         /\bhow/i
      selected = playfortime
    else
      selected = binaries
    end
    response,err = ParamExpand.expand(selected.sample,from:from,to:to)
    BotMsg.actionify([to:replyto,msg:response])
  end

  # Route messages like "beerbot: why ... " etc
  #
  # Assumes: msg has "beerbot: " stripped out via the dispatcher.

  def self.cmd msg,from:nil,to:nil,me:false,world:nil
    self.hear msg,from:from,to:to,world:world
  end

  def self.help arr=[]
    ["Ask the bot questions ending in ??"]
  end

end
