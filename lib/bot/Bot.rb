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
  # You should be able to instantiate this bot in a repl
  # and command it or get it to hear things.
  # 
  # TODO
  # 1. not responding to other bots

  class Bot

    attr_reader :nick,:module_path

    def initialize nick,module_path,modules:[]
      @more = BeerBot::More.new  # to buffer outgoing messages
      @botmsg = BeerBot::Protocol::BotMsg
      @nick = nick
      @dir = File.dirname(__FILE__)
      @module_path = module_path  # "#{@dir}/../modules"
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
          result += [msg:"Type: more",to:to]
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
        if not me then
          p "more called key (to):#{to}"
          return @more.more(to)
        else
          p "more called key (from):#{from}"
          return @more.more(from)
        end

      # Process help request...
      when /^help(\s+(\S+)(\s+\S+)?)?\s*$/
        topic = $2  # could be nil
        subtopic = $3  # could be nil
        subtopic = subtopic.strip if subtopic
        p "help called, topic:#{topic}, subtopic:#{subtopic}"
        botmsg = self.help(topic,subtopic,from:from,to:to,world:world,me:me)
        return self.more(botmsg) if botmsg
      end

      # Respond using a module...
      if @cmd then
        botmsg = @cmd.call(msg,from:from,to:to,world:world,me:me)
        p ['@cmd',botmsg]
        return self.more(botmsg) if botmsg
        return nil
      end

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
      if @hear then
        botmsg = @hear.call(msg,from:from,to:to,world:world)
        return self.more(botmsg) if botmsg
        return
      end
      self.with_modules {|m,modname|
        next unless m.respond_to?('hear')
        botmsg = m.hear(msg,from:from,to:to,world:world)
        return self.more(botmsg) if botmsg
      }
      nil
    end

    # Handle help commands.
    # 
    # "help" => list general commands or topics for all modules
    # "help topic" => list topics for topic (usually module name)
    # "help topic subtopic" => list subtopics for topic

    def help topic,subtopic,from:nil,to:nil,world:nil,me:false
      m = nil

      # "help modname [subtopic]"
      if topic then
        modname = topic
        mod = self.get_module(modname)
        return nil unless @modules.rindex(modname)
        if mod then
          if mod.respond_to?(:help) then
            arr = mod.help(subtopic)
            return nil if not arr
            m = []
            if not subtopic then
              m += [to:from,msg:"type: help #{modname} <topic>"]
            end
            m += arr.map{|a| {to:from,msg:a}}
          end
        else
          m = [to:to,msg:"Don't know this topic #{from}"]
          return m
        end

      # "help"
      else
        helplist = [
        ]
        self.with_modules {|m,modname|
          helplist.push modname.split('::').last
        }
        m = [{
            to:from,
            msg:"To issue commands to the bot over a channel, you need to start with a command prefix like ','."
          },{
            to:from,
            msg:"When talking to the bot directly, you don't need a prefix."
          },{
            to:from,
            msg:"Modules (type: help <module-name>): "+helplist.join('; ')
          }
        ]

      end

      if m then
        if not me then
          m += [to:to,msg:"pm'ing you #{from}"]
        end
      end

      return m

    end


    # Show the modules that will be used in responses.
    #
    # Only return a copy.
    # Every item in @modules is a string representing a
    # module name in @module_path.
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
      Dir.chdir(@module_path) {
        bad = arr.select{|a|
          /[a-z]/===a[0] || !File.directory?(a)
        }
        if bad.empty? then
          @modules = arr
        else
          puts "*** ERROR: These module names must start with capital or were not found in #{@module_path}: #{bad}"
          @modules
        end
      }
      self.load_modules!
    end

    # Reload all modules found in @module_path.
    #
    # This doesn't mean they will be used.
    # 
    # TODO: we could use autoload perhaps?

    def load_modules!
      Dir.chdir(@module_path) {
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
        mod = get_module m
        yield mod,m if mod
      }
    end

    # Get reference to a module if it is loaded, return nil otherwise.

    def get_module modname
      modname = "::BeerBot::Modules::#{modname}"
      begin
        mod = Object.const_get(modname)
        return mod
      rescue => e
        puts "'#{modname}' was not loaded into ruby! #{e}"
        return nil
      end
    end

    # Override normal cmd processing with Proc.
    #
    # You might want to do this to temporarily stop normal bot command
    # behaviour in order for the bot to go into some sort of exclusive
    # mode.
    #
    # To disable normal response behaviour do:
    #   bot.set_cmd {|msg,**kargs| nil }
    #   bot.set_hear {|msg,**kargs| nil }
    # 
    #
    # To unset,
    #   bot.set_cmd
    #   bot.set_hear

    def set_cmd &block
      @cmd = block
    end

    # Override normal hear-processing with Proc.
    #
    # See set_cmd.

    def set_hear &block
      @hear = block
    end

  end

end

