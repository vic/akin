require File.expand_path("../../spec_helper", __FILE__)

describe Akin::Parser::Match do

  @syntax = Akin::Parser::Syntax.define do
    a(:seq).is "s", "e", "q"

    eol = Module.new do
      attr_reader :old_pos

      def fwd
        return @line_fwd if @line_fwd
        fwd = super
        if positive?
          pos = fwd.position
          @old_pos = pos.clone
          pos.logical.incr!(1, nil, 0)
          pos.physical.incr!(1, nil, 0)
        end
        @line_fwd = fwd
      end
    end

    cont = Module.new do
      def eol
        self[1]
      end

      def type
        eol.name
      end

      def char
        if positive?
          " "
        else
          super
        end
      end

      def fwd
        return @escaped_fwd if @escaped_fwd
        fwd = super
        if positive?
          n = if type == :unix_eol then -1 else -2 end
          fwd.position.logical = eol.old_pos.logical.incr(0, n, n)
        end
        @escaped_fwd = fwd
      end
    end

    a(:unix_eol).is "\n"
    a(:win_eol).is "\r\n"
    a(:eol).as(eol).is [:unix_eol, :win_eol]
    a(:escaped_eol).as(cont).is "\\", :eol
  end

  def a(*a, &b)
    @syntax.a(*a, &b)
  end

  def input(text)
    r = Akin::Parser::CharReader.from_string(text)
    f = Akin::Parser::FilePosition.new :eval, Akin::Parser::CharPosition.default
    Akin::Parser::MatchInput.new(r, f)
  end

  describe "#match on a single char" do
    it "returns a positive Match instance on success" do
      m = a("a").match input("a")
      m.should be_kind_of(Akin::Parser::Match)
      m.positive?.should be_true
    end

    it "returns a negative Match instance on failure" do
      m = a("a").match input("b")
      m.should be_kind_of(Akin::Parser::Match)
      m.negative?.should be_true
    end

    it "returns a positive match with position" do
      m = a("hello").match i = input("hello_world")
      m.positive?.should be_true
      m.from.should == i
      m.to.position.logical.pos.should == [1, 5, 5]
      m.fwd.position.logical.pos.should == [1, 6, 6]
    end

    it "returns a negative match with position" do
      m = a("hello").match i = input("hell_boy")
      m.positive?.should be_false
      m.from.should == i
      m.to.position.logical.pos.should == [1, 4, 4]
      m.fwd.should == i
    end

    it "returns a negative Match instance on failure" do
      m = a("a").match i = input("b")
      m.negative?.should be_true
      m.from.should == i
      m.to.should be_nil
      m.fwd.should == i
    end

    it "returns a match with from,to positions set" do
      m = a(:seq).match i = input("seq")
      m.positive?.should be_true
      m.from.position.logical.pos.should == [1, 1, 1]
      m.to.position.logical.pos.should == [1, 3, 3]
    end
  end

  describe "#but" do
    it "matches on anything not a single string" do
      m = a("a").but.match i = input("b")
      m.positive?.should be_true
      m.from.should == i
      m.to.should == i
      m.fwd.should == i.fwd
    end

    it "matches on anything not a choise" do
      m = a(["a", "b"]).but.match i = input("c")
      m.positive?.should be_true
      m.from.should == i
      m.fwd.should == i.fwd
    end

    it "does not match if sequence is the same" do
      m = a("f", "o", "o").but.match i = input("bar")
      m.positive?.should be_true
      m.from.should == i
      m.to.should == i.fwd.fwd
      m.fwd.should == i.fwd.fwd.fwd
    end

    it "does not match if sequence is the same" do
      m = a("f", "o", "o").but.match i = input("foo")
      m.positive?.should be_false
      m.from.should == i
      m.to.should == nil
      m.fwd.should == i
    end
  end

  describe "#not" do
    it "does not consume input on invalid match" do
      m = a("a").not.match i = input("b")
      m.positive?.should be_true
      m.from.should == i
      m.to.should == nil
      m.fwd.should == i
    end

    it "does not consume input on invalid sequence match" do
      m = a("a", "b", "c").not.match i = input("foo")
      m.positive?.should be_true
      m.from.should == i
      m.to.should == nil
      m.fwd.should == i
    end
  end

  describe "+ operator" do
    it "returns a new sequence match object" do
      f = a("a") + a("b")
      m = f.match input("ab")
      m.positive?.should be_true
    end
  end

  describe "| operator" do
    it "returns a new alternation match object" do
      f = a("a") | a("b")
      f.match(input("b")).positive?.should be_true
      f.match(input("c")).positive?.should be_false
      f.match(input("a")).positive?.should be_true
    end
  end

  describe "#one repetition" do
    it "is positive is matched once" do
      o = a("a").one
      m = o.match input("aa")
      m.positive?.should be_true
    end

    it "is negative if not matched once" do
      o = a("a").one
      m = o.match input("b")
      m.positive?.should be_false
    end
  end

  describe "#opt repetition" do
    it "is positive if matched once" do
      m = a("a").opt.match i = input("a")
      m.positive?.should be_true
      m.fwd.should == i.fwd
    end

    it "is positive if not matched once" do
      m = a("a").opt.match i = input("b")
      m.positive?.should be_true
      m.fwd.should == i
    end
  end

  describe "#rep(0,0)" do
    it "is positive if not matched" do
      m = a("a").rep(0,0).match i = input("b")
      m.positive?.should be_true
      m.fwd.should == i
    end

    it "is negative if matched" do
      m = a("a").rep(0,0).match i = input("a")
      m.positive?.should be_false
      m.fwd.should == i
    end
  end

  describe "#rep(1, 2)" do
    it "is positive if matched once" do
      m = a("a").rep(1,2).match i = input("ab")
      m.positive?.should be_true
      m.fwd.should == i.fwd
    end

    it "is positive if matched twice" do
      m = a("a").rep(1,2).match i = input("aab")
      m.positive?.should be_true
      m.fwd.should == i.fwd.fwd
    end
  end


  describe "#rep(1, nil)" do
    it "is negative if not matched once" do
      m = a("a").rep(1,nil).match i = input("b")
      m.positive?.should be_false
      m.fwd.should == i
    end

    it "is positive if matched once" do
      m = a("a").rep(1,nil).match i = input("ab")
      m.positive?.should be_true
      m.fwd.should == i.fwd
    end

    it "is positive if matched twice" do
      m = a("a").rep(1,nil).match i = input("aab")
      m.positive?.should be_true
      m.fwd.should == i.fwd.fwd
    end

    it "is positive if matched many times" do
      m = a("a").rep(1,nil).match i = input("aaaaaaab")
      m.positive?.should be_true
      m.fwd.should == i.fwd.fwd.fwd.fwd.fwd.fwd.fwd
    end
  end

  describe "#rep(0, nil)" do
    it "is positive if matched once" do
      m = a("a").rep(0,nil).match i = input("b")
      m.positive?.should be_true
      m.fwd.should == i
    end

    it "is positive if matched once" do
      m = a("a").rep(0,nil).match i = input("ab")
      m.positive?.should be_true
      m.fwd.should == i.fwd
    end

    it "is positive if matched twice" do
      m = a("a").rep(0,nil).match i = input("aab")
      m.positive?.should be_true
      m.fwd.should == i.fwd.fwd
    end

    it "is positive if matched many times" do
      m = a("a").rep(0,nil).match i = input("aaaaaaab")
      m.positive?.should be_true
      m.fwd.should == i.fwd.fwd.fwd.fwd.fwd.fwd.fwd
      m.count.should == 7
    end
  end

  describe "#as given a symbol" do
    it "sets the match name to the symbol" do
      m = a("a").as(:foo).match i = input("a")
      m.name.should == :foo
    end
  end

  describe "#as given a module" do
    it "extends the match object with mixin if match is positive" do
      m = a("a").as(Comparable).match i = input("a")
      m.should be_kind_of(Comparable)
    end

    it "does not extends the match object with mixin if match is negative" do
      m = a("a").as(Comparable).match i = input("b")
      m.should_not be_kind_of(Comparable)
    end

    it "extends the match object with mixin" do
      m = a(:eol).match input("\na")
      m.positive?.should be_true
      m.name.should == :unix_eol
      m.fwd.position.physical.pos.should == [2, 1, 2]
      m.fwd.position.logical.pos.should == [2, 1, 2]

      m = a(:eol).match input("\r\na")
      m.positive?.should be_true
      m.name.should == :win_eol
      m.fwd.position.physical.pos.should == [2, 1, 3]
      m.fwd.position.logical.pos.should == [2, 1, 3]
    end

    it "extends the match escaped unix eol with mixin" do
      m = a(:escaped_eol).match input("\\\na")
      m.positive?.should be_true
      m.type.should == :unix_eol
      m.char.should == " "
      m.fwd.position.physical.pos.should == [2, 1, 3]
      m.fwd.position.logical.pos.should == [1, 2, 2]
    end

    it "extends the match escaped win eol with mixin" do
      m = a(:escaped_eol).match input("\\\r\na")
      m.positive?.should be_true
      m.type.should == :win_eol
      m.char.should == " "
      m.fwd.position.physical.pos.should == [2, 1, 4]
      m.fwd.position.logical.pos.should == [1, 2, 2]
    end
  end

  
  describe "composite rule" do
    it "matches an enclosed text between abc" do
      x = a("a", "b", "c")
      y = a(x, a(x.not, /./).any, x)
      y.match(input("abcabc")).positive?.should be_true
      y.match(input("abc   abc")).positive?.should be_true
      y.match(input("abcdefabc")).positive?.should be_true
    end
  end

end

