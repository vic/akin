# -*- coding: utf-8 -*-
require File.expand_path("../../spec_helper", __FILE__)
require 'akin/parser/char_reader'

describe Akin::Parser::CharReader do

  def reader(str)
    Akin::Parser::CharReader.from_string(str)
  end

  it "be constructed from an string" do
    reader("hello").should_not be_nil
  end

  it "initial position should be zero" do
    reader("hello").index.should == 0
  end

  it "size should return the number of characters in string" do
    reader("hello").size.should == 5
  end

  it "read should return the first character as string" do
    reader("hello").read.should == "h"
  end

  it "read should advance position by one" do
    reader = reader("hello")
    reader.read
    reader.index.should == 1
  end

  it "read should return nil at end of buffer" do
    reader = reader("hello")
    reader.read.should == "h"
    reader.read.should == "e"
    reader.read.should == "l"
    reader.read.should == "l"
    reader.read.should == "o"
    reader.index.should == 5
    reader.read.should be_nil
    reader.index.should == 5
    reader.read.should be_nil
  end

  it "reports length by codepoints" do
    reader = reader("árbol")
    reader.size.should == 5
  end

  it "reads a codepoint at a time" do
    reader = reader("árbol")
    reader.read.should == "á"
  end

  it "reads a codepoint at a time" do
    reader = reader 'こんにちは'
    reader.read.should == 'こ'
    reader.read.should == 'ん'
    reader.read.should == 'に'
    reader.read.should == 'ち'
    reader.read.should == 'は'
    reader.read.should be_nil
  end
end
