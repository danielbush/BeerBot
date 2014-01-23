require File.dirname(__FILE__)+"/../lib/bot/Bot.rb"
require 'pp'

Bot = ::BeerBot::Bot
PATH = File.dirname(__FILE__)
# This path should exist and contain the Facts module.
REAL_MODULE_PATH = File.expand_path(PATH) + '/../lib/modules'
TEST_MODULE_PATH = File.expand_path(PATH) + '/test_modules'

describe "the Bot class",:bot => true do
  describe "running modules in lib/modules" do
    # Test that one of the include modules that comes with beerbot
    # can be loaded and accessed.
    it "should be able to access teh Facts module" do
      bot = Bot.new('testbot',REAL_MODULE_PATH,modules:['Facts','Oracle'])
      botmsg = bot.cmd('zzzz?',from:'me',to:'you')
      botmsg[0][:msg].class.should == String
    end

    it "can use the test module path" do
      bot = Bot.new('testbot',TEST_MODULE_PATH,modules:['TestModule'])
      expect {BeerBot::Modules::TestModule}.to_not raise_error
    end

  end

  describe "module loading and setting" do
  end

  describe "exclusive mode" do
    it "should be able to override Bot#cmd" do
      #bot = Bot.new('testbot',modules:[TestModule.new('standard-mod')])
    end
    it "should be able to override Bot#hear"
  end

end
