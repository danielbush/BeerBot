Gem::Specification.new do |s|
  s.name        = 'beerbot'
  s.version     = '0.1.2'
  s.date        = '2014-04-21'
  s.summary     = "An ruby 2.0 bot"
  s.description = "Out of the box you get an irc bot, but beerbot could be so much more...",
  s.authors     = ["Daniel Bush"]
  s.email       = 'dlb.id.au@gmail.com'
  s.executables << 'run-irc.rb'
  s.files       = [
    "lib/BeerBot/00.utils/utils.rb",
    "lib/BeerBot/00.utils/param_expand.rb",
    "lib/BeerBot/00.utils/sentence_expand.rb",
    "lib/BeerBot/00.utils/DataFile.rb",
    "lib/BeerBot/00.utils/InOut.rb",
    "lib/BeerBot/00.utils/More.rb",
    "lib/BeerBot/00.utils/world/World.rb",
    "lib/BeerBot/00.utils/world/IRCWorld.rb",
    "lib/BeerBot/01.connect/Connection.rb",
    "lib/BeerBot/01.connect/IRCConnection.rb",
    "lib/BeerBot/01.bot/botmsg.rb",
    "lib/BeerBot/01.bot/BotModule.rb",
    "lib/BeerBot/01.bot/Bot.rb",
    "lib/BeerBot/01.bot/BotMsgMore.rb",
    "lib/BeerBot/02.protocols/irc.rb",
    "lib/BeerBot/06.dispatchers/dispatcher.rb",
    "lib/BeerBot/70.scheduler/scheduler.rb",
    "lib/BeerBot/Config.rb",
    "lib/BeerBot.rb",
    "lib/RunIRC.rb",
  ]
  s.homepage    = 'http://github.com/danielbush/BeerBot'
  s.license       = 'GPL'
  s.add_runtime_dependency 'pry'
  s.add_runtime_dependency 'sqlite3'
  s.add_runtime_dependency 'CronR','>= 0.1.3'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'byebug'
end
