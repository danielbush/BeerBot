# The files in this directory are part of BeerBot, a a ruby irc bot library.
# Copyright (C) 2013 Daniel Bush
# This program is distributed under the terms of the GNU
# General Public License.  A copy of the license should be
# enclosed with this project in the file LICENSE.  If not
# see <http://www.gnu.org/licenses/>.

require File.dirname(__FILE__)+'/../parse/parse'

module BeerBot

  # Dispatchers are high level objects (= "they coordinate and know
  # about other objects") that mediate between one or more connections
  # and a single bot instance.
  #
  # Dispatchers don't know about the connection.  They simply
  # return valid irc via their receive function.
  #
  # Think of them as glorified receive functions that vet access to
  # the bot they're associated with, worry about the protocol details
  # and send the bot generic messages. No protocol details should leak
  # through.
  #
  # The dispatcher's receive function has to return an irc response
  # string or an array of these. It has to look for options such as
  # :action (a CTCP action) or :private, which means that it the reply
  # should only go to the user rather than the channel.
  #
  # TODO: we haven't implemented the idea of multiple connections using
  # a single dispatcher, may require some considerations around thread
  # safety.
  #

  module Dispatchers

    # This is the IRC dispatcher.

    class IRC

      def initialize bot,nick,prefix
        @bot = bot
        @nick = nick
        @prefix = prefix
        @parse = BeerBot::Parse::IRC

        @nickrx = Regexp.new("^#{@nick}$",'i')
        # TODO: @us? = BeerBot::Parse.make_nick_recogniser(nick)  # replace @nickrx
        @get_nick_cmd = BeerBot::Parse.make_prefix_parser(nick)
        @get_prefix_cmd = BeerBot::Parse.make_prefix_parser(prefix)
      end

      # Receive a message and route it to the bot or it's world.
      # 
      # @param m Should be a nil or a hash with :prefix,:command,:params,:trailing parts.
      # @return nil or a valid IRC command (string) or an array of these.
      #
      # Depending on m[:command], :prefix,:params,:trailing may be
      # nil.

      def receive m,raw,world

        case m
        when BeerBot::Parse::IRC::IRCMessage
        else
          puts "Require an IRCMessage instance."
          return nil
        end

        case m[:command]

        when 'NICK'  # change of nick
          case s=m.check(:prefix,:nick,:trailing)
          when Symbol
            puts "* NICK expected #{s}"
            return nil
          end

          old = m[:prefix][:nick]
          nick = m[:trailing]
          world.nick(old,nick)
          nil

        when 'PART' # someone leaves channel
          case s=m.check(:prefix,:nick,:params)
          when Symbol
            puts "* PART expected #{s}"
            return nil
          end

          channel = m[:params][0]
          nick = m[:prefix][:nick]
          world.part(nick,channel)
          if @nickrx === nick then
          else
          end
          nil

        when 'JOIN' # someone joins channel
          case s=m.check(:prefix,:nick,:trailing)
          when Symbol
            puts "* JOIN expected #{s}"
            return nil
          end

          channel = m[:trailing]
          nick = m[:prefix][:nick]
          world.join(nick,channel)
          if @nickrx === nick then
          else
            # Somebody else has joined a channel.
            puts "#{nick} has joined #{channel}"
          end
          nil

        when '353'  # channel user list when we join the channel
          case s=m.check(:params,:trailing)
          when Symbol
            puts "* 353 expected #{s}"
            return nil
          end

          channel = m[:params][2]
          users = m[:trailing].split(/\s+/)
          users.each {|user|
            world.join(user,channel)
          }
          nil

        when '366'  # end of 353

        when 'PRIVMSG'
          case s=m.check(:prefix,:nick,:params,:trailing)
          when Symbol
            puts "* PRIVMSG expected #{s}"
            return nil
          end

          msg  = m[:trailing].strip
          from = m[:prefix][:nick].strip
          to   = m[:params][0].strip unless m[:params].empty?

          me = (@nickrx === to)

          # Somebody messaging us privately:
          if me then
            replies = @bot.cmd(
              msg,
              from:from,to:to,me:me,world:world)

          else

            # Somebody talking to us on channel: "Beerbot: ..."
            if msg2 = @get_nick_cmd.call(msg) then
              replies = @bot.cmd(
                msg2,
                from:from,to:to,me:me,world:world)

            # Somebody commanding us on channel: ",command ..."
            elsif msg2 = @get_prefix_cmd.call(msg) then
              replies = @bot.cmd(
                msg2,
                from:from,to:to,me:me,world:world)

            # We're just hearing something on a channel...
            else
              replies = @bot.hear(msg,from:from,to:to,world:world)
            end

          end
          
          # TODO: we could pass some fo the array to
          # a buffer which could be access by ,more
          # eg More.buffer(replyto,lines)

          @parse.botmsg(replies)

        end
      end # receive

    end
  end
end
