# The files in this directory are part of BeerBot, a a ruby irc bot library.
# Copyright (C) 2013,2014 Daniel Bush
# This program is distributed under the terms of the GNU
# General Public License.  A copy of the license should be
# enclosed with this project in the file LICENSE.  If not
# see <http://www.gnu.org/licenses/>.

require_relative '../00.utils/utils'

module BeerBot

  # Dispatchers receive incoming messages from a protocol object and
  # dispatches them (usually to an instance of Bot).
  #
  # Dispatcher#receive takes:
  # 1) event - a symbol representing an event eg :msg, :join etc
  # 2) args  - an array representing arguments

  module Dispatchers

    # This class is basically a glorified struct with a receive method
    # that is the default way to dispatch to an instance of Bot.
    # 
    # You have several options if you want to customize...
    # 1) subclass if you want to pre or post filter
    # 2) override #receive with your own singleton receive (see tests)
    # 3) make a new Dispatcher-like class

    class Dispatcher

      Utils      = BeerBot::Utils
      BotMsg     = BeerBot::BotMsg
      
      attr_accessor :bot,:nick,:prefix,:config

      def initialize bot,nick,prefix:',',config:nil
        @bot = bot
        @nick = nick
        @prefix = prefix
        @config = config
        @get_nick_cmd   = Utils.make_prefix_parser(nick)
        @nickrx         = Regexp.new("^#{nick}$",'i')
        @get_prefix_cmd = Utils.make_prefix_parser(prefix)
      end

      # Receive generic events emitted by a protocol class and
      # dispatch to an instance of Bot.
      #
      # eg the output from BeerBot::Protocol::IRC.parse .

      def receive event,args

        replies = nil

        # Otherwise, here is the default behaviour...

        case event
        when :unknown
          replies = @bot.event(event,args:args,config:@config)
        when :default
          replies = @bot.event(event,args:args,config:@config)

        when :nick
          old,nick = args
          replies = @bot.event(event,old:old,nick:nick,config:@config)

        when :quit
          nick,msg = args
          replies = @bot.event(event,nick:nick,msg:msg,config:@config)
        when :part
          nick,channel = args
          replies = @bot.event(event,nick:nick,channel:channel,config:@config)
        when :join
          nick,channel = args
          me = (@nickrx === nick)
          replies = @bot.event(event,me:me,nick:nick,channel:channel,config:@config)
        when :chanlist
          channel,users = args
          replies = @bot.event(event,channel:channel,users:users,config:@config)
        when :chanlistend
          # ignore

        when :action
          from,to,action = args
          me = (@nickrx === to)
          replies = @bot.action(action,from:from,to:to,me:me,config:@config)

        when :msg
          from,to,msg = args

          # Somebody messaging us privately:
          me = (@nickrx === to)

          # Somebody talking to us on channel: "Beerbot: ..."
          cmd = @get_nick_cmd.call(msg)
          if not cmd then
            # Somebody commanding us on channel: ",command ..."
            cmd = @get_prefix_cmd.call(msg)
          end

          if cmd then
            case cmd
            # dispatch help...
            when /^\s*help(?:\s+(.*))?$/
              if $1.nil? then
                args = []
              else
                args = $1.strip.split(/\s+/)
              end
              replies = @bot.help(args,from:from,to:to,me:me,config:@config)
            # dispatch cmd...
            else
              replies = @bot.cmd(cmd,from:from,to:to,me:me,config:@config)
            end
          else
            # We're just hearing something on a channel...
            replies = @bot.hear(msg,from:from,to:to,me:me,config:@config)
          end

        else
          puts "[dispatcher] unrecognised event: '#{event}'"
        end

        case replies
        when String # assume protocol string eg irc
          replies
        when Hash,Array,Proc
          BotMsg.to_a(replies)
        else
          []
        end

      end

    end

  end

end
