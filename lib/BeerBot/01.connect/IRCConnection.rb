# The files in this directory are part of BeerBot, a a ruby irc bot library.
# Copyright (C) 2013 Daniel Bush
# This program is distributed under the terms of the GNU
# General Public License.  A copy of the license should be
# enclosed with this project in the file LICENSE.  If not
# see <http://www.gnu.org/licenses/>.

require 'socket'
require 'set'
require_relative 'Connection'

module BeerBot

  # An instance of IRCConnection represents a specific connection to
  # an irc server (for a given user/bot).
  #
  # We also do some low-level bookkeeping, like returning pong and
  # looking for welcome message.

  class IRCConnection < Connection

    # Queue containing received messages from the server.
    attr_accessor :queue,:writeq,:readyq
    attr_accessor :connection,:server,:port,:nick,:thread

    def initialize server:nil,port:6667,nick:'beerbot'
      @server = server
      @port = port
      @nick = nick
      @queue = Queue.new   # received messages
      @writeq = Queue.new  # messages to send out

      # This queue is only used at start up when the connection
      # to the irc server isn't ready yet:
      @readyq = Queue.new
      @ready = false
      @ready_mutex = Mutex.new
      @write_mutex = Mutex.new

    end

    # Flag the connection as ready.
    #
    # Any blocks passed to ready? will now be executed.

    def ready!
      @ready_mutex.synchronize {
        @ready = true
        while @readyq.size > 0
          block = @readyq.deq
          block.call
        end
      }
    end

    def ready? &block
      return @ready unless block_given?
      @ready_mutex.synchronize {
        if @ready then
          block.call
        else
          @readyq.enq(block)
        end
      }
    end

    # Open and maintain the connection with an irc server.
    #
    # If you pass in a connection object it will be used instead of
    # opening a tcp socket.
    # It should respond to whatever is called on @connection
    # eg open,gets,write.
    # Use for testing this class.

    def open connection=nil
      if connection then
        @connection = connection
        @connection.open(self.server, self.port)
      else
        @connection = TCPSocket.open(self.server, self.port)
      end
      self.write("USER #{@nick} #{@nick} #{@nick} :#{@nick}")
      self.write("NICK #{@nick}")
      @thread = Thread.new {
        while not @connection.eof? do
          str = @connection.gets()
          puts "<< #{str}"
          case str
          when /^PING (.*)$/
            self.write "PONG #{$1}"
          when / 001 / # ready
            self.ready!
          else
            self.queue.enq(str)
          end
        end
      }
      @write_thread = Thread.new {
        loop do
          thing = @writeq.deq
          self.write thing
        end
      }

      @thread
    end

    def close
    end

    # Write out to the socket.
    #
    # Chomps message and then adds "\r\n".

    def write message
      case message
      when String
        message = message.chomp + "\r\n"
        puts ">> #{message}"
        @write_mutex.synchronize {
          @connection.print(message)
        }
      when Array
        message.each{|m| self.write(m) }
      when NilClass
      else
        puts "IRCConnection: can't process #{message}"
      end
    end

  end

end
