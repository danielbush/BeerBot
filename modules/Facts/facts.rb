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

  require_relative '../../lib/BeerBot'
  require_relative 'factsdb/factsdb.rb'

  Utils  = ::BeerBot::Utils
  BotMsg = ::BeerBot::Protocol::BotMsg
  Config = ::BeerBot::Config

  def self.dbfile
    File.join(Config.module_data('Facts'),'facts.db')
  end

  def self.db
    return @db if @db

    @db   = ::FactsDb
    @db.dbfile = self.dbfile
    @db
  end

  def self.db= obj
    @db = obj
  end

  def self.cmd msg,from:nil,to:nil,me:false,world:nil

    self.db.build_tables!
    replyto = me ? from : to

    case msg

    # ",term is also: ..."
    when /^(\S+)\s+is\s+also:\s*(.*)$/
      term = $1
      fact = $2
      ok = self.db.add(term,fact,false)
      if ok then
        if rand(2) == 0 then
          msg = "Noted #{from}"
          return [msg:msg,to:replyto]
        else
          action = "carefully writes it down"
          return [action:action,to:replyto]
        end
      else
        if not self.db.valid_term?(term) then
          return [to:replyto,msg:"Failed to store term! Terms should not contain square brackets or start with punctuation."]
        else
          return [to:replyto,msg:"Failed to store term!"]
        end
      end

    # ",term is: ..."
    when /^(\S+)\s+is:\s*(.*)$/
      term = $1
      fact = $2
      if self.db.term(term) then
        return [msg:"Term already exists #{from} use ',<term> is also ...' or ',forget <term>' .",to:replyto]
      end
      ok = self.db.add(term,fact.strip)
      if ok then
        msg = "Noted #{from}"
      else
        if not self.db.valid_term?(term) then
          msg = "Failed to store term! Terms should not contain square brackets or start with punctuation."
        else
          msg = "Failed to store term!"
        end
      end
      return [msg:msg,to:replyto]

    # If we see an interpolation and we were commanded eg
    # "Beerbot, say ,,hi"
    when /,,(\S+)(\s+\d+)?/
      return self.hear msg,from:from,to:to,me:me,world:world

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
        result = self.db.swap(term,m,n)
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
        result = self.db.before(term,m,n)
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
      if self.db.term(term) then
        if n then
          n = n.to_i
          result = self.db.delete(term,n)
          if result then
            return [msg:"Deleted #{term}[#{n}]",to:replyto]
          else
            return [msg:"Can't delete #{term}[#{n}]",to:replyto]
          end
        else
          self.db.delete(term)
          return [msg:"Removed entry #{from}",to:replyto]
        end
      else
        return [msg:"Can't find this term #{from}",to:replyto]
      end

    # <term> n s///

    when /^(\S+)(\s+\d+)\s+(s[^A-z0-9\s].+)$/
      term = $1
      n = $2.to_i
      sed = $3.strip
      m = Utils.sed_regex.match(sed)
      unless m then
        return [to:replyto,msg:"No dice."]
      end
      
      before = m[:before]
      after = m[:after]
      pattern = m[:pattern]
      replacement = m[:replacement]
      flags = m[:flags]

      arr = self.db.term(term)
      return [to:replyto,msg:"Don't know this term."] if not arr
      entry = arr[n]
      return [to:replyto,msg:"You sure that index is right?"] if not entry

      if flags =~ /g/ then
        arr[n] = entry.gsub(pattern,replacement)
      else
        arr[n] = entry.sub(pattern,replacement)
      end
      self.db.delete(term)
      arr.each {|t|
        self.db.add(term,t)
      }
      return [to:replyto,msg:"#{term}[#{n}] is now '#{arr[n]}'"]



    # ",term?"

    when /^(\S+)\?\s*$/
      search = $1
      arr = self.db.search(search)
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
    when /^(\S+)\s+(nomode|rand|reply)\s*$/
      term = $1
      new_mode = $2
      if not self.db.term(term) then
        return [to:replyto,msg:"Don't know this term, #{from}"]
      end
      mode = self.db.get_mode(term)

      if mode == new_mode then
        msg = "#{mode} mode already set"
        return [msg:msg,to:replyto]
      end

      case new_mode
      when "nomode"
        self.db.set_mode(term,nil)
        msg = "Turning off #{mode} mode."
      when "rand","reply"
        self.db.set_mode(term,new_mode)
        msg = "Setting mode to #{new_mode} on #{term}"
      else
        msg = "wtf?"
      end
      return [msg:msg,to:replyto]

    when /^(\S+)\s+(\S+.*)$/
      term = $1
      params = $2
      params = params.split(/\s+/)
      self.reply(term,nil,to:to,from:from,params:params)

    else
      return nil
    end

  end

  def self.hear msg,from:nil,to:nil,me:false,world:nil
    self.db.build_tables!
    case msg
    when /,,(\S+)(\s+\d+)/
      term = $1
      n = $2
      n = n.to_i if n
      return self.reply(term,n,to:to,from:from)
    when /,,(\S+)\s(.*)$/
      term = $1
      params = $2
      params = params.split(/\s+/)
      #byebug
      return self.reply(term,n,to:to,from:from,params:params)
    end
  end

  # ------------------------------------------------------------



  # Return a botmsg array for term or nth entry.
  #
  # If term has a mode, we process it here.

  def self.reply term,n=nil,to:nil,from:nil,params:nil

    nstr = n ? "[#{n}]" : ""

    # Fetch the term.
    val = self.db.term(term)

    if val then

      # Modes
      if mode = self.db.get_mode(term) then
        case mode
        when "rand"
          v,err = Utils.expand(val.sample,from:from)
          msg = [msg:"#{term}#{nstr} is: #{v}",to:to]
        when "reply"
          v = val.sample
          params = [] unless params
          v,err = Utils.expand(v,*params,from:from)
          if err.size > 0 then
            msg = [to:to,msg:"Need at least #{err.max} arguments #{from}"]
          else
            msg = BotMsg.actionify([msg:v,to:to])
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
        msg = [msg:"hmm I think #{term}#{nstr} is: ",to:to] +
                val.map{|v| {msg:"[%d] %s" % [i+=1,v],to:to} }
      end
    else
      #msg = [msg:"Don't know this term #{from}",to:to]
      return nil
    end
    return msg
  end

  def self.help arr=[]
    topic,*subtopics = arr
    if not topic then
      [ "Allows you to store terms in a database.  Each term has one or more entries.",
        "Topics: add,forget,edit,search,modes,swap,parameters"]
    else
      case topic
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
          "<term> nomode # turn off modes, and resume default entry listing behaviour",
          "<term> rand # toggle random selection of entry in term",
          "<term> reply # bot selects entry and says it; if entry starts with '*', /me action is performed",
        ]
      when 'swap'
        [
          "<term> swap m n # swap mth and nth terms in entry",
          "<term> m before n ",
        ]
      when 'parameters'
        [
          "When in reply-mode certain patterns starting with '::' will get expanded:",
          "an entry that starts with '*' becomes a /me-style action",
          "::from will expand to the person messaging the bot",
          "::n where n=1,2,3.. will expand to args passed after the term, eg <term> arg1 arg2 etc",
          ":: expands to nothing",
          "combinations are pipe-delimited, the first existing one is used:",
          "eg ::2|::1 will expand 1st if 2nd arg not provided",
        ]
      else
        ["No information"]
      end
    end
  end

end
