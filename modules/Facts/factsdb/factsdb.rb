
# A simple database for storing facts intended for things like an irc
# bot.

module FactsDb

  @@pwd = File.expand_path(File.dirname(__FILE__))

  require 'sqlite3'

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
  # set it here.

  def self.dbfile= dbfile
    @db = nil  # force new database instance
    @dbfile = dbfile
  end

  def self.dbfile
    @dbfile
  end

  def self.db
    raise "dbfile not set" unless @dbfile
    @db ||= SQLite3::Database.new(@dbfile)
    @db
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
  # Return false if we fail to add.

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


end
