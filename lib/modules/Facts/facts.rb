# The files in this directory are part of BeerBot, a a ruby irc bot library.
# Copyright (C) 2013 Daniel Bush
# This program is distributed under the terms of the GNU
# General Public License.  A copy of the license should be
# enclosed with this project in the file LICENSE.  If not
# see <http://www.gnu.org/licenses/>.

module BeerBot; module Modules; end; end

require 'sqlite3'

# Facts module.
#
# Usage:
# ,term1 is foo
# => the bot stores ["foo"] (an array containing "foo") against term "term1"
# ,term1 is also bar
# => the bot appends to the array ["foo","bar"]
# ,term1
# => the bot prints out the terms one per line
# [0] foo
# [1] bar
# ,forget term1 1
# => bot deletes the first entry
# ,forget term1
# => bot deletes the whole term
#
# The way we implement this is to use a 2-field table, 1 field is the
# term, the other is a marshalled ruby array.
#
# Facts will build an sqlite3 database called facts.db in this
# directory.

module BeerBot::Modules::Facts

  # IMPORTANT: set this outside of any methods, otherwise, expand_path
  # will not actually resolve correctly - maybe something to do with
  # the way we load modules?

  @@path = File.expand_path(File.dirname(__FILE__))

  # TODO: use BLOB instead of TEXT for values?
  def self.build_tables!
    return unless self.table('facts').empty?
    p "Rebuilding tables"
    rows = self.db.execute <<-SQL
    CREATE TABLE facts (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      term VARCHAR(30) UNIQUE NOT NULL,
      val  TEXT
    );
SQL
  end

  # By default, we create facts.db in this directory, but you can
  # override it here for testing purposes.

  def self.set_db dbfile
    @@dbfile = dbfile
    @@db = nil  # force new database instance
  end
  def self.dbfile
    @@dbfile
  end

  def self.db
    @@dbfile ||= @@path+'/facts.db'
    p @@dbfile
    @@db ||= SQLite3::Database.new(@@dbfile)
    @@db
  end

  # Returns nil if table doesn't exist.

  def self.table table
    self.db.table_info(table)
  end

  # Fetch term from database and unmarshal it (should be array) or
  # return nil.

  def self.term term
    term = term.to_s
    val = self.db.get_first_value("SELECT val FROM facts WHERE term=?",[term])
    return nil if not val
    return Marshal.load(val)
  end

  # Add term to facts table.
  def self.add term,val,replace=false
    exists = self.term(term)
    if exists then
      if replace then
        val = [val]
      else
        val = exists.push(val)
      end
      self.delete(term)
      self.db.execute("INSERT INTO facts(term,val) VALUES (?,?)",
        [term,Marshal.dump(val)])
    else
      val = [val]
      self.db.execute("INSERT INTO facts(term,val) VALUES (?,?)",
        [term,Marshal.dump(val)])
    end
  end

  def self.delete term,n=nil
    if n.nil? then
      self.db.execute("DELETE FROM facts WHERE term = ?",[term])
      return true
    else
      vals = self.term(term)
      if not vals.nil? then
        if vals[n] then
          self.delete term
          vals.delete_at(n)
          vals.each{|t|
            self.add term,t
          }
          return true
        end
      end
    end
  end

  def self.help detail=nil
    if not detail then
      ["topics: add,forget,edit,search"]
    else
      case detail
      when 'add'
        [
          "<term> is ...  # to create a new term",
          "<term> is also ...  # to add a entry for existing term",
        ]
      when 'forget'
        [
          "forget <term> # forget the term",
          "forget <term>[n] # forget entry n in term (not implemented yet)",
        ]
      when 'edit'
        [
          "<term> s/../../g  # not implemented yet",
        ]
      when 'edit'
        [
          ",?<regex> (case insensitive) # not implemented yet",
        ]
      else
        ["No information"]
      end
    end
  end

  def self.hear msg,to:nil,from:nil,world:nil
    self.build_tables!
    case msg
    when /,,(\S+)/
      term = $1
      i = -1
      if val = self.term(term) then
        msg = [msg:"#{term} is: ",to:to] +
              val.map{|v| {:msg => "[%d] %s" % [i+=1,v],to:to}}
        return msg
      end
    end
  end

  def self.cmd msg,from:nil,to:nil,me:false,world:nil
    self.build_tables!
    to = me ? from : to

    case msg

    # ",term is also ..."
    when /^(\S+)\s+is\s+also\s+(.*)$/
      term = $1
      fact = $2
      ok = self.add(term,fact,false)
      if ok then
        if rand(2) == 0 then
          msg = "Noted #{from}"
          return [msg:msg,to:to]
        else
          action = "carefully writes it down"
          return [action:action,to:to]
        end
      else
        return [msg:"Failed to store term!",to:to]
      end

    # ",term is ..."
    when /^(\S+)\s+is\s+(.*)$/
      term = $1
      fact = $2
      if self.term(term) then
        return [msg:"Term already exists #{from} use ',<term> is also ...' or ',forget <term>' .",to:to]
      end
      ok = self.add(term,fact.strip)
      msg = ok ? "Noted #{from}" : "Failed to store term!"
      return [msg:msg,to:to]

    # TODO: sed-edit a term ?

    # TODO: forget <term> n where n = 0,1,2,3,
    when /^forget\s+(\S+)(\s+.*)?$/
      term = $1
      n = $2
      term.strip!
      if self.term(term) then
        if n then
          n = n.to_i
          result = self.delete(term,n)
          if result then
            return [msg:"Deleted #{term}[#{n}]",to:to]
          else
            return [msg:"Can't delete #{term}[#{n}]",to:to]
          end
        else
          self.delete(term)
          return [msg:"Removed entry #{from}",to:to]
        end
      else
        return [msg:"Can't find this term #{from}",to:to]
      end


    # ",term?"
    # TODO: search terms and values
    when /^(\S+)\?\s*$/
      return nil

    # TODO ",term n" where n = 0,1,2,3

    # ",term"
    when /^(\S+)\s*$/
      term = $1
      val = self.term(term)
      if val then
        if val.size == 1
          msg = [msg:"#{term} is: #{val[0]}",to:to]
        else
          i = -1
          msg = [msg:"#{term} is: ",to:to] +
                val.map{|v| {msg:"[%d] %s" % [i+=1,v],to:to} }
        end
      else
        #msg = [msg:"Don't know this term #{from}",to:to]
        return nil
      end
      return msg

    else
      return nil
    end

  end
end
