# The files in this directory are part of BeerBot, a a ruby irc bot library.
# Copyright (C) 2014 Daniel Bush
# This program is distributed under the terms of the GNU
# General Public License.  A copy of the license should be
# enclosed with this project in the file LICENSE.  If not
# see <http://www.gnu.org/licenses/>.

require 'json'
module BeerBot
  module Utils
    # A class that loads data from a file and allows you to access it
    # using the #data method.
    #
    # If the file is updated (after >=1 sec), #data will reload.
    class DataFile
      attr_reader :reloaded  # true if last call to #data reloaded file
      def initialize filepath
        @filepath = filepath
        @data = File.read(filepath)
        @mtime = File.stat(filepath).mtime
        @reloaded = false
      end
      def data
        @reloaded = false
        return @data unless File.exists?(@filepath)
        mtime = File.stat(@filepath).mtime
        return @data if mtime == @mtime
        puts "Reloading data file #{@filepath}"
        @mtime = mtime
        @data = File.read(@filepath)
        @reloaded = true
        @data
      end
    end
    # Specialised DataFile that parses json.
    class JsonDataFile < DataFile
      attr_reader :json
      def initialize filepath
        super
        @json = JSON.parse(@data)
      end
      def data
        super
        begin
          if @reloaded then
            json = JSON.parse(@data)
            @json = json
          end
        rescue => e
          return @json
        end
        @json
      end
    end
  end
end
