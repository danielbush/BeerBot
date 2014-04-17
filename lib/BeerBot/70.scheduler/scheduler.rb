# The files in this directory are part of BeerBot, a a ruby irc bot library.
# Copyright (C) 2014 Daniel Bush
# This program is distributed under the terms of the GNU
# General Public License.  A copy of the license should be
# enclosed with this project in the file LICENSE.  If not
# see <http://www.gnu.org/licenses/>.

require_relative '../../../ext/RubyCron/lib/RubyCron'
require 'rubygems'
require 'active_support'
#require 'active_support/time_with_zone'
#require 'active_support/values/time_zone'
require 'active_support/core_ext/time/zones'

module BeerBot
  module Scheduler
    def self.instance timezone=nil
      @@instance ||= RubyCron::Cron.new
      if timezone then
        @@instance.time {
          Time.use_zone(timezone) {
            Time.zone.now
          }
        }
      end
      @@instance
    end
  end
end
