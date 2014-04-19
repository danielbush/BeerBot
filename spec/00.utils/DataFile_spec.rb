require_relative "../../lib/BeerBot/00.utils/DataFile.rb"
require 'pp'
require 'json'

DataFile = BeerBot::Utils::DataFile
JsonDataFile = BeerBot::Utils::JsonDataFile

describe "DataFile class" do
  filepath1 = '/tmp/beerbotDataFile.dat'
  filepath2 = '/tmp/beerbotDataFile.json'
  before(:each) do
    File.write(filepath1,'blah')
  end
  it "should load a file as a string" do
    DataFile.new(filepath1).data.should == 'blah'
  end
  it "should update the loaded string if the file is updated after >=1 second" do
    d = DataFile.new(filepath1)
    d.data.should == 'blah'
    sleep 1  # ick
    File.write(filepath1,'foo')
    d.data.should == 'foo'
  end
  it "should use the cached data if file no longer exists" do
    d = DataFile.new(filepath1)
    File.unlink(filepath1)
    d.data.should == 'blah'
  end
  it "should raise an error if file never existed" do
    File.unlink(filepath1)
    expect {DataFile.new(filepath1)}.to raise_error
  end
  describe "JSON data file class" do
    before(:each) do
      File.write(filepath2,{'a' => [1,2]}.to_json)
    end
    it "should load and parse valid json" do
      JsonDataFile.new(filepath2).data['a'][0].should == 1
    end
    it "should return cached data if json becomes invalid" do
      d = JsonDataFile.new(filepath2)
      File.write(filepath2,'{')
      d.data['a'][0].should == 1
    end
    it "should update data if file changes >= 1 sec" do
      d = JsonDataFile.new(filepath2)
      d.data['a'][0].should == 1
      sleep 1
      File.write(filepath2,{'b' => [3,4]}.to_json)
      d.data['a'].should == nil
      d.data['b'][0].should == 3
    end
  end
end

