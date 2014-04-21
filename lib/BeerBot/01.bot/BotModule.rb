
module BeerBot
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

end
