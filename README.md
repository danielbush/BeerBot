# BeerBot

An irc bot written in ruby 2.0 and some bits of thread.

* Uses ruby 2.0
* includes IRC
* Structured to be independent of IRC, the bot itself is agnostic
  * you know, if you want to make BeerBot do xmpp, please do so and let me know :D
* Uses pry as a repl for administering the bot while running
* Contains a scheduler based on ```CronR``` gem; this should make it easy to get BeerBot to do recurring tasks like reminders

## Status

Only just started building this in the last week (27-Nov-2013).
Be careful about using this on a public network.
I wrote it partly in frustration with another ruby irc bot and
partly for an internal irc server.

## Layout

* ```lib/``` contains the core bot code
* ```modules/``` some example bot modules
* ```datadir/``` example location for data directory; bot modules should store their data here (see example below)
* ```conf/``` example configuration file here; some settings are mandatory, take a look at it
* ```bin/``` contains ```run-irc.rb```

## Installing

Install the gem

```
  gem install 'beerbot'
  type run-irc.rb
  # => run-irc.rb is hashed (/home/danb/.rvm/gems/ruby-2.0.0-p247/bin/run-irc.rb)

```
  
Or, if you want the code...

Git clone this code (using your git-fu).

Then do ```bundle install```.

## Configure / Setup

First, take a look at the example configuration file in ```conf/```.
Hopefully that is mostly self-explanatory.

Outside of the code somewhere...

1. create a configuration file (like example conf in ```conf/```)
2. specify and make a directory to contain bot modules (like ```modules/```
3. specify and make a data directory (like ```datadir/```)

## Running

If you installed the gem, with a bit of luck, all you need to do (once
you've done the above preparatory stuff) is...

```
  run-irc.rb path/to/conf.json
```

If you're working with the code (not a gem), then you'll probably want
to do something like this:

```
ruby -Ip/t/b/lib p/t/b/bin/run-irc.rb path/to/conf.json
```

where p/t/b = path/to/beerbot

Your ```path/to/conf.json``` should be a json file that specifies
things like a ```moduledir``` and a ```datadir``` and some other
things - see ```conf/``` for example.

Note that the bot modules in ```moduledir``` may require beerbot:

```
  require 'BeerBot'
```

...so that is why we add the ```-I``` to the above invocation so as to
modify the ```load path``` to include the core bot code.

You should see some irc lines whizz by on your terminal.

Amongst these you should see some some scary numbers like ```020```
(that means the irc server likes the cut of our gib), and ```353``` /
```366```... you'll get those if you specified any channels in your
```conf``` that beerbot will have joined.

## Talking to the bot

On irc, the ```cmd_prefix``` you specified in your ```conf``` can be used as a short to address the bot.

You can say:

```
  beerbot: help
```

or just

```
  ,help
```

where ```,``` is the ```cmd_prefix```.

If you do this on a channel, beerbot will tell you that it is
messaging you directly with help.

## Repl

Yeh, repl is cool.  Way cool.  If you got beerbot running, you already have one.  Try typing:

```ruby
  @scheduler
  @bot
  @config
```

Note, that ```@bot``` is just an array of bot modules.  Neat.

```@scheduler``` is an instance of ```CronR::Cron``` which is also an array.  You can add jobs to it from this repl if you feel so inclined.  See the ```CronR``` gem.

## Goodies

So there are 2 modules in ```modules/``` included. One is the
```Facts``` module and the other is the ```Oracle``` module.

If you want to use them, you should probably copy them over to your
```moduledir``` that you specified in your conf.

The ```Facts``` module is by far the more complicated of the two and
provides a way for people to add one or more facts for a given term or
keyword. At this point, maybe just look at the specs or use beerbot's
```,help``` command to check this out.

There's also a ```Beer``` module that I haven't included here. In fact
both the ```Facts``` module and the ```Beer``` module were somewhat
inspired by functionality resident in #emac's fsbot on freenode.

## Hodor!

Ok, enough of the dry stuff.  Let's make a bot module.

```
  mkdir moduledir/Hodor
```

In ```moduledir/Hodor/init.rb``` put:

```ruby
  require_relative 'Hodor'
```

In ```moduledir/Hodor/Hodor.rb``` put:

```ruby
  require 'BeerBot'
  module BeerBot::Modules::Hodor
    # This is called when the bot is addressed directly...
    def self.cmd msg,**kargs
      replyto = kargs[:me] ? kargs[:from] : kargs[:to]
      [to:replyto,msg:"Hodor!"]
    end

    # This is called when the bot isn't addressed directly...
    def self.hear msg,**kargs
      replyto = kargs[:me] ? kargs[:from] : kargs[:to]
      [to:replyto,msg:"Hodor?"]
    end

    # Only need to return an array of msgs (no to's/from's):

    def self.help arr=[]
      topic,*subtopics = arr
      ['HODOR!']
    end
  end
```

So what does the above do?

If you say anything directly:

```
  <danb> ,hi
  <beerbot> Hodor!
  <danb> beerbot: hi
  <beerbot> Hodor!
```

If you say something on a channel not to the bot:

```
  <danb> hi
  <beerbot> Hodor?
  <danb> oh wow, that's annoying can we ban this plz??
```

Finally if you said: ```,help Hodor```, well, you can guess...

Ok, so some things to note.

```ruby
  [to:replyto,msg:"..."]
```

is sugar for:

```ruby
  [{to:replyto,msg:"..."}]
```

In fact: 

```ruby
   {to:replyto,msg:"..."}
```

will do just fine. Both forms are referred to as a ```botmsg```.
```#cmd``` and ```#hear``` can return either a single hash or an array
of such.

Now, if you were to return ```nil``` rather thana ```botmsg```, then
BeerBot will move on and look at the next bot module to see if it has
a response.

What constitutes "the next bot module" you ask?

Well, in the pry repl, look at ```@bot```.  It's an array (take a look at the source code for bot.rb in ```lib/*/```).  BeerBot will start with the first bot module in the array, and look for a response, and continue working through the array till it hits the first module to respond.

At the moment, the first module to response with non-nil terminates
any further look ups.

### Scheduling

Now let's get really annoying. If saying "Hodor" all the time won't
get you and Beerbot banned from the channel, you can perhaps try going
the unsolicited route...

You can grab the ```CronR``` scheduler like this in your module:

```ruby
  scheduler = BeerBot::Scheduler.instance
  # Cron parameters: 5 = 'friday', 0,16 = 4pm 
  cronargs = [0,16,true,true,5]
  # Add a job...
  scheduler.suspend {|arr|
    arr << CronR::CronJob.new('timesheet',*cronargs) {
      [to:'#chan',msg:"OMG! it's like 4pm friday..."]
    }
  }
```

### Events

We've covered messages the bot hears and messages that are interpreted
directly by the bot.  But what about other events like somebody joining
a channel or conference room?

Taking the Hodor module above we can add:

```ruby
    def self.event event,**kargs
      case event
      when :join
        unless kargs[:me] then
          [to:kargs[:channel],msg:"Greetings #{kargs[:nick]}!"]
        end
      end
    end
```

Events are dispatched by the dispatcher - see
```lib/BeerBot/06.dispatchers``` and ```lib/BeerBot/02.protocols```.
The parse function in 02.protocols/irc.rb tries to return a generic
representation of a particular irc event.
The dispatcher in 06.dispatchers/irc.rb takes this and decides what to
do with it.
TODO:
