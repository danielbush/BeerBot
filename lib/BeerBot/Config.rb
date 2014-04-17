# The files in this directory are part of BeerBot, a a ruby irc bot library.
# Copyright (C) 2014 Daniel Bush
# This program is distributed under the terms of the GNU
# General Public License.  A copy of the license should be
# enclosed with this project in the file LICENSE.  If not
# see <http://www.gnu.org/licenses/>.

module BeerBot

  # Config should be loaded with the json from a config file before
  # initialisation of the system.
  #
  # It should be available to things like bot modules eg
  #   BeerBot::Config['datadir']
  # 

  Config = {}

  class << Config

    def load config
      self.reject!{true}
      self.merge!(config)
    end

    def validate!
      if not self['datadir'] then
        raise "'datadir' not set in config."
      end
      if not File.exists?(self['datadir'])
        raise "datadir:'#{self['datadir']}' doesn't exist."
      end
    end

    # Return path for module subdir.

    def module name,&block
      self.validate!
      datadir = self['datadir']
      path = File.join(datadir,'modules',name)
      if not File.exists?(path) then
        FileUtils.mkdir_p(path)
      end
      if block_given? then
        Dir.chdir(path) {
          block.call(path)
        }
      else
        path
      end
    end

  end

end
