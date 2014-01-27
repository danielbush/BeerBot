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
