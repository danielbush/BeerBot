require 'CronR' # For scheduler

require_relative 'beerbot/00.utils/utils'
require_relative 'beerbot/00.utils/InOut'
require_relative 'beerbot/01.connect/IRCConnection'
require_relative 'beerbot/01.bot/botmsg'
require_relative 'beerbot/01.bot/BotModule'
require_relative 'beerbot/01.bot/Bot'
require_relative 'beerbot/02.codecs/irc'
require_relative 'beerbot/06.dispatchers/dispatcher'
require_relative 'beerbot/70.scheduler/scheduler'
require_relative 'beerbot/config'
require_relative 'beerbot/kernel'

module BeerBot
  module Modules
  end
end
