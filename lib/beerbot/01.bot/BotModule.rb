
module BeerBot
  # Represents a bot module and may contain a reference to the loaded
  # ruby module or any errors associated with loading it.

  class BotModule < Hash
    def initialize name,status:false,mod:nil,modname:nil,errors:[]

      self[:status] = status

      # See Bot#load!
      self[:name] = name
      self[:modname] = modname
      self[:mod] = mod  # The loaded ruby module.

      self[:errors] = errors

    end
  end

end
