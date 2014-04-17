# The files in this directory are part of BeerBot, a a ruby irc bot library.
# Copyright (C) 2013,2014 Daniel Bush
# This program is distributed under the terms of the GNU
# General Public License.  A copy of the license should be
# enclosed with this project in the file LICENSE.  If not
# see <http://www.gnu.org/licenses/>.

require_relative '../00.utils/utils'
require_relative '../01.protocols/irc'

module BeerBot

  # Dispatchers receive incoming messages from a connection and
  # decide what to do with them.

  module Dispatchers

    # This dispatcher calls BeerBot::Protocol::IRC.parse on what it
    # receives and then processes the response.
    #
    # There are several ways to specify how the result of parse is
    # processed.  You can:
    # 1) pass in a block at instantiation time
    # 2) set a block using #set_receive
    # 3) subclass this class and write your own #receive

    class IRCDispatcher

      IRC   = BeerBot::Protocol::IRC
      Utils = BeerBot::Utils
      
      attr_accessor :bot,:nick,:prefix,:world

      def initialize bot,nick,prefix:',',world:nil,&block
        @bot = bot

        @nick = nick
        @get_nick_cmd   = Utils.make_prefix_parser(nick)
        @nickrx = Regexp.new("^#{nick}$",'i')

        @prefix = prefix
        @get_prefix_cmd = Utils.make_prefix_parser(prefix)

        @world = world

        if block_given? then
          @block = block
        end
      end

      # Set a receiving proc.
      #
      # If no block given, @block is set to nil and #receive is used.

      def set_receive &block
        if block_given? then
          @block = block
        else
          @block = nil
        end
      end

      def parse irc_str
        IRC.parse(irc_str)
      end

      def receive irc_str

        event,*args = self.parse(irc_str)

        if @block then
          return self.instance_exec(event,*args,&@block)
        end

        # Otherwise, here is the default behaviour...

        case event
        when :unknown
          #puts "protocol/irc :unknown"
        when :default
          #puts "protocol/irc :default"
        when :nick
          old,nick = args
          @world.nick(old,nick) if @world
        when :part
          nick,channel = args
          @world.part(nick,channel) if @world
        when :join
          nick,channel = args
          @world.join(nick,channel) if @world
        when :chanlist
          #p "[dispatcher] :chanlist"
          channel,users = args
          if @world then
            users.each {|user|
              @world.join(user,channel)
            }
          end

        when :privmsg

          from,to,msg = args

          # Somebody messaging us privately:
          me = (@nickrx === to)

          # Somebody talking to us on channel: "Beerbot: ..."
          msg2 = @get_nick_cmd.call(msg)
          if not msg2 then
            # Somebody commanding us on channel: ",command ..."
            msg2 = @get_prefix_cmd.call(msg)
          end

          if msg2 then
            if msg2 =~ /^\s*help(?:\s+(.*))?$/ then
              replies = @bot.help(
                if $1.nil? then
                  []
                else
                  $1.strip.split(/\s+/)
                end,
                from:from,to:to,me:me,world:world)
            else
              replies = @bot.cmd(
                msg2,
                from:from,to:to,me:me,world:world)
            end
          else
            # We're just hearing something on a channel...
            replies = @bot.hear(msg,from:from,to:to,world:world)
          end

        else
          puts "protocol/irc unrecognised event: '#{event}'"
        end

        replies

      end

    end

  end

end