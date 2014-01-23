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
    it "should be able to access the Facts module" do
      bot = Bot.new('testbot',REAL_MODULE_PATH,modules:['Facts','Oracle'])
      botmsg = bot.cmd('zzzz?',from:'me',to:'you')
      botmsg[0][:msg].class.should == String
    end

    it "can use the test module path" do
      bot = Bot.new('testbot',TEST_MODULE_PATH,modules:['TestModule'])
      expect {BeerBot::Modules::TestModule}.to_not raise_error
      BeerBot::Modules::TestModule.make('test1')
      botmsg = bot.cmd('zzzz?',from:'me',to:'you')
      botmsg[0][:msg].should == 'test1'
    end

  end

  describe "module loading and setting" do
  end

  describe "exclusive mode" do
    it "should be able to override Bot#cmd and unset it" do
      bot = Bot.new('testbot',TEST_MODULE_PATH,modules:['TestModule'])
      BeerBot::Modules::TestModule.make('test1')
      bot.cmd('zzzz?',from:'me',to:'you')[0][:msg].should == 'test1'
      bot.set_cmd {|msg,**kargs|
        [to:kargs[:from],msg:'override']
      }
      bot.cmd('zzzz?',from:'me',to:'you')[0][:msg].should == 'override'
      bot.set_cmd  # no block
      bot.cmd('zzzz?',from:'me',to:'you')[0][:msg].should == 'test1'
    end

    it "should be able to override Bot#hear"

  end

end
