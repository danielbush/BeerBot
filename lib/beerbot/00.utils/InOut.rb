# The files in this directory are part of BeerBot, a a ruby irc bot library.
# Copyright (C) 2014 Daniel Bush
# This program is distributed under the terms of the GNU
# General Public License.  A copy of the license should be
# enclosed with this project in the file LICENSE.  If not
# see <http://www.gnu.org/licenses/>.

module BeerBot
  module Utils

    # Represents a thread that waits on an in-queue, processes any
    # things received and puts them on an out-queue.

    class InOut

      attr_reader :inq,:outq,:run,:thread

      def initialize inq:nil,outq:nil,&block
        @inq = inq
        @outq = outq
        @run = block
        raise "No block given" unless block_given?
      end

      def start!
        @thread = Thread.new {
          loop {
            begin
              thing = @inq.deq
              response = @run.call(thing)
              if response then
                @outq.enq(response)
              else
                # TODO
              end
            rescue => e
              puts e
              puts e.backtrace
            end
          }
        }
      end

    end
  end
end
