require_relative "../../lib/BeerBot/01.connect/IRCConnection"

describe 'IRCConnection' do

  IRCConnection = BeerBot::IRCConnection

  class MockConnection

    attr_reader :outq,:receiveq
    attr_accessor :running

    def initialize
      # What we emit to the user.
      @outq = Queue.new
      # What we receive from the user.
      @receiveq = Queue.new
    end

    def close
      @running = false
    end

    # For us, to push things into the connection.
    def push item
      @outq.enq item
    end

    # IRCConnection uses this to start the connection.
    def open *args
      @running = true
    end

    # IRCConnection waits on this.
    def gets
      @outq.deq
    end

    # IRCConnection writes to this.
    def print str
      @receiveq.enq str
    end

    def eof?
      not @running
    end

  end

  before(:each) {
    @conn = IRCConnection.new
    @mock = MockConnection.new
  }

  # BEWARE:
  # Errors may occur in a separate thread an never get picked up by
  # rspec.  If you can't join the thread, then maybe debug/log it's
  # behaviour.
  # eg @conn.open(@mock).join

  it "should authenticate" do
    @conn.open(@mock)
    @mock.receiveq.deq(false).should == "USER beerbot beerbot beerbot :beerbot\r\n"
    @mock.receiveq.deq(false).should == "NICK beerbot\r\n"
  end

  it "should only execute ready when it receives 001" do
    # We'll create a queue inside ready? and wait on it indefinitely
    # below.
    q = Queue.new
    @conn.open(@mock)
    @conn.ready?.should == false
    @conn.ready? {
      q.enq("item 1")
    }
    # Trigger the ready signal...
    @mock.push(":moo.server.net 001 lamebot :Welcome lamebot")
    # Should block for a wee bit, but hopefully we should get
    # the item-1...
    q.deq.should == "item 1"
    @conn.ready?.should == true
  end

  describe "after receiving 001" do
    it "should pong (after 001)" do
      @conn.open(@mock)
      @mock.push(":moo.server.net 001 lamebot :Welcome lamebot")
      @mock.push("PING foo")
      2.times { @mock.receiveq.deq(false) }
      @mock.receiveq.deq(false).should == "PONG foo\r\n"
    end
  end

end
