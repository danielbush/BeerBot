# The files in this directory are part of BeerBot, a a ruby irc bot library.
# Copyright (C) 2013,2014 Daniel Bush
# This program is distributed under the terms of the GNU
# General Public License.  A copy of the license should be
# enclosed with this project in the file LICENSE.  If not
# see <http://www.gnu.org/licenses/>.

require_relative '../lib'

module BeerBot; module Modules; end; end

module BeerBot::Modules::TestModule1

  def self.instance
    TestClass.new('testmodule1')
  end

end