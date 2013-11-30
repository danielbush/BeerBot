# The files in this directory are part of BeerBot, a a ruby irc bot library.
# Copyright (C) 2013 Daniel Bush
# This program is distributed under the terms of the GNU
# General Public License.  A copy of the license should be
# enclosed with this project in the file LICENSE.  If not
# see <http://www.gnu.org/licenses/>.

module BeerBot
  class Connection
    attr_accessor :queue
    def initialize
      @queue = Queue.new
    end
    def open
    end
    def close
    end
    def write str
    end
    def ready? &block
    end
  end
end
