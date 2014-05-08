
# A test bot module (needs to be instantiated).
#
# If we pass a non-string msg, it will be returned.
# (This is to help with testing/mocking).

require_relative '../../../lib/beerbot'

class TestClass

  def initialize name
    @name = name
  end

  def cmd msg,from:nil,to:nil,config:nil,me:false
    case msg
    when String
      # This is what we'd expect a module to return:
      [to:from,msg:"cmd #{@name}"]
    else
      # Return the object - this could be not a botmsg, but it helps
      # with testing.
      msg
    end
  end

  def hear msg,from:nil,to:nil,me:false,config:nil
    case msg
    when String
      [to:from,msg:"hear #{@name}"]
    else
      msg
    end
  end

  def action action,from:nil,to:nil,me:false,config:nil
    case action
    when String
      [to:from,msg:"action #{@name}"]
    else
      action
    end
  end

  def event event,**kargs
    case event
    when :join
      unless kargs[:me] then
        [to:kargs[:channel],msg:kargs[:nick]]
      end
    end
  end

  # Here we'll just reflect back the topic and subtopics...
  #
  # Remember, help should return an array of lines ie strings
  # (not bot msgs).

  def help topics,from:nil,to:nil,config:nil
    [topics.join('/')]
  end
end

