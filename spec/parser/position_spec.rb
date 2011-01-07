require File.expand_path("../../spec_helper", __FILE__)

describe Akin::Parser::CharPosition do
  describe "#pos" do
    def new(*args)
      Akin::Parser::CharPosition.new(*args)
    end

    it "returns the line position as an array of fixnums" do
      new(1, 1, 1).pos.should == [1, 1, 1]
    end
  end

  describe "#clone" do
    it "returns a new instance with same position data" do
      new(1, 1, 1).tap { |cp| cp.clone.pos.should == cp.pos }
    end
  end
end

describe Akin::Parser::FilePosition do
  def from(*args)
    Akin::Parser::FilePosition.from(*args)
  end

  it "holds a logical and physical char positions" do
    a = from(:spec, 1, 1, 1)
    a.logical.should be_kind_of(Akin::Parser::CharPosition)
    a.physical.should be_kind_of(Akin::Parser::CharPosition)
  end

  describe "#forward_char" do
    it "returns a new instance" do
      a = from(:spec, 1, 1, 1)
      b = a.forward_char
      a.should_not eql(b)
    end

    it "advances both positions by one char" do
      a = from(:spec, 1, 1, 1)
      b = a.forward_char
      b.logical.pos.should == [1, 2, 2]
      b.physical.pos.should == b.logical.pos
      b.filename.should eql(a.filename)
    end
  end

  describe "#forward_line" do
    it "returns a new instance" do
      a = from(:spec, 1, 1, 1)
      b = a.forward_line
      a.should_not eql(b)
    end

    it "advances both positions by one line" do
      a = from(:spec, 1, 1, 1)
      b = a.forward_line
      b.logical.pos.should == [2, 1, 2]
      b.physical.pos.should == b.logical.pos
      b.filename.should eql(a.filename)
    end
  end

  describe "#forward_esc_line" do
    it "returns a new instance" do
      a = from(:spec, 1, 1, 1)
      b = a.forward_esc_line
      a.should_not eql(b)
    end

    it "advances logical position by one char" do
      a = from(:spec, 1, 3, 3)
      b = a.forward_esc_line
      b.logical.pos.should == [1, 4, 4]
    end

    it "advances physical position by one line" do
      a = from(:spec, 1, 3, 3)
      b = a.forward_esc_line
      b.physical.pos.should == [2, 1, 4]
    end
  end
end
