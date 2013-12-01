# The files in this directory are part of BeerBot, a a ruby irc bot library.
# Copyright (C) 2013 Daniel Bush
# This program is distributed under the terms of the GNU
# General Public License.  A copy of the license should be
# enclosed with this project in the file LICENSE.  If not
# see <http://www.gnu.org/licenses/>.


module BeerBot

  # Protocol agnostic - we receive commands and hear messages
  # with nicks and from/to.
  #
  # The bot defines 'cmd' and 'hear' methods which it may respond to.
  # The bot also records which modules it may use to respond to messages
  # and the order in which to check them.
  # 
  # 1. TODO per-from (user/channel) paging
  # 2. response limiting (probably measured over time)
  # 3. plugin chain: ordering and calling thereof
  # 4. not responding to other bots
  #

  class Bot

    attr_reader :nick

    def initialize nick,modules:[]
      @nick = nick
      @dir = File.dirname(__FILE__)
      @moduledir = "#{@dir}/../modules"
      self.modules = modules || []
    end

    # If you are addressing the bot directly.
    #
    # If :me then the bot is being PRIVMSG'd.
    # If not :me, then the bot is being addressed over a channel.

    def cmd msg,from:nil,to:nil,world:nil,me:false
      case msg
      when /^more!{0,}|moar!{0,}/i
        return More.more(to)
      when /^help/
        return self.help msg,from:from,to:to,world:world,me:me
      end
      response = nil
      self.with_modules {|m,modname|
        a = m.cmd(msg,from:from,to:to,world:world,me:me)
        #p "[bot] #{modname} => '#{a}'"
        case a
        when Array
          # TODO: handle special cases or flags from the module
          return a
        else
        end
      }
      nil
    end

    # Anythihg that isn't obviously a command, is 'heard' by the bot.
    # The bot may decide it is being addressed can call self.cmd.

    def hear msg,from:nil,to:nil,world:nil
      self.with_modules {|m,modname|
        next unless m.respond_to?('hear')
        a = m.hear(msg,from:from,to:to,world:world)
        case a
        when Array
          # TODO: handle special cases or flags from the module
          return a
        else
        end
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

