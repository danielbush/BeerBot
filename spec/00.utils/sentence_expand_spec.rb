require_relative "../../lib/BeerBot/00.utils/sentence_expand.rb"
require 'pp'

describe "sentence sentence expansion", :param_expand => true do

  params1 = {
    'ithink' => [nil,"I think","Perhaps","Clearly"],
    'youmust' => [
      "you must",
      "you are going to have to",
      "you will have to"
    ],
    'dothis' => [
      "spend some time thinking on this",
      "think some more about this",
      "think some more on this",
      "search inside yourself",
      "ponder this for some time"
    ],
    'toget' => [
      "to get",
      "to obtain",
      "to find"
    ],
    'this' => [
      "that answer",
      "the answer",
      "the answer to that one",
      "the thing you want answered"
    ],
  }


  #":expletive do you think I'm :something ?",
  params2 = {
    'expletive' => [
      nil,"srsly,","ffs,","seriously,",
      "for the love of all things silicon"
    ],
    'something' => [
      "google",
      "your :slave",
      "just here to help you",
      "just here to help little ol' you",
      "sitting here just :towaste on :you"
    ],
    'slave' => [
      "slave",
      "PA",
      "own personal answering service",
    ],
    'towaste' => [
      "to :waste :precious compute cycles",
      "to :waste my :precious cpu time",
      "to :waste my :precious cycles"
    ],
    'precious' => [
      nil, "precious", "valuable"
    ],
    'waste' => [
      "waste", "squander", "use up", "fitter away",
    ],
    'you' => [
      "you",
      "lowly carbon-based life forms :likeyou",
      "a hapless soul :likeyou",
    ],
    'likeyou' => ["like you","such as you"],
  }

  it "should generate sentences with a valid spec" do
    100.times do
      # This is a bit crap.
      sentence = ":ithink :youmust :dothis :toget :this ::from"
      BeerBot::Utils::SentenceExpand.expand(sentence,params1)
    end
  end

  it "should omit param lookups that don't exist by default" do
    sentence = ":zzz :youmust :dothis :toget :this ::from"
    BeerBot::Utils::SentenceExpand.expand(sentence,params1)
  end

  it "can raise an error if key lookups don't exist" do
    sentence = ":zzz :youmust :dothis :toget :this ::from"
    expect{
      BeerBot::Utils::SentenceExpand.expand(sentence,params1,true)
    }.to raise_error
  end

end

