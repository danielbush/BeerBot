
require_relative '../oracle.rb'
Oracle = ::BeerBot::Modules::Oracle
pwd = File.expand_path(File.dirname(__FILE__))
conffile = File.join(pwd,'test.json')

Oracle.create_datafile!(conffile)
Oracle.datafile(conffile)

describe "Oracle module" do
  it "should respond to ??" do
    replies = Oracle.cmd("??",from:'from1',to:'to1')
    replies.size.should == 1
    replies[0][:msg].class.should == String
  end
end
