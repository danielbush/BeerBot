# The files in this directory are part of BeerBot, a a ruby irc bot library.
# Copyright (C) 2013 Daniel Bush
# This program is distributed under the terms of the GNU
# General Public License.  A copy of the license should be
# enclosed with this project in the file LICENSE.  If not
# see <http://www.gnu.org/licenses/>.

require File.dirname(__FILE__)+'/../parse/parse'

module BeerBot

  # Dispatchers are lambdas that handle a lot of the details of
  # processing a protocol and update the world or call the bot (both
  # in protocol agnostic fashion).
  #
  # The lambda will route messages to the bot (cmd or hear) in
  # a protocol neutral message using botmsg hashes.

  module Dispatchers

    # Create a lambda for a given bot/nick/world/command prefix for
    # irc.
    # 
    # The lambda receives an incoming irc string, tries to parse
    # it and act on it.
    # The lambda should return nil or a botmsg hash.
    # Note that connection readiness and PONG protocol are handled by
    # the irc connection, not here.

    def self.makeIRCDispatcher bot,nick,prefix,world,&block

      irc = BeerBot::Parse::IRC::IRCMessage
      nickrx = Regexp.new("^#{nick}$",'i')
      get_nick_cmd = BeerBot::Parse.make_prefix_parser(nick)
      get_prefix_cmd = BeerBot::Parse.make_prefix_parser(prefix)

      lambda {|str|

        m = irc.new(str)

        if not m then
          puts "Don't recognise this command: '#{str}'."
        end

        case m[:command]

        when 'NICK'  # change of nick
          case s=m.check(:prefix,:nick,:trailing)
          when Symbol
            puts "* NICK expected #{s}"
            return nil
          end
          return nil unless world

          old = m[:prefix][:nick]
          nick = m[:trailing]
          world.nick(old,nick)
          return nil

        when 'PART' # someone leaves channel
          case s=m.check(:prefix,:nick,:params)
          when Symbol
            puts "* PART expected #{s}"
            return nil
          end
          return nil unless world

          channel = m[:params][0]
          nick = m[:prefix][:nick]
          world.part(nick,channel)
          if nickrx === nick then
          else
          end
          return nil

        when 'JOIN' # someone joins channel
          case s=m.check(:prefix,:nick,:trailing)
          when Symbol
            puts "* JOIN expected #{s}"
            return nil
          end
          return nil unless world

          channel = m[:trailing]
          nick = m[:prefix][:nick]
          world.join(nick,channel)
          if nickrx === nick then
          else
            # Somebody else has joined a channel.
            puts "#{nick} has joined #{channel}"
          end
          return nil

        when '353'  # channel user list when we join the channel
          case s=m.check(:params,:trailing)
          when Symbol
            puts "* 353 expected #{s}"
            return nil
          end
          return nil unless world

          channel = m[:params][2]
          users = m[:trailing].split(/\s+/)
          users.each {|user|
            world.join(user,channel)
          }
          return nil

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

          me = (nickrx === to)

          # Somebody messaging us privately:
          if me then
            replies = bot.cmd(
              msg,
              from:from,to:to,me:me,world:world)

          else

            # Somebody talking to us on channel: "Beerbot: ..."
            if msg2 = get_nick_cmd.call(msg) then
              replies = bot.cmd(
                msg2,
                from:from,to:to,me:me,world:world)

            # Somebody commanding us on channel: ",command ..."
            elsif msg2 = get_prefix_cmd.call(msg) then
              replies = bot.cmd(
                msg2,
                from:from,to:to,me:me,world:world)

            # We're just hearing something on a channel...
            else
              replies = bot.hear(msg,from:from,to:to,world:world)
            end

          end
          return replies
        else # unknown command
          return nil
        end
      }

    end

  end

end
