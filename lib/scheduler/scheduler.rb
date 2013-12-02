# The files in this directory are part of BeerBot, a a ruby irc bot library.
# Copyright (C) 2013 Daniel Bush
# This program is distributed under the terms of the GNU
# General Public License.  A copy of the license should be
# enclosed with this project in the file LICENSE.  If not
# see <http://www.gnu.org/licenses/>.

module BeerBot; end
require 'json'
require 'yaml'
require 'date'
require 'thread'
require 'set'

# Scheduler
# 
# Usage:
#   s = Scheduler.new
#   id = s.add(<A>,<DateTime>,nick) # one off
#   id = s.add_perm(<A>,nick)       # permanently add
# where <A> could be
#   lambda{|now,h|}                  # add_perm or add
#   {...}  # eg {:msg => "...", ...} # add only
#   [...]  # eg [:msg => "...", ...] # add only

class BeerBot::Scheduler

  DIR = File.dirname(__FILE__)

  attr_accessor :queue,:list,:permlist

  def initialize
    @item_id = 0;
    @list = []
    @permlist = []
    @list_mutex = Mutex.new
    @queue = Queue.new
  end

  def is_at? at,now
    days = at-now
    #p "is_at? #{days.to_f}"
    minutes = days*24*60
    minutes = minutes.to_f
    if minutes <= -60 then
      return :kill
    elsif minutes <= 0.5 then
      return :ok
    else
      return :future
    end
      
  end

  # Process a list
  #
  # List containing hashes (h) of form:
  #   {at:<DateTime item:Hash|Array|Proc owner:nick}
  #
  # 'now' should generally be set to now, unless you're testing.
  #
  # If :item is a Proc, it will wrapped in a lambda that will call the
  # Proc passing in 'now' and 'h' for reference. If :item is an Array
  # or Hash, it is assumed they to be a valid bot message format.
  #
  # Really old Hash items in the queue will be discarded.
  #
  # Why not call the lambda?
  # ------------------------
  # Because we don't want the scheduler thread(s) to execute
  # whatever is in lambda.
  # 
  # Possible optimisation
  # ---------------------
  # #add does a sort by :at for at-based hashes.
  # So to avoid running everything in @list, we could
  # stop once we hit :future items.

  def process_list list,now

    @list_mutex.synchronize {

      delete = Set.new

      list.each {|h|

        case h
        when Hash

          item = h[:item]
          at = h[:at]

          if not item then
            delete.add(h)
            next
          end

          # h has an :at, we might delete it...
          if at then
            case self.is_at?(at,now)
            when :ok
              delete.add(h)
            when :future
              next
            else
              p "Item #{h} older than an hour, discarding."
              delete.add(h)
              next  # don't go further
            end

          # h has no :at, it is permanent...
          else
            # Only procs are permanent...
            unless Proc===item then
              p "Item #{item} doesn't have :at property, discarding."
              delete.add(h)
              next
            end
          end

          # Queue the item for processing...
          case item
          when Proc
            #r = item.call(now,h)
            # @queue.enq(r) if r
            @queue.enq(
              lambda{
                item.call(now,h)
              })
          when Hash,Array
            @queue.enq(item)
          end

        # h is invalid...
        else
          p "Can't process this item #{h}"
          delete.add(h)
        end
      }

      list.select!{|h|
        if delete.member?(h) then
          false
        else
          true
        end
      }

    }

  end

  # Start the scheduler.
  #
  # Can only call this once.

  def start
    return if @thread

    @thread = Thread.new {
      now = DateTime.now
      sec = now.second
      loop {
        sleep 60-sec
        now = DateTime.now
        sec = now.second
        # Wake up
        p "[scheduler/minute] waking up, time is #{now}"
        Thread.new {
          self.process_list(@list,now)
        }
        Thread.new {
          self.process_list(@permlist,now)
        }
      }
    }

  end


  def join
    # Pick one of the threads and wait for it.
    @thread.join
  end

  # Add a scheduled one-off 'item'.
  #
  # Sorted by 'at'.
  # @see process_list for the format.
  #
  # Returns an id (string) or nil.

  def add item,at,owner=nil
    return nil unless item
    @list_mutex.synchronize {
      @item_id += 1
      @list.push({id:@item_id,at:at,owner:owner,item:item})
      @list.sort!{|a,b| a[:at]<=>b[:at]}
      @item_id
    }
  end

  # Add a permanent job that will get run every minute.
  #
  # We force this to be a proc.

  def add_perm item,owner=nil
    case item
    when Proc
    else
      return nil
    end
    @list_mutex.synchronize {
      case item
      when Proc
        @item_id += 1
        @permlist.push({id:@item_id,owner:owner,item:item})
        return @item_id
      else
        p "Can't add item #{item}"
        return nil
      end
    }
  end

  # Remove a job by id from list.

  def remove id,owner=nil
    @list_mutex.synchronize {
      id = id.to_i
      @list.select!{|i|
        if i[:id]==id then
          if owner.nil? then
            false
          elsif i[:owner] == owner then
            false
          else
            # Refuse to delete.
            # Maybe someone is trying to delete something
            # that isn't theirs.
            true
          end
        else
          true
        end
      }
    }
  end

  # Persist some current jobs to a yaml or json file.
  #
  # We can't persist procs and since @permlist is all about
  # procs, we don't bother serializing it.

  def serialize
    data = []
    @list_mutex.synchronize {
      @list.each {|h|
        case h[:item]
        when Hash
          data.push(h)
        else
          # We can't marshal procs.
        end
      }
      YAML.dump(data)
    }
  end

  def persist! filename="#{DIR}/items.dat"
    File.open(filename,'w') {|f|
      f.write(self.serialize)
    }
    p "Wrote to #{filename}"
  end

  def load! filename="#{DIR}/items.dat"
    if File.exists?(filename) then
      data = YAML.load(File.read(filename))
      data.each{|h|
        if h[:at] then
          self.add(h[:item],h[:at],h[:owner])
        else
          self.add_perm(h[:item],h[:owner])
        end
      }
    end
  end


end

# test
#s = BeerBot::Modules::Scheduler.new.join
