require 'pp'
require File.dirname(__FILE__)+"/../facts.rb"

dbfile = File.expand_path(File.dirname(__FILE__))+'/facts.db'
Facts = ::BeerBot::Modules::Facts
File.unlink(dbfile) if File.exists?(dbfile)
Facts.set_db(dbfile)
Facts.build_tables!

describe "Facts module" do
  
  describe "adding terms" do

    it "should store the term" do
      Facts.add 'term1','value1'
      Facts.term('term1').should == ['value1']
    end

    it "should not add terms that use square brackets" do
      Facts.valid_term?("term[1]").should == false
      Facts.add('term[1]','foo').should == false
      /failed/i.should === Facts.cmd("term[foo] is foo")[0][:msg]
    end

    it "should not add terms that start with command prefix" do
      Facts.valid_term?(",term").should == false
      Facts.valid_term?("!term").should == false
      Facts.valid_term?("term").should == true

      Facts.add(',term','foo').should == false
      Facts.add('!term','foo').should == false
      Facts.add('term3','foo').should == []
      Facts.term('term3').should == ['foo']  # just checking

      /failed/i.should === Facts.cmd(",term is foo")[0][:msg]
      /noted/i.should === Facts.cmd("term2 is foo")[0][:msg]
    end

    # Add may sometimes delete the term and build a new one.
    it "should preserve mode" do
      Facts.add 'term4','val4'
      Facts.set_mode 'term4','rand'
      Facts.add 'term4','val5'
      Facts.get_mode('term4').should == 'rand'
    end

  end

  describe "fetching terms" do

    it "should fetch all entries if no number specified" do
      Facts.add('term-f','foo')
      Facts.add('term-f','bar')
      Facts.term('term-f').should == ['foo','bar']
    end

    it "should fetch nth entry if n is specified" do
      Facts.cmd("term-f 0")[0][:msg].should == "term-f[0] is: foo"
      Facts.cmd("term-f 1")[0][:msg].should == "term-f[1] is: bar"
    end

  end

  describe "searching terms" do
    it "should return an array of terms that match" do
      Facts.search("term").size.should > 0
      Facts.search("foo").size.should > 0
      /term-f/.should === Facts.cmd("term?")[0][:msg]
      /term-f/.should === Facts.cmd("te?")[0][:msg]
    end
  end

  describe "randomising a term" do

    Facts.add("term-rand","A")
    Facts.add("term-rand","B")

    it "should be able to get and set the mode of the term" do
      Facts.get_mode("term-rand").should == nil
      Facts.set_mode("term-rand","rand")
      Facts.get_mode("term-rand").should == "rand"
      Facts.set_mode("term-rand",nil)
      Facts.get_mode("term-rand").should == nil
    end

    it "should turn randomising on" do
      /^Randomising/.should === Facts.cmd("term-rand rand")[0][:msg]
      /^Unrandomising/.should === Facts.cmd("term-rand rand")[0][:msg]
      /^Randomising/.should === Facts.cmd("term-rand rand")[0][:msg]
      /[AB]/.should === Facts.cmd("term-rand")[0][:msg]
      /^Unrandomising/.should === Facts.cmd("term-rand rand")[0][:msg]
      /^\[0\]/.should === Facts.cmd("term-rand")[1][:msg]
      /^\[1\]/.should === Facts.cmd("term-rand")[2][:msg]
    end
  end

end
