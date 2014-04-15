
  # TODO
  #it "should not add terms that use square brackets" do
  #/failed/i.should === Facts.cmd("term[foo] is: foo")[0][:msg]

  #it "should not add terms that start with command prefix" do
  # TODO
  #/failed/i.should === Facts.cmd(",term is: foo")[0][:msg]
  #/noted/i.should === Facts.cmd("term2 is: foo")[0][:msg]

  # it "should fetch nth entry if n is specified" do
  # TODO
  #Facts.cmd("term-f 0")[0][:msg].should == "term-f[0] is: foo"
  #Facts.cmd("term-f 1")[0][:msg].should == "term-f[1] is: bar"

    it "should actionify term entries that start with * when in reply mode" do
      DB.add("action-f","* does something")
      DB.set_mode('action-f','reply')
      # TODO
      #Facts.cmd('action-f',to:'chan')[0][:action].should == "does something"
    end

    it "should substitute ::from with the sender's nick" do
      DB.add("term-f-1","hi ::from")

      # Reply mode.
      DB.set_mode('term-f-1','reply')
      botmsg = Facts.cmd('term-f-1',from:'from',to:'chan')
      botmsg[0][:msg].should == "hi from"

      # Not sure if I want to do the other modes...

      # Nomode:
      DB.set_mode('term-f-1',nil) # no mode
      botmsg = Facts.cmd('term-f-1',from:'from',to:'chan')
      botmsg[0][:msg].should match(/hi ::from/)
      botmsg = Facts.cmd('term-f-1 0',from:'from',to:'chan')
      #botmsg[0][:msg].should match(/hi from/)

      # Rand mode:
      DB.set_mode('term-f-1','rand')
      botmsg = Facts.cmd('term-f-1',from:'from',to:'chan')
      botmsg[0][:msg].should match(/hi from/)
    end

    it "should substitute correctly if non-character text is next to the parameters" do
      DB.add('term-f-n','a ::from, foo')
      DB.set_mode('term-f-n','reply')
      botmsg = Facts.cmd('term-f-n',from:'from',to:'chan')
      botmsg[0][:msg].should match("a from, foo")
    end

    it "should substitute ::n (n numeric) with parameters" do
      DB.add('term-f-n',"args are ::1")
      DB.set_mode('term-f-n','reply')
      Facts.cmd("term-f-n test")[0][:msg].should == "args are test"
    end

    it "should not substitute ::n if not in parameters" do
      DB.add('term-f-n',"args are ::3")
      DB.set_mode('term-f-n 1 2','reply')
      Facts.cmd("term-f-n test")[0][:msg].should match("args are ::3")
    end

    it "should substitute ::n|::from with ::from if ::n (numeric) not provided" do
      DB.add('term-f-n',"args are ::1|::from")
      DB.set_mode('term-f-n','reply')
      Facts.cmd("term-f-n test")[0][:msg].should == "args are test"
      Facts.cmd("term-f-n",from:'foo')[0][:msg].should == "args are foo"
    end

    # Might do this at some point.

    it "should substitute ::n|? (n numeric) if they're available" 

    it "should randomly substitute ::from|?" 

  #describe "searching terms" do
      #/term-f/.should === Facts.cmd("term?")[0][:msg]
      #/term-f/.should === Facts.cmd("te?")[0][:msg]

    it "should move terms if indices are valid" do
      Facts.cmd("term-before 3 before 1")[0][:msg]
      DB.term('term-before').should == ['A','D','B','C']
    end
    it "should complain if indices are not valid" do
      Facts.cmd("term-before 11 before 3")[0][:msg]
      DB.term('term-before').should == ['A','B','C','D']
    end

    it "should swap terms if indices are valid" do
      Facts.cmd("term-swap swap 1 3")[0][:msg]
      arr = DB.term('term-swap')
      arr.should == ['A','D','C','B']
    end

    it "should complain if indices are not valid" do
      Facts.cmd("term-swap swap 11 3")[0][:msg]
      DB.term('term-swap').should == ['A','B','C','D']
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
        DB.term('sterm')[0].should == 'quick fox'
      end
    end

    before(:each) do
      DB.delete('sterm')
      DB.add('sterm',"quick fox")
      DB.add('sterm',"lazy cow")
      DB.add('sterm',"/abc/xyz/")
    end

    it "should perform s// on a term entry" do
      Facts.cmd("sterm 0 s/qui/bla/")
      DB.term('sterm')[0].should == 'black fox'
    end

    it "should handle bad regexes" do
      botmsg = Facts.cmd("sterm 0 s/[q/b/")
      botmsg[0][:msg].class.should == String
      DB.term('sterm')[0].should == 'quick fox'
    end

    it "should handle replacements that use forward slashes" do
      Facts.cmd("sterm 2 s/\\\//z/")
      DB.term('sterm')[2].should == 'zabc/xyz/'
      Facts.cmd("sterm 2 s/\\\//0/g")
      DB.term('sterm')[2].should == 'zabc0xyz0'
    end

  end

    describe "turning a term into a reply" do

      it "should turn reply-mode on" do
        Facts.cmd("term-rand reply")[0][:msg].should match(/^Setting mode to reply/)
      end

      it "should reply directly" do
        Facts.cmd("term-rand reply")
        DB.get_mode('term-rand').should == 'reply'
        Facts.cmd("term-rand")[0][:msg].should match(/^[AB]$/)
      end

      it "should create actions for items that start with '*'" do
        DB.add("term-rand-2","* does something")
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

  describe "interpolation",:interpolation => true do
    before(:each) do
      DB.delete('term-1')
    end
    it "should interpolate ',,'" do
      DB.add('term-1','foo')
      msg1,*other = Facts.cmd("... ,,term-1 ...")
      msg1[:msg].should match('foo')
    end
    it "should handle arguments in reply mode" do
      DB.add('term-1','foo ::1 ::2 ::from')
      DB.set_mode('term-1','reply')
      msg1,*other = Facts.cmd("... ,,term-1 a b ...",from:'from')
      msg1[:msg].should match('foo a b from')
    end
  end

