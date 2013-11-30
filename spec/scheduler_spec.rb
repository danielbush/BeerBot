require File.dirname(__FILE__)+"/../lib/scheduler/scheduler.rb"
require 'pp'
require 'date'

::Scheduler = BeerBot::Scheduler


describe "is_at?" do
  it "should handle dates close to 'now'" do
    s = Scheduler.new
    now = DateTime.now
    s.is_at?(now,now).should eq(:ok)
    # Past
    s.is_at?(now-Rational(60,24*60),now).should eq(:kill)
    s.is_at?(now-Rational(59,24*60),now).should eq(:ok)
    s.is_at?(now-Rational(1,24*60),now).should eq(:ok) # -1minute
    s.is_at?(now-Rational(59,24*60*60),now).should eq(:ok) # -59sec
    s.is_at?(now-Rational(30,24*60*60),now).should eq(:ok) # -30sec
    # Now
    s.is_at?(now-Rational(0,24*60*60),now).should eq(:ok) # 0sec
    s.is_at?(now+Rational(0,24*60*60),now).should eq(:ok) # 0sec
    # Future
    s.is_at?(now+Rational(1,24*60*60),now).should eq(:ok) # +1sec
    s.is_at?(now+Rational(30,24*60*60),now).should eq(:ok) # +30sec
    s.is_at?(now+Rational(59,24*60*60),now).should eq(:future) # +59secs
    s.is_at?(now+Rational(60,24*60*60),now).should eq(:future)
    s.is_at?(now+Rational(1,24*60),now).should eq(:future)
  end
end

require 'json'
require 'yaml'
describe "persisting stuff" do
  it "can serialize but not for procs" do
    s = Scheduler.new
    now = DateTime.now
    s.add i={msg:'test-1'},now,'danb'
    s.add i=lambda{'foo'},now,'danb'
    data = s.serialize
    j = YAML.load(data)
    j[0][:item][:msg].should eq('test-1')
    j.size.should eq(1)
  end
  it "can persist and load from file" do
    s = Scheduler.new
    now = DateTime.now
    s.add i={msg:'test-1'},now,'danb'
    s.persist!('/tmp/rspec-beerbot-scheduler.dat')

    # Check the data...
    j = YAML.load(File.read('/tmp/rspec-beerbot-scheduler.dat'))
    j[0][:item][:msg].should eq('test-1')
    j.size.should eq(1)

    # Create a new one and load..
    s = Scheduler.new
    s.load!('/tmp/rspec-beerbot-scheduler.dat')
    s.list[0][:item].should eq(i)
  end
end

describe "adding stuff" do

  it "should add one-off items" do
    s = Scheduler.new
    now = DateTime.now
    s.add i={msg:'test-1'},now,'danb'
    h = s.list[0]
    h[:item].should eq(i)
    h[:at].should eq(now)
    h[:owner].should eq('danb')
  end

  it "should add only Procs for permanent items" do
    s = Scheduler.new
    now = DateTime.now
    s.add_perm i={msg:'test-1'},'danb'
    s.list.size.should eq(0)
    s.permlist.size.should eq(0)

    s.add_perm i=lambda{|*args|'hi'},'danb'
    s.list.should be_empty
    s.permlist.size.should eq(1)
    s.permlist[0][:item].should eq(i)
  end

  it "should remove items" do
    s = Scheduler.new
    now = DateTime.now
    id = s.add(i={msg:'test-1'},now,'danb')

    s.list.size.should eq(1)
    s.remove(id,nil)
    s.list.size.should eq(0)
  end

end

describe "processing stuff" do

  it "should delete and queue valid at-based Hashes" do
    s = Scheduler.new
    now = DateTime.now
    id = s.add(i={msg:'test-1'},now,'danb')
    s.process_list(s.list,now)
    h = s.queue.deq(true)
    h.should eq(i)
    s.list.size.should eq(0)
    s.queue.size.should eq(0)

  end

  it "should delete but not queue invalid at-based Hashes",:focus => true do
    s = Scheduler.new
    now = DateTime.now
    # 1 day old (should fail processing)
    id = s.add(i={msg:'test-1'},now-1,'danb')
    s.process_list(s.list,now)
    s.list.size.should eq(0)
    s.queue.size.should eq(0)
  end

  it "should process and delete at-based Procs" do
    s = Scheduler.new
    now = DateTime.now
    s.add(ii=lambda{|now,h|
        [now,h]
      },now,'danb')
    s.queue.size.should eq(0)
    s.list.size.should eq(1)
    s.process_list(s.list,now)
    s.queue.size.should eq(1)
    s.list.size.should eq(0)
    i = s.queue.deq(true)
    n,h = i.call
    h[:owner].should eq('danb')
    h[:item].should eq(ii)
  end

  it "should process but not delete non at-based Procs" do
    s = Scheduler.new
    now = DateTime.now
    s.add_perm(ii=lambda{|now,h|
        [now,h]
      },'danb')

    s.list.size.should eq(0)
    s.permlist.size.should eq(1)
    s.process_list(s.permlist,now)
    s.queue.size.should eq(1)
    s.permlist.size.should eq(1)
    i = s.queue.deq(true)
    n,h = i.call
    h[:owner].should eq('danb')
    h[:item].should eq(ii)
  end

end
