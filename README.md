# BeerBot

*"...the number of BeerBot installations has grown to 1, with more expected..."* -- BeerBot Labs

BeerBot is an irc bot written in ruby 2.0 and some bits of thread.

* Uses ruby 2.0
* includes IRC
* Structured to be independent of IRC, the bot itself is agnostic
  * you know, if you want to make BeerBot do xmpp, please do so and let me know :D
* Uses pry as a repl for administering the bot while running
* Contains a scheduler based on ```CronR``` gem; this should make it easy to get BeerBot to do recurring tasks like reminders

I wrote it partly in frustration with another ruby irc bot and
partly for an internal irc server.

## Status

* Started building this in the last week of 27-Nov-2013 .
* Be careful about using this on a public network.

## Batteries sold separately

BeerBot won't do anything out of the box.

* Go here: https://github.com/danielbush/beerbot-modules and follow the instructions.

## Layout

* ```lib/``` contains the core bot code
* ```conf/``` example configuration file here; some settings are mandatory, take a look at it
* ```bin/``` contains ```beerbot-run-irc.rb```

## Installing

Install the gem

```
  gem install 'beerbot'
  type beerbot-run-irc.rb
  # => beerbot-run-irc.rb is hashed (/home/danb/.rvm/gems/ruby-2.0.0-p247/bin/beerbot-run-irc.rb)

```
  
Or, if you want the code...

Git clone this code (using your git-fu).

Then do ```bundle install```.

## Configure / Setup

First, take a look at the example configuration file in ```conf/```.
Hopefully that is mostly self-explanatory.

You want something like this:
```
  cd somewhere
  mkdir beerbot
  mkdir beerbot/conf
  mkdir beerbot/code
  mkdir beerbot/data
  mkdir beerbot/modules
```
where...
- **conf/**
  - Put your conf file(s) in here
- **code/**
  - Bot code can go here (if you're cloning from here, not using the gem)
- **modules/**
  - This is the ```moduledir``` in conf.
  - Your 'modules' config should point to zero or more modules in this dir.
    Get your own set of bot modules:
      git clone https://github.com/danielbush/beerbot-modules.git modules
- **data/**
  - This is the ```datadir``` in conf.

## Running

If you installed the gem, with a bit of luck, all you need to do (once
you've done the above preparatory stuff) is...

```
  beerbot-run-irc.rb path/to/conf.json
```

If you're working with the code (not a gem), then you'll probably want
to do something like this:

```
  ruby -Ip/t/b/lib p/t/b/bin/beerbot-run-irc.rb path/to/conf.json
```

where p/t/b = path/to/beerbot

Your ```path/to/conf.json``` should be a json file that specifies
things like a ```moduledir``` and a ```datadir``` and some other
things - see ```conf/``` for example.

Note that the bot modules in ```moduledir``` may require beerbot:

You should see some irc lines whizz by on your terminal.

Amongst these you should see some some scary numbers like ```001```
(that means the irc server likes the cut of our gib), and ```353``` /
```366```... you'll get those if you specified any channels in your
```conf``` that beerbot will have joined.

## Repl

Yeh, repl is cool.  Way cool.  If you got beerbot running, you already have one once those lines go whizzing by.  Hit enter a couple of times and
you should see the pry repl prompt
```
  pry>
```


Pry is running inside the **RunIRC** class in lib/RunIRC.rb .
There are some convenience methods in this class for making the
bot do things.

```ruby
  pry> join '#chan1'
  pry> say '#chan1','howdy!'
  pry> action '#chan1','departs the channel hastily'
  pry> leave '#chan1'
```
You get the idea.

Try typing:

```ruby
  pry> @scheduler
  pry> @bot
  pry> @config
```

Note, that ```@bot``` is just an array of bot modules.  Neat.
Those are the bot modules that beerbot will run when responding
to commands, overhearing messages / actions or receiving events.

```@scheduler``` is an instance of ```CronR::Cron``` which is also an array.  You can add jobs to it from this repl if you feel so inclined.  See the ```CronR``` gem.

```ruby
  pry> @scheduler.time
```
... will give you the current time for the configured timezone you have.
See the CronR documentation.

## Talking to the bot (on irc)

On irc, the ```cmd_prefix``` you specified in your ```conf``` can be used as a shortcut to address the bot.

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

## Scheduling

You can grab the ```CronR``` scheduler in a more official way like this:

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


