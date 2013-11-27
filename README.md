# BeerBot

An irc bot written in ruby 2.0 and some bits of thread.
Use at your own risk..

* Uses ruby 2.0
* Uses pry as a repl for administering the bot while running
* Structured to be independent of irc, the bot itself is agnostic

## Status

Only just started building this in the last week (27-Nov-2013).
Be careful about using this on a public network.
I wrote it partly in frustration with another ruby irc bot and
partly for an internal irc server.

## Setup

Get ruby 2.0

* Get rvm, see TODO
* Then set it up
 rvm use ruby-2.0.0

Clone this project, and cd into it.

Install the required gems
  bundle install

Most of the bot functionality is in lib/modules/.
Specify the ones you want to load using the 'modules' property in your
conf (see conf/ for examples).

And run
  bundle install
on these.


## Usage

Create an irc conf, use conf/ as an example.

If you want to test or play with it with a real irc server, on
linux it is pretty easy to install an irc server and run it
on localhost.

Use irssi or your favourite irc client to connect and create
channels.

  ruby run-irc.rb conf/your-conf.json

Should start the bot and launch the pry repl.

You can interrogate all key parts of the system from this repl
eg @bot, @conn, @dispatch, @world.

And you can reload the bot or its modules and alter which modules are
used to reply to messages.

## Bot (and modules)

The actual bot and the modules it uses are agnostic to the chat protocol eg irc.

What do we mean by bot?

A bot is
* an object that has a 'cmd' method,
* and optionally 'hear' and 'help' methods.

For messages addressed to the bot, we use:

```ruby
  def cmd msg,from:nil,world:nil
```

This is the way to send commands to the bot.

For messages not addressed to the bot, we use:

```ruby
  def hear msg,to:nil,from:nil,world:nil
```


cmd and hear should reply with an array of hashes where each hash is
a message or action.

Example:

```ruby
  [msg:'hi there']

  => [{:msg => "hi there"}]
```

is a single reply

```ruby
  [action:'runs up the stairs']

  => [{:action => 'runs up the stairs'}]
```

is a single action.

You can reply with multiple actions.


```ruby
  [msg:'hi there'] + [msg:'oh crap!']

  => [{msg:'hi there'},{msg:...}]
```

will get the bot to say 'hi there' and 'oh crap'.


There are some additional options you could pass.

  [..., private:true]

  => {..., :private => true }

means the message should be sent to the sender of the message.
(this is the nick/user in the prefix part of the PRIVMSG).
This distinction may be important when the bot receives a cmd via a channel.
By default, the dispatcher will route the message back to the channel.
The 'private' option should override this.

### Dispatching

The bot and its modules are protocol agnostic.  Instead, there is a
dispatcher class that worries about the details of the protocol
and mediates between the bot and the irc (or potentially other) connection.

## Major components

The major components (modules/classes) in bot-land:

* Parse
  * the Parse::IRC.parse module does the job of "parsing" irc messages
  * the Parse::IRC.msg creates a PRIVMSG which you can send to the irc server
  * the Parse::IRC.action creates an action /me-style PRIVMSG
* IRCConnection < Connection
  * connects to irc
  * does ping/pong, and provides a ready? hook for you to do things
    once connection is established
* IRCWorld < World
  * the bot's world, the channels and people he knows about
* Bot
  * the bot itself, implements hear/cmd methods
  * manages modules, loading them
  * it's really just a glorified module loader/router for getting
    your modules to receive and reply to messages
* Dispatchers::IRC
  * routes messages to the Bot instance and route the replies
    back to the irc connection
  * instantiate one of these and have the IRCConnection
    emit to the 'receive' function
  * 'receive' should output nil or a valid IRC response string
    or an array of these
* lib/modules/...
  * modules used by the bot (your code goes here)

Also see: run-irc.rb pretty much introduces you to the major parts of
the system and how they are put together to create the bot.

## Adding a module

You need to create module like this:
```ruby
  module BeerBot
    module Modules
      module MyMod
        def self.cmd msg,from:nil,world:nil
        end
        # Optional
        def self.hear msg,to:nil,from:nil,world:nil
        end
        # Optional
        def self.help
        end
      end
    end
  end
```

And then store it here (with folder being the same name as the module):

  lib/modules/MyMod/MyMod.rb

The bot loads modules into memory by loading this file

  lib/modules/MyMod/init.rb

init.rb should load whatever could you require and the MyMod module.

Finally you need to add "MyMod" to the 'modules' array in your json conf.
You can also add the module to the bot after it starts using the pry
repl.  For the run-irc.rb example, you can access @bot.modules and
@bot.modules= .  See example session below.

## Example session

  ruby run-irc.rb conf/my-conf.json

You will see the bot receiving strings and the pry repl telling
you its position.  This should change.  We're just using pry to
pry on the variables in run-irc.rb.

The pry repl will allow you to see everything in run-irc.rb.

```ruby
  @world # shows the bot's world so far
  @conn  # shows IRCConnection
  @bot   # shows the bot instance
  @dispatch  # the dispatcher that mediates between @bot and @conn
  @parse     # irc parser

  reload! # hot reload the bot and dispatcher
  @bot.load_modules! # reload the modules used by @bot
  @bot.modules = [...]  # change the modules the bot uses to respond
```

You can talk to the bot directly, no irc

```ruby
  @bot.cmd "do something!",from:someone
```

You can send any irc command you want by using `write`:

```ruby
  @conn.write "JOIN #channel1"
```

or

```ruby
  @conn.write @parse.join("#channel1")
```


## Understanding PRIVMSG and Bot#cmd / Bot#hear

For IRC messages, PRIVMSG is the main way to talk:

```
  :prefix PRIVSMG to-nick :message here
```

where prefix can be expanded:

```
  :nick!~user@host PRIVSMG to :message here
```

* !~ is a separator
* ":" is also separator

Here are some examples:

1) danb1 says "yo" on #chan1:
  ":danb1!~danb@127.0.0.1 PRIVMSG #chan1 :yo\r\n"

2) danb1 says "yo" to beerbot privately:
  ":danb1!~danb@127.0.0.1 PRIVMSG beerbot :yo\r\n"

3) danb1 says "beerbot yo!" on #chan1:
  ":danb1!~danb@127.0.0.1 PRIVMSG #chan1 :beerbot yo!\r\n"

Our bot instance doesn't want to know about the niceties of the irc
protocol and PRIVMSG in particular, it just wants to receive and
possibly respond to messages. They could for instance be coming over
xmpp, who knows...

* case 1 uses 'hear'.
* case 2 uses 'cmd'.
* case 3 uses 'cmd'

Case 3 is really a special case of case 1. But it is very common way
to request actions from the bot.

