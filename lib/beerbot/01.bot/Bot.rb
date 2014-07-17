# The files in this directory are part of BeerBot, a a ruby irc bot library.
# Copyright (C) 2014 Daniel Bush
# This program is distributed under the terms of the GNU
# General Public License.  A copy of the license should be
# enclosed with this project in the file LICENSE.  If not
# see <http://www.gnu.org/licenses/>.

require_relative 'botmsg.rb'
require_relative 'BotModule.rb'

module BeerBot

  # Represents a sequence of BotModule instances.

  class Bot < Array

    attr_accessor :module_path,:module_names

    def initialize
      super()
    end

    # Call all init methods on bot modules that have them.
    # 
    # Should only be called once.

    def init config
      self.valid_modules.each {|botmodule|
        if botmodule[:mod].respond_to?(:init) then
          botmodule[:mod].init(config)
        end
      }
    end

    # Call #config on all valid bot modules.

    def update_config config
      self.valid_modules.each {|botmodule|
        if botmodule[:mod].respond_to?(:config) then
          botmodule[:mod].config(config)
        end
      }
    end

    # Purge existing modules from this array and load modules with
    # names in module_names in module_path on disk into memory.
    #
    # MODULE NAMES and MODULE PATH:
    # 
    # Best understood like this:
    #   "#{module_path}/#{name}/*" = location of modules
    #   modname = "::BeerBot::Modules::#{name}"

    def load! module_names, module_path
      @module_path = module_path
      @module_names = module_names
      self.reject!{true} unless self.empty?  # ick :)
      Dir.chdir(module_path) {
        module_names.each {|name|
          initfile = "#{name}/init.rb"
          modname = "::BeerBot::Modules::#{name}"
          mod = nil
          err = [
            [:nodir,!File.directory?(name)],
            [:badname,name !~ /^[A-Z]/  ],
            [:noinit,!File.exists?(initfile)],
          ].select{|e| e[1]}
          ok = (err.size == 0)

          if ok then
            puts "loading #{initfile}..."
            load(initfile)
            mod = Object.const_get(modname)
            if mod.respond_to?(:instance) then
              mod = mod.instance
            end
          else
            p [initfile,err]
            raise "Can't load (some) modules."
          end

          bm = BotModule.new(
            name,status:ok,mod:mod,
            modname:modname,errors:err
          )
          self.push(bm)
        }
      }
    end

    def has_errors
      if self.find{|bot_module| !bot_module[:status]} then
        true
      else
        false
      end
    end

    # Return list of valid (loaded) modules.

    def valid_modules
      self.select{|bot_module| bot_module[:status]}
    end

    # Call :meth on valid (loaded) modules and maybe accumulate result
    # or return first valid response...
    #
    # Converts return value to ARRAY FORMAT if not already.
    # 
    # The array could be empty, which means nothing was returned (or
    # we couldn't interpret the output of the bot modules).
    # 
    # We expect each bot_module to return nil or a botmsg (Hash, Array
    # or Proc that returns the first two).
    #
    # At the moment, we use inject and break on first valid
    # response...  

    def run meth,*args,**kargs
      self.valid_modules.inject([]) {|arr,bot_module|
        name,mod = bot_module.values_at(:name,:mod)
        unless mod.respond_to?(meth) then
          next arr
        end
        reply = mod.send(meth,*args,**kargs)
        suppress,botmsg = BotMsg.to_reply_format(reply)
        if botmsg then
          arr += botmsg
        end
        if suppress then
          break arr
        else
          arr
        end
      }
    end

    # Process messages addressed directly to the bot.

    def cmd msg,from:nil,to:nil,me:false,config:nil
      if @cmd then
        @cmd.call(msg,from:from,to:to,config:config,me:me)
      else
        self.run(:cmd,msg,from:from,to:to,config:config,me:me)
      end
    end

    # Process messages the bot overhears.

    def hear msg,from:nil,to:nil,me:false,config:nil
      if @hear then
        @hear.call(msg,from:from,to:to,me:me,config:config)
      else
        self.run(:hear,msg,from:from,to:to,me:me,config:config)
      end
    end

    def action action,from:nil,to:nil,me:false,config:nil
      self.run(:action,action,from:from,to:to,me:me,config:config)
    end

    # Handle events other than being messaged.
    #
    # IRC events like joining channels, changing nicks etc.
    #
    # Both event and kargs is dependent on the dispatcher which in
    # turn is dependent on how the protocol (eg irc) is parsed.

    def event event,**kargs
      self.run(:event,event,**kargs)
    end

    def help arr,from:nil,to:nil,config:nil,me:false
      m = []
      modname,*topics = arr

      # "help"

      if arr.empty? then
        helplist = self.valid_modules.select {|bot_module|
          bot_module[:mod].respond_to?(:help)
        }.map{|bot_module|
          bot_module[:name]
        }
        reply = [
          {
            to:from,
            msg:"To issue commands to the bot over a channel, you need to start with a command prefix like ','."
          },
          {
            to:from,
            msg:"Modules (type: help <module-name>): "+helplist.join('; ')
          }
        ]

      # "help modname [subtopic [... [... etc]]]"

      else

        bot_module = self.valid_modules.find{|bot_module|
          bot_module[:name]==modname
        }

        # Can't find module...
        if bot_module.nil? then
          reply = [to:to,msg:"Don't know this topic #{from}"]

        # Can find module...
        else

          mod = bot_module[:mod]
          reply = []


          # Module has help...
          if mod.respond_to?(:help) then
            arr = mod.help(topics)

            if !arr || arr.empty? then
              reply += [to:from,msg:"hmmm, the module didn't say anything..."]
            else
              if topics.empty? then
                reply += [to:from,msg:"Note: modules should list topics which you can access like: help #{modname} <topic>"]
              end
              reply += arr.map{|a| {to:from,msg:a}}
            end

          # Module doesn't have help...
          else
            reply += [to:from,msg:"type: #{modname} doesn't seem to have any help"]
          end
        end

      end

      if not me then
        reply += [to:to,msg:"pm'ing you #{from}"]
      end
      return reply
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
