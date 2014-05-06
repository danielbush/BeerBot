require 'CronR' # For scheduler

require_relative 'BeerBot/00.utils/utils'
require_relative 'BeerBot/00.utils/DataFile'
require_relative 'BeerBot/00.utils/InOut'
require_relative 'BeerBot/01.connect/IRCConnection'
require_relative 'BeerBot/01.bot/botmsg'
require_relative 'BeerBot/01.bot/BotModule'
require_relative 'BeerBot/01.bot/Bot'
require_relative 'BeerBot/01.bot/BotMsgMore'
require_relative 'BeerBot/02.protocols/irc'
require_relative 'BeerBot/06.dispatchers/dispatcher'
require_relative 'BeerBot/70.scheduler/scheduler'
require_relative 'BeerBot/Config'

module BeerBot
  module Modules
  end
end
