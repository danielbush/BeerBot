require_relative "../../lib/BeerBot/01.bot/Bot.rb"
require 'pp'

Bot = ::BeerBot::Bot
PATH = File.dirname(__FILE__)
# This path should exist and contain the Facts module.
REAL_MODULE_PATH = File.expand_path(PATH) + '/../../lib/modules'
TEST_MODULE_PATH = File.expand_path(PATH) + '/test_modules'

describe "the Bot class",:bot => true do

  describe "loading" do

    it "can load the modules on the module path" do
      bot = Bot.new(TEST_MODULE_PATH,['TestModule1','TestModule2'])
      bot.map{|b|
        [b[:status],b[:name]]
      }.should == [[true,'TestModule1'],[true,'TestModule2']]
      bot.has_errors.should == false
    end

    it "will throw load errors" do
      expect {
        Bot.new(TEST_MODULE_PATH,['BadModule1'])
      }.to raise_error(LoadError)
    end

    it "can list valid modules" do
      bot = Bot.new(TEST_MODULE_PATH,['TestModule1','TestModule2'])
      arr = bot.valid_modules.map{|bm| bm[:name]}
      arr.size.should == 2
      arr[0].should == 'TestModule1'
    end

  end

  describe "running" do

    describe "bot commands" do
      it "should run the modules in order (cmd)" do
        bot = Bot.new(TEST_MODULE_PATH,['TestModule1','TestModule2'])
        replies = bot.cmd('test')
        replies.size.should == 1
        replies[0][:msg].should == 'cmd testmodule1'

        bot = Bot.new(TEST_MODULE_PATH,['TestModule2','TestModule1'])
        replies = bot.cmd('test')
        replies[0][:msg].should == 'cmd testmodule2'
      end

      it "should return an array-based botmsg" do
        bot = Bot.new(TEST_MODULE_PATH,['TestModule1'])
        # Note: we've rigged the test modules to echo back non-strings
        # to bot#run, #run should then do BotMsg.to_a on them.
        replies = bot.cmd({to:'to',msg:'some msg'})
        replies.class.should == Array
        replies.size.should == 1
        replies[0][:to].should == 'to'
        replies[0][:msg].should == 'some msg'
      end

      it "should return empty array if nothing" do
        bot = Bot.new(TEST_MODULE_PATH,['TestModule1'])
        replies = bot.cmd(nil)
        replies.class.should == Array
        replies.size.should == 0
        replies = bot.cmd(/foo/)  # some other random object
        replies.class.should == Array
        replies.size.should == 0
      end

      it "bot should still run even if no modules" do
        bot = Bot.new(TEST_MODULE_PATH,[])
        replies = bot.cmd("foo")
        replies.class.should == Array
        replies.size.should == 0
      end
    end

    describe "bot listening" do

      it "should run the modules in order" do
        bot = Bot.new(TEST_MODULE_PATH,['TestModule1','TestModule2'])
        replies = bot.hear('test')
        replies.size.should == 1
        replies[0][:msg].should == 'hear testmodule1'

        bot = Bot.new(TEST_MODULE_PATH,['TestModule2','TestModule1'])
        replies = bot.hear('test')
        replies[0][:msg].should == 'hear testmodule2'
      end

    end

    describe "event handling" do
      it "handle a join event" do
        bot = Bot.new(TEST_MODULE_PATH,['TestModule1'])
        replies = bot.event(:join,channel:'#foo',nick:'jonny')
        replies.size.should == 1
        replies[0][:to].should == '#foo'
        replies[0][:msg].should == 'jonny'
      end
    end

    describe "overriding cmd" do
      bot = Bot.new(TEST_MODULE_PATH,['TestModule1','TestModule2'])
      bot.set_cmd {
        "foo"
      }
      bot.cmd("test").should == 'foo'
      bot.set_cmd  # unset it
      bot.cmd("test").class.should == Array
    end

    describe "overriding hear" do
      bot = Bot.new(TEST_MODULE_PATH,['TestModule1','TestModule2'])
      bot.set_hear {
        "foo"
      }
      bot.hear("test").should == 'foo'
      bot.set_hear  # unset it
      bot.hear("test").class.should == Array
    end

  end

  describe "help functionality" do

    it "should offer help if module name is given as first argument" do
      bot = Bot.new(TEST_MODULE_PATH,['TestModule1'])
      replies = bot.help(["TestModule1","topic1"],to:'to',from:'from')
      replies.find{|r| r[:msg] == 'topic1'}.should_not == nil
    end

    it "should handle subtopics" do
      bot = Bot.new(TEST_MODULE_PATH,['TestModule1'])
      replies = bot.help(["TestModule1","topic1",'subtopic1'],to:'to',from:'from')
      replies.find{|r| r[:msg] == 'topic1/subtopic1'}.should_not == nil
    end
    
  end

end
