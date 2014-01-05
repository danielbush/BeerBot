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

end
