require 'date'

module BeerBot;  module Modules; end; end

module BeerBot::Modules::Beer

  @@path = File.expand_path(File.dirname(__FILE__))
  require @@path+'/../../utils/DataFile'
  require @@path+'/../../utils/paramExpand'
  require @@path+'/../../utils/utils'
  filepath = @@path+'/data.json'
  begin
    @@datafile = BeerBot::Utils::JsonDataFile.new(filepath)
  rescue => e
    puts "Can't load or parse json file: #{filepath}"
    puts "Error: #{e}"
    exit 1
  end

  # Set up some scheduling...
  @scheduler = BeerBot::Scheduler.instance
  @scheduler.add_perm(
    lambda{|now,h|
      BeerBot::Modules::Beer.reminder(now)
    })

  # Generate a reminder (botmsg) if 'now' is a certain time away from
  # beerdate.
  #
  # eg
  # BeerBot::Modules::Beer.reminder DateTime.now+Rational(1,24*60*60),DateTime.now+Rational(0,24*60)

  def self.reminder now=nil,beerdate=nil
    data = @@datafile.data['beerclock']['reminder']
    now = DateTime.now unless now
    beerdate = self.beerdate(now) unless beerdate
    seconds = Rational(1,24*60*60)
    minutes = Rational(1,24*60)
    tolerance = 10*seconds
    diff = beerdate-now
    if diff.abs < tolerance then
      announce = data['announce'].sample
      return [msg:announce,to:'#sydney']
    elsif (diff-(60*minutes)).abs < tolerance then
      warning = data['warning'].sample
      return [msg:warning,to:'#sydney']
    else
      return nil
    end
  end

  def self.help details=nil
    ['beerclock','beer [<nick>]']
  end

  def self.cmd msg,from:nil,to:nil,me:false,world:world

    to = (me ? from : to)

    case msg
    when /^beerclock|^beeroclock/i
      data = @@datafile.data["beerclock"]
      nick = from
      now = DateTime.now
      diff = self.beerdate_diff(now)
      if not diff
        return [
          msg:BeerBot::Utils.expand(
            data['now'].sample,
            nick:nick),
          to:to
        ]
      end
      if rand(10) < 3 then
        arr = data['other']
      else
        arr = data['main']
      end
      a = arr.sample
      a = BeerBot::Utils.expand(a, nick:nick)
      a = BeerBot::Utils.expand(a, diff)
      a = [msg:a,to:to]

      b = BeerBot::Utils.expand(
        data['supplementary'].sample,
        {nick:nick}
      )
      b = {msg:b,to:to}
      b = BeerBot::Utils.actionify(b)
      
      case rand(10)
      when 0,9
        if b[:action] then
          return a+[b]
        else
          c = [action:self.send_beer(nick),to:to]
          return a+[b]+c
        end
      else
        return a
      end

    when /^beer(\s+.*)?$/
      nick = $1
      if nick then
        nick.strip!
        # Recognise ourselves :)
        if world && world[:nick] then
          if world[:nick] == nick then
            nick = "himself"
          end
        end
      else
        nick = from
      end
      return [action:self.send_beer(nick),to:to]

    else
      return nil

    end
  end

  # Return string representing /me-style beer-sending action.

  def self.send_beer nick
    action = ":actions ::nick a :states :receptacles of :beers"
    msg = BeerBot::Utils::ParamExpand.expand(action,@@datafile.data['beer'])
    BeerBot::Utils.expand(msg, nick:nick )
  end

  # Get the next beer o'clock datetime from 'now'.

  def self.beerdate now # todo: wday / time
    wday = now.wday # 0 = sunday, 5 = friday
    daystofri = 6-(wday+1).modulo(7) # 0 = saturday, 6 = friday
    d = DateTime.new(now.year,now.month,now.day,16,0,0,now.offset)
    beerdate = d+daystofri
  end

  # Return nil if we've hit beer o'clock (friday evening).
  # Otherwise return hash with component parts.

  def self.beerdate_diff now
    beerdate = self.beerdate(now)
    #beerdate = DateTime.now+1.0/24
    #beerdate = DateTime.now+1.0/24/60 # 1 minute
    #beerdate = DateTime.now+1.0/24/60/60*50 # 50 seconds
    days = beerdate - now

    get_fraction = lambda {|r|
      _,frac = r.numerator.divmod(r.denominator)
      Rational(frac,r.denominator)
    }

    if days < 0 then
      if now.wday == 5 then
        # It's beer o'clock.
        return nil
      end
    end

    hours = get_fraction.call(days)*24
    minutes = get_fraction.call(hours)*60 
    seconds = get_fraction.call(minutes)*60 
    totaldays = days
    totalhours = days*24
    totalminutes = totalhours*60
    totalsecs = totalminutes*60
    
    {
      totaldays:totaldays.to_f.round(2),
      totalhours:totalhours.to_f.round(2),
      totalminutes:totalminutes.to_f.round(1),
      totalsecs:totalsecs.to_f.round(0),
      days:days.to_f.truncate,
      hours:hours.to_f.truncate,
      minutes:minutes.to_f.truncate,
      seconds:seconds.to_f.truncate,
    }
  end

end

