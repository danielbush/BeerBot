require_relative "../../lib/beerbot/01.bot/Bot.rb"
require 'pp'

Bot = ::BeerBot::Bot
PATH = File.dirname(__FILE__)
TEST_MODULE_PATH = File.expand_path(PATH) + '/test_modules'

describe "the Bot class",:bot => true do

  describe "loading" do

    it "can load the modules on the module path" do
      bot = Bot.new
      bot.load!(['TestModule1','TestModule2'],TEST_MODULE_PATH)
      bot.map{|b|
        [b[:status],b[:name]]
      }.should == [[true,'TestModule1'],[true,'TestModule2']]
      bot.has_errors.should == false
    end

    it "will throw load errors" do
      expect {
        Bot.new.load!(['BadModule1'],TEST_MODULE_PATH)
      }.to raise_error(LoadError)
    end

    it "can list valid modules" do
      bot = Bot.new
      bot.load!(['TestModule1','TestModule2'],TEST_MODULE_PATH)
      arr = bot.valid_modules.map{|bm| bm[:name]}
      arr.size.should == 2
      arr[0].should == 'TestModule1'
    end

  end

  describe "init" do

    it "can call init on all modules that have an init method and pass config" do
      bot = Bot.new
      bot.load!(['TestModule1','TestModule2'],TEST_MODULE_PATH)
      bot[0][:name].should == 'TestModule1'
      mod0 = bot[0][:mod]
      mod1 = bot[1][:mod]
      def mod0.init config
        @config ||= config
      end
      def mod0.config config=nil
        @config
      end
      mod0.config.should  == nil
      config = BeerBot::Config.new(:blah => true)

      bot.init(config)
      mod0.config.should  == config
      mod1.respond_to?(:init).should == false
    end

  end

  describe "config" do

    it "can update all modules that have a config method" do
      bot = Bot.new
      bot.load!(['TestModule1','TestModule2'],TEST_MODULE_PATH)
      bot[0][:name].should == 'TestModule1'

      # Set a config method on only one of the modules...
      mod0 = bot[0][:mod]
      mod1 = bot[1][:mod]
      # This is the sort of method a bot module would implement...
      def mod0.config config=nil
        @config ||= config
      end
      mod0.config.should  == nil
      config = BeerBot::Config.new(:blah => true)

      expect {
        bot.update_config(config)
      }.to_not raise_error
      mod0.config.should == config
      mod1.respond_to?(:config).should == false
    end

  end

  describe "running" do

    describe "handling replies from modules" do

      it "can handle single botmsg's" do
        bot = Bot.new
        mod1 = Object.new
        def mod1.cmd msg,**kargs
          [false,{to:'to1',msg:'msg1'}]
        end
        bot.push({status:true,mod:mod1})
        replies = bot.cmd('test')
        replies.size.should == 1
      end

      it "can handle array botmsg's" do
        bot = Bot.new
        mod1 = Object.new
        def mod1.cmd msg,**kargs
          [false,[to:'to1',msg:'msg1']]
        end
        bot.push({status:true,mod:mod1})
        replies = bot.cmd('test')
        replies.size.should == 1
      end

      it "can handle proc's that return single or array botmsg's",:foo => true do
        bot = Bot.new
        mod1 = Object.new
        def mod1.cmd msg,**kargs
          lambda {
            [to:'to1',msg:'msg1']
          }
        end
        bot.push({status:true,mod:mod1})
        replies = bot.cmd('test')
        replies.size.should == 1

        def mod1.cmd msg,**kargs
          [true,
            lambda {
              [to:'to1',msg:'msg1']
            }]
        end
        bot.push({status:true,mod:mod1})
        replies = bot.cmd('test')
        replies.size.should == 1
      end

      it "should follow through if bool is false in array format" do
        bot = Bot.new
        mod1 = Object.new
        mod2 = Object.new
        def mod1.cmd msg,**kargs
          [false,[to:'to1',msg:'msg1']]
        end
        def mod2.cmd msg,**kargs
          [false,[to:'to2',msg:'msg2']]
        end
        bot.push({status:true,mod:mod1})
        bot.push({status:true,mod:mod2})

        replies = bot.cmd('test')
        replies.size.should == 2
        replies[0].should == {to:'to1',msg:'msg1'}
        replies[1].should == {to:'to2',msg:'msg2'}
      end

      it "should stop if bool is true (regardless of 2nd value) in array format" do
        bot = Bot.new
        mod1 = Object.new
        mod2 = Object.new
        def mod1.cmd msg,**kargs
          [true,[to:'to1',msg:'msg1']]
        end
        def mod2.cmd msg,**kargs
          [false,[to:'to2',msg:'msg2']]
        end
        bot.push({status:true,mod:mod1})
        bot.push({status:true,mod:mod2})

        replies = bot.cmd('test')
        replies.size.should == 1
        replies[0].should == {to:'to1',msg:'msg1'}
      end

      it "should handle single object repsonse format" do
        bot = Bot.new
        mod1 = Object.new
        mod2 = Object.new
        def mod1.cmd msg,**kargs
          [to:'to1',msg:'msg1']
        end
        bot.push({status:true,mod:mod1})

        replies = bot.cmd('test')
        replies.size.should == 1
        replies[0].should == {to:'to1',msg:'msg1'}
      end

      it "should suppress for handle single object repsonse format" do
        bot = Bot.new
        mod1 = Object.new
        mod2 = Object.new
        def mod1.cmd msg,**kargs
          [to:'to1',msg:'msg1']
        end
        def mod2.cmd msg,**kargs
          [to:'to2',msg:'msg2']
        end
        bot.push({status:true,mod:mod1})
        bot.push({status:true,mod:mod2})

        replies = bot.cmd('test')
        replies.size.should == 1
        replies[0].should == {to:'to1',msg:'msg1'}
      end

      it "should return empty array if nothing (single value format)" do
        bot = Bot.new
        mod = Object.new 
        def mod.cmd msg,**kargs
          nil
        end
        bot.push({mod:mod,status:true})

        replies = bot.cmd('foo')
        replies.class.should == Array
        replies.size.should == 0

        replies = bot.cmd(/foo/)  # some other random object
        replies.class.should == Array
        replies.size.should == 0
      end

      it "should return empty array not-botmsg (single value format" do
        bot = Bot.new
        mod = Object.new 
        def mod.cmd msg,**kargs
          Object.new
        end
        bot.push({mod:mod,status:true})

        replies = bot.cmd('foo')
        replies.class.should == Array
        replies.size.should == 0
      end

      it "bot should still run even if no modules" do
        bot = Bot.new
        replies = bot.cmd("foo")
        replies.class.should == Array
        replies.size.should == 0
      end

    end

    describe "bot listening" do

      it "should run the modules in order" do
        bot = Bot.new
        bot.load!(['TestModule1','TestModule2'],TEST_MODULE_PATH)
        replies = bot.hear('test')
        replies.size.should == 1
        replies[0][:msg].should == 'hear testmodule1'

        bot = Bot.new
        bot.load!(['TestModule2','TestModule1'],TEST_MODULE_PATH)
        replies = bot.hear('test')
        replies[0][:msg].should == 'hear testmodule2'
      end

    end

    describe "bot actions" do
      it "should run the modules in order" do
        bot = Bot.new
        bot.load!(['TestModule1','TestModule2'],TEST_MODULE_PATH)
        replies = bot.action('test')
        replies.size.should == 1
        replies[0][:msg].should == 'action testmodule1'
      end
    end

    describe "event handling" do
      it "handle a join event" do
        bot = Bot.new
        bot.load!(['TestModule1'],TEST_MODULE_PATH)
        replies = bot.event(:join,channel:'#foo',nick:'jonny')
        replies.size.should == 1
        replies[0][:to].should == '#foo'
        replies[0][:msg].should == 'jonny'
      end
    end

    describe "overriding cmd" do
      it "should override" do
        bot = Bot.new
        bot.load!(['TestModule1','TestModule2'],TEST_MODULE_PATH)
        bot.set_cmd {
          "foo"
        }
        bot.cmd("test").should == 'foo'
        bot.set_cmd  # unset it
        bot.cmd("test").class.should == Array
      end
    end

    describe "overriding hear" do
      it "should override" do
        bot = Bot.new
        bot.load!(['TestModule1','TestModule2'],TEST_MODULE_PATH)
        bot.set_hear {
          "foo"
        }
        bot.hear("test").should == 'foo'
        bot.set_hear  # unset it
        bot.hear("test").class.should == Array
      end
    end

  end

  describe "help functionality" do

    it "should offer help if module name is given as first argument" do
      bot = Bot.new
      bot.load!(['TestModule1'],TEST_MODULE_PATH)
      replies = bot.help(["TestModule1","topic1"],to:'to',from:'from')
      replies.find{|r| r[:msg] == 'topic1'}.should_not == nil
    end

    it "should handle subtopics" do
      bot = Bot.new
      bot.load!(['TestModule1'],TEST_MODULE_PATH)
      replies = bot.help(["TestModule1","topic1",'subtopic1'],to:'to',from:'from')
      replies.find{|r| r[:msg] == 'topic1/subtopic1'}.should_not == nil
    end
    
  end

end
