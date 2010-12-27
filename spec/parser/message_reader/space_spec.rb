require File.expand_path("../../../spec_helper", __FILE__)
require 'akin/parser/message_reader'
require 'akin/parser/char_at'
require 'akin/parser/char_reader'
require 'akin/parser/position'

describe Akin::Parser::MessageReader do
  def read(type, code)
    if code.kind_of?(String)
      at = Akin::Parser::CharAt.from(Akin::Parser::CharReader.from_string(code),
                                     Akin::Parser::FilePosition.new(:eval))
    else
      at = code
    end
    Akin::Parser::MessageReader.new.send "read_#{type}", at
  end

  it "parses space" do
    o = read :space, "    "
    o.should_not be_nil
    o.kind_of?(Akin::Parser::Message).should be_true
    o.type.should == :space
    o.data.should == "    "
  end

  it "parses tab as space" do
    o = read :space, " \t "
    o.type.should == :space
    o.data.should == " \t "
  end

  it "parses escaped unix-eol as space" do
    o = read :space, "  \\\n  "
    o.type.should == :space
    o.data.should == "    "
  end

  it "parses escaped win-eol as space" do
    o = read :space, "  \\\r\n  "
    o.type.should == :space
    o.data.should == "    "
  end

end
