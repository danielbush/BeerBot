Gem::Specification.new do |s|
  s.name        = 'beerbot'
  s.version     = '0.2.1'
  s.date        = '2014-09-09'
  s.summary     = "A ruby 2.0 bot"
  s.description = "Out of the box you get an irc bot, but beerbot could be so much more...",
  s.authors     = ["Daniel Bush"]
  s.email       = 'dlb.id.au@gmail.com'
  s.executables << 'beerbot-run-irc.rb'
  s.files       = [
    "lib/beerbot/00.utils/utils.rb",
    "lib/beerbot/00.utils/InOut.rb",
    "lib/beerbot/01.connect/IRCConnection.rb",
    "lib/beerbot/01.bot/BotModule.rb",
    "lib/beerbot/01.bot/botmsg.rb",
    "lib/beerbot/01.bot/Bot.rb",
    "lib/beerbot/02.codecs/irc.rb",
    "lib/beerbot/06.dispatcher.rb",
    "lib/beerbot/70.scheduler/scheduler.rb",
    "lib/beerbot/config.rb",
    "lib/beerbot/kernel.rb",
    "lib/beerbot.rb",
  ]
  s.homepage    = 'http://github.com/danielbush/BeerBot'
  s.license       = 'GPL'
  s.add_runtime_dependency 'pry'
  s.add_runtime_dependency 'sqlite3'
  s.add_runtime_dependency 'CronR','= 0.1.6'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'byebug'
end
