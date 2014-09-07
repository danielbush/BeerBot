# The files in this directory are part of BeerBot, a a ruby irc bot library.
# Copyright (C) 2014 Daniel Bush
# This program is distributed under the terms of the GNU
# General Public License.  A copy of the license should be
# enclosed with this project in the file LICENSE.  If not
# see <http://www.gnu.org/licenses/>.

module BeerBot
  module Scheduler

    CronR = ::CronR

    def self.instance timezone=nil
      @instance ||= CronR::Cron.new
      if timezone then
        @instance.timezone = timezone
      end
      @instance
    end

  end
end
