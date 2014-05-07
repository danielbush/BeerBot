require_relative "../lib/BeerBot/Config.rb"
require 'pp'
require 'byebug'

Config = BeerBot::Config

describe "Config", :utils => true do

  it "should load config data" do
    conf = Config.new
    conf.load({param1:1,param2:2})
    conf[:param1].should == 1
    conf[:param2].should == 2
    conf.load({param1:3,param2:4})
    conf[:param1].should == 3
    conf[:param2].should == 4
  end

  it "should have a scheduler" do
    conf = Config.new
    # We have to set it, but it's there to be set :)
    conf.scheduler.should == nil
  end

  it "should have an out-queue" do
    conf = Config.new
    conf.out.class.should == Queue
  end

  it "should have a reference to bot" do
    conf = Config.new
    # Once again, we have to set this at startup...
    conf.bot.should == nil
  end

  describe "module handling" do
    it "should provide module_data which provides datadir for given bot module" do
      conf = Config.new
      datadir = '/tmp' # TODO
      moduledir = File.join(
        File.expand_path(File.dirname(__FILE__)),
        '01.bot',
        'test_modules'
      )
      conf['datadir'] = datadir
      conf['moduledir'] = moduledir
      conf.module_data('TestModule1') {|path|
        path.should == '/tmp/modules/TestModule1'
      }
    end
  end

end

