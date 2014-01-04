# The files in this directory are part of BeerBot, a a ruby irc bot library.
# Copyright (C) 2013 Daniel Bush
# This program is distributed under the terms of the GNU
# General Public License.  A copy of the license should be
# enclosed with this project in the file LICENSE.  If not
# see <http://www.gnu.org/licenses/>.

require File.dirname(__FILE__)+'/../more/more'
require File.dirname(__FILE__)+'/../protocols/irc'
require File.dirname(__FILE__)+'/../protocols/botmsg'

module BeerBot

  # Protocol agnostic - we receive commands and hear messages
  # with nicks and from/to.
  #
  # The bot defines 'cmd' and 'hear' methods which it may respond to.
  # The bot also records which modules it may use to respond to messages
  # and the order in which to check them.
  # 
  # TODO
  # 1. not responding to other bots

  class Bot

    attr_reader :nick

    def initialize nick,modules:[]
      @more = BeerBot::More.new  # to buffer outgoing messages
      @botmsg = BeerBot::Protocol::BotMsg
      @nick = nick
      @dir = File.dirname(__FILE__)
      @moduledir = "#{@dir}/../modules"
      self.modules = modules || []
    end

    # Process a botmsg (or array of such), and filter by 'to' and then
    # more-filter based on this.
    #
    # Returns the first 'n' messages for each 'to'.

    def more botmsg
      return nil unless botmsg
      result = []
      by_to = Hash.new{|h,k| h[k]=[]}
      arr = @botmsg.botmsg_to_a(botmsg)

      arr.inject(by_to){|h,v| h[v[:to]].push(v); h}
      by_to.each_pair{|to,a|
        result += @more.filter(a,to)
        if result.size < a.size then
          result += [msg:"Type: ,more",to:to]
        end
      }
      return result
    end

    # For addressing the bot directly.
    #
    # msg: String excluding command prefix(es)
    #
    # If :me then the bot is being PRIVMSG'd.
    # If not :me, then the bot is being addressed over a channel.

    def cmd msg,from:nil,to:nil,world:nil,me:false
      case msg

      # Pull out stuff that has been buffered...
      when /^more!{0,}|^moar!{0,}/i
        return @more.more(to)

      # Process help request...
      when /^help/
        botmsg = self.help(msg,from:from,to:to,world:world,me:me)
        return self.more(botmsg)
      end

      # Respond using a module...
      response = nil
      self.with_modules {|m,modname|
        botmsg = m.cmd(msg,from:from,to:to,world:world,me:me)
        p [modname,botmsg]
        return self.more(botmsg) if botmsg
      }
      nil
    end

    # Anythihg that isn't obviously a command, is 'heard' by the bot.
    # 
    # The bot may decide it is being addressed can call self.cmd.

    def hear msg,from:nil,to:nil,world:nil
      self.with_modules {|m,modname|
        next unless m.respond_to?('hear')
        botmsg = m.hear(msg,from:from,to:to,world:world)
        return self.more(botmsg) if botmsg
      }
      nil
    end

    # TODO: need a help protocol.
    #
    # help => list general commands or topics for all modules
    # help moduleName => list same for the module
    # help moduleName cmd => list cmd syntax (optional)

    def help msg,from:nil,to:nil,world:nil,me:false
      helplist = []
      self.with_modules {|m,modname|
        if m.respond_to?(:help) then
          mhelp = m.help
          helplist += mhelp
        end
      }
      [msg:helplist.join(', ')]
    end


    # Show the modules that will be used in responses.
    #
    # Only return a copy.
    # Every item in @modules is a string representing a
    # module name in @moduledir.
    # It should be capitalized/camelcase, module or class name.
    #
    # Note: doing self#modules += [...] will work as expected because
    # of the clone.

    def modules
      @modules.dup
    end

    # Assign a new list of modules and Kernel#load them.
    #
    # Can be used with '+='.

    def modules=(arr)
      Dir.chdir(@moduledir) {
        bad = arr.select{|a|
          /[a-z]/===a[0] || !File.directory?(a)
        }
        if bad.empty? then
          @modules = arr
        else
          puts "*** ERROR: These module names must start with capital or were not found in #{@moduledir}: #{bad}"
          @modules
        end
      }
      self.load_modules!
    end

    # Reload all modules found in @moduledir.
    #
    # This doesn't mean they will be used.
    # 
    # TODO: we could use autoload perhaps?

    def load_modules!
      Dir.chdir(@moduledir) {
        entries = Dir.glob('*')
        dirs = entries.select{|e| File.directory?(e) && (/[A-Z]/===e[0])}
        dirs.each {|dir|
          initfile = "#{dir}/init.rb"
          if File.exists?(initfile) then
            result = load(initfile)
            puts "#{initfile}: #{result}"
          else
            puts "#{initfile} not found."
          end
        }
      }
    end

    def with_modules &block
      @modules.each {|m|
        modname = "::BeerBot::Modules::#{m}"
        begin
          mod = Object.const_get(modname)
        rescue => e
          puts "'#{modname}' was not loaded into ruby! #{e}"
          next
        end
        yield mod,modname
      }
    end


  end

end

