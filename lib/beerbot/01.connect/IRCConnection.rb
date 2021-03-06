# The files in this directory are part of BeerBot, a a ruby irc bot library.
# Copyright (C) 2013,2014 Daniel Bush
# This program is distributed under the terms of the GNU
# General Public License.  A copy of the license should be
# enclosed with this project in the file LICENSE.  If not
# see <http://www.gnu.org/licenses/>.

require 'socket'
require 'set'

module BeerBot

  # An instance of IRCConnection represents a specific connection to
  # an irc server (for a given user/bot).
  #
  # We also do some low-level bookkeeping, like returning pong and
  # looking for welcome message.

  class IRCConnection

    # Queue containing received messages from the server.
    attr_accessor :queue,:writeq,:readyq
    attr_accessor :connection,:server,:port,:nick,:thread
    attr_accessor :echo

    def initialize server:nil,port:6667,nick:'beerbot'
      @echo = true
      @server = server
      @port = port
      @nick = nick
      @queue = Queue.new   # received messages
      @writeq = Queue.new  # messages to send out

      # This queue is only used at start up when the connection
      # to the irc server isn't ready yet:
      @readyq = Queue.new
      @ready = false
      @ready_blocks = []
      @ready_mutex = Mutex.new
      @write_mutex = Mutex.new

    end

    # Flag the connection as ready.
    #
    # Any blocks passed to ready? will now be executed.

    def ready!
      @ready_mutex.synchronize {
        unless @ready_blocks.empty? then
          @ready_blocks.each{|b| @readyq.enq(b)}
        end
        @ready = true
        while @readyq.size > 0
          block = @readyq.deq
          @ready_blocks.push(block)
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
    #
    # May throw errors.
    # - @connection.eof? can throw things like ECONNRESET etc

    def open connection=nil
      @thread = Thread.new {
        loop do
          begin
            if connection then
              @connection = connection
              @connection.open(self.server, self.port)
            else
              @connection = TCPSocket.open(self.server, self.port)
            end
            self.write("USER #{@nick} #{@nick} #{@nick} :#{@nick}")
            self.write("NICK #{@nick}")
            while not @connection.eof? do
              str = @connection.gets()
              puts "<< #{str}" if @echo
              case str
              when /^PING (.*)$/
                self.write "PONG #{$1}"
              when / 001 / # ready
                self.ready!
              else
                self.queue.enq(str)
              end
            end
          rescue => e
            puts "Connection whoops: #{e}"
          end
          @ready = false
          puts "Sleeping #{10} then try again..."
          sleep 10
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
        puts ">> #{message}" if @echo
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
