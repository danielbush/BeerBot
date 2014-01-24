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

  # Return a botmsg array for term or nth entry.
  #
  # If term has a mode, we process it here.

  def self.reply term,n=nil,to:nil,from:nil

    nstr = n ? "[#{n}]" : ""

    # Fetch the term.
    val = self.term(term)

    if val then


      # Modes
      if mode = self.get_mode(term) then
        case mode
        when "rand"
          msg = [msg:"#{term}#{nstr} is: #{val.sample}",to:to]
        when "reply"
          v = val.sample
          if v[0] == '*' then
            msg = [action:v[1..-1].strip,to:to]
          else
            msg = [msg:v,to:to]
          end
        else
          msg = [to:to,msg:"Don't know how to handle mode #{mode}!"]
        end

      # term n
      elsif n then
        msg = [msg:"#{term}#{nstr} is: #{val[n]}",to:to]

      # Default mode, only 1 entry
      elsif val.size == 1 then
        msg = [msg:"#{term}#{nstr} is: #{val[0]}",to:to]

      # Default mode, several entries
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

  # Swap entries within a term.
  #
  # Return revised array (as well as saving it to the db) or nil if
  # error.

  def self.swap term,m,n
    arr = self.term(term)
    if not arr then
      return nil
    end
    if (not arr[m]) || (not arr[n]) then
      return nil
    end
    arr[n],arr[m] = arr[m],arr[n]
    self.delete(term)
    arr.each{|t|
      self.add term,t
    }
  end

  # Move entry m before n for term.

  def self.before term,m,n
    arr = self.term(term)
    if not arr then
      return nil
    end
    if (not arr[m]) || (not arr[n]) then
      return nil
    end
    result = []
    arr.each_with_index {|entry,idx|
      case idx
      when m
      when n
        result.push(arr[m])
        result.push(arr[n])
      else
        result.push(entry)
      end
    }
    self.delete(term)
    result.each{|entry|
      self.add term,entry
    }
    return result
  end

  # Extract regex rx and replacement string str from input string of
  # form "s/rx/str/flag".
  #
  # Single quotes for rx and triple backslash to detect a backslash.
  # This should allow us to handle escaping forward slashes like this:
  #   s/\\\//.../g
  # No idea how that all works actually.  See the spec tests.
  #
  # Returns [rx,replacement,flags] or [nil,msg,nil] where msg might be
  # an error message or nil.

  def self.extract_sed_string str
    rx = Regexp.new('^s/(.*[^\\\])/(.*)/([g])?$')
    m = rx.match(str)
    return [nil,nil,nil] if not m

    begin
      r = Regexp.new(m[1])
    rescue => e
      return [nil,e.to_s,nil]
    end

    replacement = m[2]
    flags = m[3].nil? ? [] : m[3].split
    return [r,replacement,flags]
  end

  def self.help detail=nil
    if not detail then
      [ "Allows you to store terms in a database.  Each term has one or more entries.",
        "Topics: add,forget,edit,search,modes"]
    else
      case detail
      when 'add'
        [
          "<term> is: ...  # to create a new term",
          "<term> is also: ...  # to add a entry for existing term",
        ]
      when 'forget'
        [
          "forget <term> # forget the term",
          "forget <term> n  # forget entry n in term (not implemented yet)",
        ]
      when 'edit'
        [
          "<term> n s/../../g  # edit nth entry of term",
        ]
      when 'search'
        [
          "<pattern>? (case insensitive), pattern will be automatically globbed",
        ]
      when 'modes'
        [
          "<term> nomode # turn of modes, and resume default entry listing behaviour",
          "<term> rand # toggle random selection of entry in term",
          "<term> reply # bot selects entry and says it; if entry starts with '*', /me action is performed",
        ]
      when 'swap'
        [
          "<term> swap m n # swap mth and nth terms in entry",
        ]
      else
        ["No information"]
      end
    end
  end

  def self.hear msg,from:nil,to:nil,world:nil
    self.build_tables!
    case msg
    when /,,(\S+)(\s+\d+)?/
      term = $1
      n = $2
      n = n.to_i if n
      return self.reply(term,n,to:to,from:from)
    end
  end

  def self.cmd msg,from:nil,to:nil,me:false,world:nil

    self.build_tables!
    replyto = me ? from : to

    case msg

    # If we see an interpolation and we were commanded eg
    # "Beerbot, say ,,hi"
    when /,,(\S+)(\s+\d+)?/
      return self.hear msg,from:from,to:to,world:world

    # ",term is also ..."
    when /^(\S+)\s+is\s+also:\s+(.*)$/
      term = $1
      fact = $2
      ok = self.add(term,fact,false)
      if ok then
        if rand(2) == 0 then
          msg = "Noted #{from}"
          return [msg:msg,to:replyto]
        else
          action = "carefully writes it down"
          return [action:action,to:replyto]
        end
      else
        if not self.valid_term?(term) then
          return [to:replyto,msg:"Failed to store term! Terms should not contain square brackets or start with punctuation."]
        else
          return [to:replyto,msg:"Failed to store term!"]
        end
      end

    # ",term is ..."
    when /^(\S+)\s+is:\s+(.*)$/
      term = $1
      fact = $2
      if self.term(term) then
        return [msg:"Term already exists #{from} use ',<term> is also ...' or ',forget <term>' .",to:replyto]
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
      return [msg:msg,to:replyto]


    # ",term swap m n"
    when /^(\S+)\s+swap\s+(\d+)\s+(\d+)\s*$/
      term = $1
      m = $2.to_i
      n = $3.to_i
      if m == n then
        msg = [
          "That's just silly #{from}",
          "Srsly?"
        ].sample
      else
        result = self.swap(term,m,n)
        if result then
          msg = "Swapped #{m} with #{n}"
        else
          msg = "Couldn't make that swap, #{from}"
        end
      end
      return [to:replyto,msg:msg]

    # ",term m before n"
    when /^(\S+)\s+(\d+)\s+before\s+(\d+)\s*$/
      term = $1
      m = $2.to_i
      n = $3.to_i
      if m == n then
        msg = [
          "You serious?",
          "Srsly?"
        ].sample
      else
        result = self.before(term,m,n)
        if result then
          msg = "#{m} is before #{n}"
        else
          msg = "Couldn't make that change, #{from}"
        end
      end
      return [to:replyto,msg:msg]

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
            return [msg:"Deleted #{term}[#{n}]",to:replyto]
          else
            return [msg:"Can't delete #{term}[#{n}]",to:replyto]
          end
        else
          self.delete(term)
          return [msg:"Removed entry #{from}",to:replyto]
        end
      else
        return [msg:"Can't find this term #{from}",to:replyto]
      end

    # <term> n s///

    when /^(\S+)(\s+\d+)\s+(\S.*)$/
      term = $1
      n = $2.to_i
      sed = $3.strip
      rx,replacement,flags = self.extract_sed_string(sed)
      if not rx then
        if replacement then
          return [to:replyto,msg: replacement]
        else
          return [to:replyto,msg:"No dice."]
        end
      end
      arr = self.term(term)
      return [to:replyto,msg:"Don't know this term."] if not arr
      entry = arr[n]
      return [to:replyto,msg:"You sure that index is right?"] if not entry
      if flags.rindex('g')
        arr[n] = entry.gsub(rx,replacement)
      else
        arr[n] = entry.sub(rx,replacement)
      end
      self.delete(term)
      arr.each {|t|
        self.add(term,t)
      }
      return [to:replyto,msg:"#{term}[#{n}] is now '#{arr[n]}'"]



    # ",term?"

    when /^(\S+)\?\s*$/
      search = $1
      arr = self.search(search)
      if arr.empty? then
        return [msg:"Can't find anything relevant #{from}",to:replyto]
      else
        return [
          to:replyto,
          msg:"You might want to look at these terms #{from}: " + arr.join(', '),
        ]
      end

    # ",term" or ",term n"

    when /^(\S+)(\s*\d+)?\s*$/
      term = $1
      n = $2
      n = n.to_i if n
      return self.reply(term,n,to:replyto,from:from)

    # ",term nomode|rand|reply"
    when /^(\S+)\s+(\S+)\s*$/
      term = $1
      new_mode = $2
      if not self.term(term) then
        return [to:replyto,msg:"Don't know this term, #{from}"]
      end
      mode = self.get_mode(term)

      if mode == new_mode then
        msg = "#{mode} mode already set"
        return [msg:msg,to:replyto]
      end

      case new_mode
      when "nomode"
        self.set_mode(term,nil)
        msg = "Turning off #{mode} mode."
      when "rand","reply"
        self.set_mode(term,new_mode)
        msg = "Setting mode to #{new_mode} on #{term}"
      else
        msg = "wtf?"
      end
      return [msg:msg,to:replyto]

    else
      return nil
    end

  end
end
