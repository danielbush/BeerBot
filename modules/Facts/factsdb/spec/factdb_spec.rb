require 'pp'
require 'byebug'
require_relative "../factsdb.rb"

dbfile = File.expand_path(File.dirname(__FILE__))+'/facts.db'
File.unlink(dbfile) if File.exists?(dbfile)
DB = FactsDb
DB.dbfile = dbfile
DB.build_tables!

describe "FactsDb module" do
  
  describe "adding terms" do

    it "should store the term" do
      r = DB.add('term1','value1')
      DB.term('term1').should == ['value1']
    end

    it "should not add terms that use square brackets" do
      DB.valid_term?("term[1]").should == false
      DB.add('term[1]','foo').should == false
    end

    it "valid_term? can be used to determine if a term is usable" do
      DB.valid_term?(",term").should == false
      DB.valid_term?("!term").should == false
      DB.valid_term?("term").should == true
    end

    it "should not add terms that start with command prefix" do
      DB.add(',term','foo').should == false
      DB.add('!term','foo').should == false
      DB.add('term3','foo').should == []
      DB.term('term3').should == ['foo']  # just checking
    end

    it "should preserve mode" do
      DB.add 'term4','val4'
      DB.set_mode 'term4','rand'
      DB.add 'term4','val5'
      DB.get_mode('term4').should == 'rand'
    end

  end

  describe "fetching terms",:fetching => true do
    before(:each) do
      DB.delete('term-f')
      DB.delete('term-f-1')
      DB.delete('term-f-n')
      DB.delete('action-f')
    end

    it "should fetch all entries if no number specified" do
      DB.add("term-f","foo")
      DB.add("term-f","bar")
      DB.term('term-f').should == ['foo','bar']
    end

    it "should fetch nth entry if n is specified" do
      DB.add("term-f","foo")
      DB.add("term-f","bar")
      # TODO...
    end

  end

  describe "deleting terms",:deleting => true do
  end

  describe "searching terms" do
    it "should return an array of terms that match" do
      DB.search("term").size.should > 0
      DB.search("foo").size.should > 0
    end
  end

  describe "insert terms before", :before => true do

    before(:each) do
      DB.delete('term-before')
      DB.add("term-before","A")
      DB.add("term-before","B")
      DB.add("term-before","C")
      DB.add("term-before","D")
    end

    it "should return false if indices are not valid" do
      result = DB.before('term-before',11,3)  # 11 before 3
      result.should == nil
    end

    it "should move first entry before the second entry" do
      result = DB.before('term-before',3,1)  # 3 before 1
      DB.term('term-before').should == ['A','D','B','C']
    end

  end

  describe "swapping terms" do

    before(:each) do
      DB.delete('term-swap')
      DB.add("term-swap","A")
      DB.add("term-swap","B")
      DB.add("term-swap","C")
      DB.add("term-swap","D")
    end

    it "should return false if indices are not valid" do
      DB.term('term-swap').should == ['A','B','C','D']
      result = DB.swap('term-swap',11,3)
      result.should == nil
      DB.term('term-swap').should == ['A','B','C','D']
    end

    it "should swap entries if indices are valid" do
      result = DB.swap('term-swap',1,3)
      result.should == ['A','D','C','B']
      DB.term('term-swap').should == ['A','D','C','B']
    end

    it "should return false if term doesn't exist" do
      result = DB.swap('term-swap-notexists',11,3)
      result.should == nil
      DB.term('term-swap').should == ['A','B','C','D']
    end

  end


  describe "term modes" do

    before(:each) do
      DB.delete('term-rand')
      DB.add("term-rand","A")
      DB.add("term-rand","B")
    end

    it "should be able to get and set the mode of the term" do
      DB.get_mode("term-rand").should == nil
      DB.set_mode("term-rand","rand")
      DB.get_mode("term-rand").should == "rand"
      DB.set_mode("term-rand",nil)
      DB.get_mode("term-rand").should == nil
    end

  end


end
