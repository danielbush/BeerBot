# The files in this directory are part of BeerBot, a a ruby irc bot library.
# Copyright (C) 2014 Daniel Bush
# This program is distributed under the terms of the GNU
# General Public License.  A copy of the license should be
# enclosed with this project in the file LICENSE.  If not
# see <http://www.gnu.org/licenses/>.

require_relative '../01.protocols/botmsg.rb'

module BeerBot

  BotMsg = BeerBot::Protocol::BotMsg

  # Represents a bot module and may contain a reference to the loaded
  # ruby module or any errors associated with loading it.

  class BotModule < Hash
    def initialize name,status:false,mod:nil,modname:nil,errors:[]
      self[:status] = status
      self[:name] = name  # The module name.
      self[:mod] = mod  # The loaded ruby module.
      self[:modname] = modname
      self[:errors] = errors
    end
  end

  # Represents a sequence of BotModule instances.

  class Bot < Array

    attr_accessor :module_path,:module_names

    def initialize module_path,module_names
      super()
      @module_path = module_path
      @module_names = module_names
      self.load!
    end

    def load!
      self.reject!{true} unless self.empty?  # ick :)
      Dir.chdir(@module_path) {
        @module_names.each {|name|
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
    # Returns array-based botmsg.  The array could be empty, which
    # means nothing was returned (or we couldn't interpret the output
    # of the bot modules).
    # 
    # We expect each bot_module to return nil or a botmsg (Hash, Array
    # or Proc that returns the first two).
    #
    # At the moment, we use inject and break on first valid
    # response...  

    def run meth,*args,**kargs
      self.valid_modules.inject([]) {|arr,bot_module|
        name,mod = bot_module.values_at(:name,:mod)
        next arr unless mod.respond_to?(meth)
        botmsg = mod.send(meth,*args,**kargs)
        if botmsg then
          #arr << [name,botmsg]
          arr += BotMsg.to_a(botmsg)
          break arr # TODO allow multi-module response?
        else
          arr
        end
      }
    end

    def cmd msg,from:nil,to:nil,world:nil,me:false
      if @cmd then
        botmsg = @cmd.call(msg,from:from,to:to,world:world,me:me)
        return botmsg
      else
        self.run(:cmd,msg,from:from,to:to,world:world,me:me)
      end
    end

    def hear msg,from:nil,to:nil,world:nil
      if @hear then
        botmsg = @hear.call(msg,from:from,to:to,world:world)
        return botmsg
      else
        self.run(:hear,msg,from:from,to:to,world:world)
      end
    end

    def help arr,from:nil,to:nil,world:nil,me:false
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