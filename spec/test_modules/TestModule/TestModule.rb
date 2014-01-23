# The files in this directory are part of BeerBot, a a ruby irc bot library.
# Copyright (C) 2013 Daniel Bush
# This program is distributed under the terms of the GNU
# General Public License.  A copy of the license should be
# enclosed with this project in the file LICENSE.  If not
# see <http://www.gnu.org/licenses/>.

module BeerBot; module Modules; end; end

module BeerBot::Modules::TestModule
  def self.make name
    @instance = TestClass.new(name)
  end
  def self.cmd msg,from:nil,to:nil,world:nil,me:false
    @instance.cmd msg,from:nil,to:nil,world:nil,me:false
  end
  def self.hear msg,from:nil,to:nil,world:nil
    @instance.hear msg,from:nil,to:nil,world:nil
  end

  class TestClass
    def initialize name
      @name
    end
    def cmd msg,from:nil,to:nil,world:nil,me:false
      [to:from,msg:@name]
    end
    def hear msg,from:nil,to:nil,world:nil
      [to:from,msg:@name]
    end
  end
end

