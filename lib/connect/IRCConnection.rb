# The files in this directory are part of BeerBot, a a ruby irc bot library.
# Copyright (C) 2013 Daniel Bush
# This program is distributed under the terms of the GNU
# General Public License.  A copy of the license should be
# enclosed with this project in the file LICENSE.  If not
# see <http://www.gnu.org/licenses/>.

require 'socket'
require 'set'
require File.dirname(__FILE__)+'/../parse/parse'
require File.dirname(__FILE__) + '/Connection'

module BeerBot

  # An instance of IRCConnection represents a specific connection to
  # an irc server (for a given user/bot).
  #
  # We also do some low-level bookkeeping, like returning pong and
  # looking for welcome message.

  class IRCConnection < Connection

    # Queue containing received messages from the server.
    attr_accessor :queue
    attr_accessor :name,:connection,:server,:port,:nick,:thread

    def initialize name,server:nil,port:6667,nick:'beerbot'
      @name = name
      @irc = BeerBot::Parse::IRC::IRCMessage
      @server = server
      @port = port
      @nick = nick
      @queue = Queue.new

      # This queue is only used at start up when the connection
      # to the irc server isn't ready yet:
      @readyq = Queue.new
      @ready = false
      @ready_mutex = Mutex.new

    end

    def ready? &block
      @ready_mutex.synchronize {
        if @ready then
          block.call
        else
          @readyq.enq(block)
        end
      }
    end

    # Open and maintain the connection with an irc server.
    def open
      @connection = TCPSocket.open(server, port)
      @open = true
      self.write("USER #{@nick} #{@nick} #{@nick} :#{@nick}")
      self.write("NICK #{@nick}")
      @thread = Thread.new {
        loop do
          break unless @open
          str = @connection.gets()
          p "<< #{str}"
          case str
          # TODO put this into parser (so we can test it easily)
          when /^PING (.*)$/
            self.write "PONG #{$1}"
          else
            m = @irc.new(str)
            if m then
              case m[:command]
              when '001'  # welcome message
                @ready_mutex.synchronize {
                  @ready = true
                  while @readyq.size > 0
                    block = @readyq.deq
                    block.call
                  end
                }
              end
              self.queue.enq([m,str])
            else
              puts "Don't recognise this command."
            end
          end
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
        p ">> #{message}"
        @connection.print(message)
      when Array
        message.each{|m| self.write(m) }
      when NilClass
      else
        p "IRCConnection: can't process #{message}"
      end
    end

  end

end
