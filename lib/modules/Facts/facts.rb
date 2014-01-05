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
    rows = self.db.execute <<-SQL
    CREATE TABLE facts (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      term VARCHAR(30) UNIQUE NOT NULL,
      val  TEXT,
      mode VARCHAR(50)
    );
SQL
  end

  # At the moment, just a colleciton of things you would run if your
  # database already exists.
  #
  # Manually:
  #  sqlite3 facts.db
  #  .schema facts  # show the table definition
  #  ALTER TABLE ...

  def self.migrations
    [
      "ALTER TABLE facts ADD mode VARCHAR(50);"
    ]
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
    @@db ||= SQLite3::Database.new(@@dbfile)
    @@db
  end

  # Returns nil if table doesn't exist.

  def self.table table
    self.db.table_info(table)
  end

  # Fetch term from database.
  #
  # Should return an array if term or entry found, or nil otherwise.

  def self.term term
    term = term.to_s
    val = self.db.get_first_value("SELECT val FROM facts WHERE term=?",[term])
    return nil if not val
    arr = Marshal.load(val)
    return arr
  end

  # Get the mode for an entry.
  #
  # Currently entries are either modeless or "rand".

  def self.get_mode term
    self.db.get_first_value("SELECT mode FROM facts WHERE term=?",[term])
  end

  def self.set_mode term,mode
    self.db.execute("UPDATE facts SET mode=? WHERE term=?",
      [mode,term])
  end

  # Search on terms and their values.
  # 
  # Notes:
  # LIKE is not case-sensitive; GLOB is.
  # See: http://www.sqlite.org/lang_expr.html
  # db.execute returns array - empty if no results.

  def self.search pattern
    # We need to add '%'
    pattern = "%"+pattern+"%"
    val = self.db.execute(
      "SELECT term FROM facts WHERE "+
      "term LIKE ?"+
      "OR val LIKE ?",
      [pattern,pattern])
    return nil if not val
    return val
  end

  def self.valid_term? term
    # No square brackets.
    return false if /[\]\[]/ === term
    return false if /^[:;,!?*&%^#$]/ === term
    return true
  end

  # Add term to facts table.
  #
  # Return false

  def self.add term,val,replace=false
    if not self.valid_term?(term) then
      return false
    end
    exists = self.term(term)
    if exists then
      if replace then
        val = [val]
      else
        val = exists.push(val)
      end
      mode = self.get_mode(term)
      self.delete(term)
      self.db.execute("INSERT INTO facts(term,val,mode) VALUES (?,?,?)",
        [term,Marshal.dump(val),mode])
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
      # Delete nth entry, and rebuild the term.
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
      ["topics: add,forget,edit,search,rand"]
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
          "forget <term> n  # forget entry n in term (not implemented yet)",
        ]
      when 'edit'
        [
          "<term> n s/../../g  # not implemented yet",
        ]
      when 'search'
        [
          "<pattern>? (case insensitive), pattern will be automatically globbed",
        ]
      when 'rand'
        [
          "<term> rand # toggle random selection of entry in term",
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
        if not self.valid_term?(term) then
          return [to:to,msg:"Failed to store term! Terms should not contain square brackets or start with punctuation."]
        else
          return [to:to,msg:"Failed to store term!"]
        end
      end

    # ",term is ..."
    when /^(\S+)\s+is\s+(.*)$/
      term = $1
      fact = $2
      if self.term(term) then
        return [msg:"Term already exists #{from} use ',<term> is also ...' or ',forget <term>' .",to:to]
      end
      ok = self.add(term,fact.strip)
      if ok then
        msg = "Noted #{from}"
      else
        if not self.valid_term?(term) then
          msg = "Failed to store term! Terms should not contain square brackets or start with punctuation."
        else
          msg = "Failed to store term!"
        end
      end
      return [msg:msg,to:to]

    # ",term rand"
    when /^(\S+)\s+rand\s*$/
      term = $1
      if not self.term(term) then
        return [to:to,msg:"Don't know this term, #{from}"]
      end
      mode = self.get_mode(term)
      case mode
      when "rand"
        msg = "Unrandomising #{term}"
        self.set_mode(term,nil)
      else
        msg = "Randomising #{term}"
        self.set_mode(term,"rand")
      end
      return [msg:msg,to:to]

    # TODO: sed-edit a term ?

    # forget <term>
    # forget <term> n where n = 0,1,2,3,

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

    when /^(\S+)\?\s*$/
      search = $1
      arr = self.search(search)
      if arr.empty? then
        return [msg:"Can't find anything relevant #{from}",to:to]
      else
        return [
          to:to,
          msg:"You might want to look at these terms #{from}: " + arr.join(', '),
        ]
      end

    # ",term" or ",term n"

    when /^(\S+)(\s*\S+)?\s*$/
      term = $1
      n = $2

      # If we find n, then set nstr.
      n = n.to_i if n
      nstr = n ? "[#{n}]" : ""

      # Fetch the term.
      val = self.term(term)

      if val then
        if n then
          msg = [msg:"#{term}#{nstr} is: #{val[n]}",to:to]
        elsif self.get_mode(term) == "rand" then
          msg = [msg:"#{term}#{nstr} is: #{val.sample}",to:to]
        elsif val.size == 1 then
          msg = [msg:"#{term}#{nstr} is: #{val[0]}",to:to]
        else
          i = -1
          msg = [msg:"#{term}#{nstr} is: ",to:to] +
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
