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
      /failed/i.should === Facts.cmd("term[foo] is: foo")[0][:msg]
    end

    it "should not add terms that start with command prefix" do
      Facts.valid_term?(",term").should == false
      Facts.valid_term?("!term").should == false
      Facts.valid_term?("term").should == true

      Facts.add(',term','foo').should == false
      Facts.add('!term','foo').should == false
      Facts.add('term3','foo').should == []
      Facts.term('term3').should == ['foo']  # just checking

      /failed/i.should === Facts.cmd(",term is: foo")[0][:msg]
      /noted/i.should === Facts.cmd("term2 is: foo")[0][:msg]
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

  describe "insert terms before", :before => true do
    before(:each) do
      Facts.delete('term-before')
      Facts.add("term-before","A")
      Facts.add("term-before","B")
      Facts.add("term-before","C")
      Facts.add("term-before","D")
    end
    describe "low level interface" do
      it "should return false if indices are not valid" do
        result = Facts.before('term-before',11,3)  # 11 before 3
        result.should == nil
      end
      it "should move first entry before the second entry" do
        result = Facts.before('term-before',3,1)  # 3 before 1
        Facts.term('term-before').should == ['A','D','B','C']
      end
    end
    it "should move terms if indices are valid" do
      Facts.cmd("term-before 3 before 1")[0][:msg]
      Facts.term('term-before').should == ['A','D','B','C']
    end
    it "should complain if indices are not valid" do
      Facts.cmd("term-before 11 before 3")[0][:msg]
      Facts.term('term-before').should == ['A','B','C','D']
    end
  end

  describe "swapping terms" do

    before(:each) do
      Facts.delete('term-swap')
      Facts.add("term-swap","A")
      Facts.add("term-swap","B")
      Facts.add("term-swap","C")
      Facts.add("term-swap","D")
    end

    describe "low level interface" do

      it "should return false if indices are not valid" do
        Facts.term('term-swap').should == ['A','B','C','D']
        result = Facts.swap('term-swap',11,3)
        result.should == nil
        Facts.term('term-swap').should == ['A','B','C','D']
      end

      it "should swap entries if indices are valid" do
        result = Facts.swap('term-swap',1,3)
        result.should == ['A','D','C','B']
        Facts.term('term-swap').should == ['A','D','C','B']
      end

      it "should return false if term doesn't exist" do
        result = Facts.swap('term-swap-notexists',11,3)
        result.should == nil
        Facts.term('term-swap').should == ['A','B','C','D']
      end

    end

    it "should swap terms if indices are valid" do
      Facts.cmd("term-swap swap 1 3")[0][:msg]
      arr = Facts.term('term-swap')
      arr.should == ['A','D','C','B']
    end

    it "should complain if indices are not valid" do
      Facts.cmd("term-swap swap 11 3")[0][:msg]
      Facts.term('term-swap').should == ['A','B','C','D']
    end
  end

  describe "s// terms" do
    describe "low level interface" do
      it "can safely extract a regex and replacement string" do
        examples = [
          "s/a/9/",
          "s/a/9/g"
        ]
        rx,replacement,flags = Facts.extract_sed_string(examples[0])
        rx.source.should == 'a'
        replacement.should === '9'
        flags.should == []
        rx,replacement,flags = Facts.extract_sed_string(examples[1])
        rx.source.should == 'a'
        replacement.should === '9'
        flags.should == ['g']
      end
      it "should handle bad regexes and return error" do
        rx,msg,_ = Facts.extract_sed_string('s/[q/b/]')
        rx.should == nil
        msg.should.class == String
        Facts.term('sterm')[0].should == 'quick fox'
      end
    end

    before(:each) do
      Facts.delete('sterm')
      Facts.add('sterm',"quick fox")
      Facts.add('sterm',"lazy cow")
      Facts.add('sterm',"/abc/xyz/")
    end

    it "should perform s// on a term entry" do
      Facts.cmd("sterm 0 s/qui/bla/")
      Facts.term('sterm')[0].should == 'black fox'
    end

    it "should handle bad regexes" do
      botmsg = Facts.cmd("sterm 0 s/[q/b/")
      botmsg[0][:msg].class.should == String
      Facts.term('sterm')[0].should == 'quick fox'
    end

    it "should handle replacements that use forward slashes" do
      Facts.cmd("sterm 2 s/\\\//z/")
      Facts.term('sterm')[2].should == 'zabc/xyz/'
      Facts.cmd("sterm 2 s/\\\//0/g")
      Facts.term('sterm')[2].should == 'zabc0xyz0'
    end

  end

  describe "term modes" do

    before(:each) do
      Facts.delete('term-rand')
      Facts.add("term-rand","A")
      Facts.add("term-rand","B")
    end

    it "should be able to get and set the mode of the term" do
      Facts.get_mode("term-rand").should == nil
      Facts.set_mode("term-rand","rand")
      Facts.get_mode("term-rand").should == "rand"
      Facts.set_mode("term-rand",nil)
      Facts.get_mode("term-rand").should == nil
    end

    describe "turning a term into a reply" do

      it "should turn reply-mode on" do
        Facts.cmd("term-rand reply")[0][:msg].should match(/^Setting mode to reply/)
      end

      it "should reply directly" do
        Facts.cmd("term-rand reply")
        Facts.get_mode('term-rand').should == 'reply'
        Facts.cmd("term-rand")[0][:msg].should match(/^[AB]$/)
      end

      it "should create actions for items that start with '*'" do
        Facts.add("term-rand-2","* does something")
        Facts.cmd("term-rand-2 reply")
        msg = Facts.cmd("term-rand-2")[0][:action]
        msg.should == 'does something'
      end
    end

    describe "randomising a term" do

      it "should turn randomising on" do
        Facts.cmd("term-rand rand")[0][:msg].should match(/^Setting mode to/)
        /already set/.should === Facts.cmd("term-rand rand")[0][:msg]
        /is:\s*[AB]/.should === Facts.cmd("term-rand")[0][:msg]
      end

    end

    describe "unsetting a mode" do
      it "should revert to default behaviour" do
        /^Setting mode to rand/.should === Facts.cmd("term-rand rand")[0][:msg]
        /^Turning off/.should === Facts.cmd("term-rand nomode")[0][:msg]
        /^\[0\]/.should === Facts.cmd("term-rand")[1][:msg]
        /^\[1\]/.should === Facts.cmd("term-rand")[2][:msg]
      end
    end

  end

end
