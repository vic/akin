# -*- coding: utf-8 -*-

require File.expand_path('../spec_helper', __FILE__)

describe 'Akin grammar' do
  include_context 'grammar'

  it 'parses ascii name' do
    s('foo').should == [:name, "foo"]
  end

  it 'parses a chain of names' do
    s('foo bar').should == [:chain,
      [:name, "foo"], [:name, "bar"]]
  end

  it 'parses operator inside chain' do
    s('a + b').should == [:chain,
     [:name, "a"], [:oper, "+"], [:name, "b"]]
  end

  it 'allows new line after operator' do
    s("a +\n b").should == [:chain,
     [:name, "a"], [:oper, "+"], [:name, "b"]]
  end

  it 'allows no space after operator' do
    s("a +b").should == [:chain,
     [:name, "a"], [:oper, "+"], [:name, "b"]]
  end

  it 'allows no space between operator' do
    s("a+b").should == [:chain,
     [:name, "a"], [:oper, "+"], [:name, "b"]]
  end

  it 'allows operator to have arguments' do
    s("a +(b, c)").should == [:chain,
     [:name, "a"], [:oper, "+"], [:send, ["(", ")"], [:name, "b"], [:name, "c"]]]
  end

  it 'parses args' do
    s('a(b, c)').should ==
     [:chain, [:name, "a"],
              [:send, ["(", ")"],
               [:name, "b"], [:name, "c"]]]
  end

  it 'parses chained args' do
    s('a(b, c)[d]').should ==
     [:chain, [:name, "a"],
              [:send, ["(", ")"],
                [:name, "b"], [:name, "c"]],
              [:send, ["[", "]"],
                [:name, "d"]]]
  end

  it 'parses space args' do
    s('a (b)').should ==
     [:chain, [:name, "a"],
              [:space, ["(", ")"], [:name, "b"]]]
  end

  it 'parses empty msg'  do
   s('m = (a, b): a + b').should ==
     [:chain, [:name, "m"],
              [:oper, "="],
              [:empty, ["(", ")"],
                 [:name, "a"], [:name, "b"],
                 [:chain, [:name, "a"],
                          [:oper, "+"], [:name, "b"]]]]
  end

  it 'parses msg with single keyword' do
    s('a: b').should ==
      [:kmsg, [:part, "a", nil, [:name, "b"]]]
  end

  it 'parses msg with single keyword having commas' do
    s('a: b, c').should ==
      [:kmsg, [:part, "a", nil, [:name, "b"], [:name, "c"]]]
  end

  it 'parses msg with single argd keyword' do
    s('a(b): c').should ==
      [:kmsg, [:part, "a", ["(", ")"],
               [:name, "b"], [:name, "c"]]]
  end

  it 'parses msg with two keywords' do
    s('Point x: a y: b').should ==
      [:chain, [:name, "Point"],
       [:kmsg, [:part, "x", nil, [:name, "a"]],
               [:part, "y", nil, [:name, "b"]]]]
  end

  it 'parses msg with no args' do
    s('a: b: c').should ==
      [:kmsg, [:part, "a", nil],
              [:part, "b", nil, [:name, "c"]]]
  end

  it 'parses msg with no args' do
    s('a: b: c:').should ==
      [:kmsg, [:part, "a", nil],
              [:part, "b", nil],
              [:part, "c", nil]]
  end

  it 'allows msg to have comma separated arguments' do
    s('a: b, c').should ==
      [:kmsg, [:part, "a", nil, [:name, "b"], [:name, "c"]]]
  end

  it 'allows msg to have argument on nested line' do
    s("a:\n b").should ==
      [:kmsg, [:part, "a", nil, [:name, "b"]]]
  end

  it 'allows msg to have argument on nested line' do
    s("a: b\n c").should ==
      [:kmsg, [:part, "a", nil, [:name, "b"], [:name, "c"]]]
  end

  it 'doesnt include non-nested chain in msg' do
    s("a: b\nc").should ==
      [:block, [:kmsg, [:part, "a", nil, [:name, "b"]]], [:name, "c"]]
  end

  it 'does include same-indentation part in msg' do
    s("a: b\nc: d").should ==
      [:kmsg, [:part, "a", nil, [:name, "b"]],
       [:part, "c", nil, [:name, "d"]]]
  end

  it 'parses msg of two parts on same column' do
    s("a b: c\n  d: e").should ==
      [:chain, [:name, "a"],
       [:kmsg, [:part, "b", nil, [:name, "c"]],
               [:part, "d", nil, [:name, "e"]]]]
  end

  it 'is greedy if dot is found after semicolon' do
    s("a b:. c: d e: f").should ==
      [:chain, [:name, "a"],
       [:kmsg, [:part, "b", nil,
                [:kmsg, [:part, "c", nil, [:name, "d"]],
                        [:part, "e", nil, [:name, "f"]]]]]]
  end

  it 'stops parsing msg at semicolon on new line' do
    s("a: b\nc:d\n; e").should ==
      [:block,
       [:kmsg, [:part, "a", nil, [:name, "b"]],
        [:part, "c", nil, [:name, "d"]]],
       [:name, "e"]]
  end

  it 'stops parsing msg at dot on new line' do
    s("a: b\nc:d\n. e").should ==
      [:chain,
       [:kmsg, [:part, "a", nil, [:name, "b"]],
        [:part, "c", nil, [:name, "d"]]],
       [:name, "e"]]
  end

  it 'stops parsing msg at dot' do
    s("a: b c: d . e").should ==
      [:chain,
       [:kmsg, [:part, "a", nil, [:name, "b"]],
        [:part, "c", nil, [:name, "d"]]],
       [:name, "e"]]
  end

  it 'stops parsing msg at dot' do
    s("a b . c").should ==
      [:chain, [:name, "a"], [:name, "b"], [:name, "c"]]
  end

  it 'parses a unicode keyword message' do
    s("浪: 人").should ==
      [:kmsg, [:part, "浪", nil, [:name, "人"]]]
  end

  it 'treats semicolon as operator if enclosed by spaces' do
    s("a : b").should ==
      [:chain, [:name, "a"], [:oper, ":"], [:name, "b"]]
  end

  it 'treats double dot as operator' do
    s("a..b").should ==
      [:chain, [:name, "a"], [:oper, ".."], [:name, "b"]]
  end

  it 'allow operator arguments to be continued on next line' do
    code = <<-CODE
      a +
        b -
          c
      CODE
    s(code).should ==
      [:chain,
       [:name, "a"],
       [:oper, "+"], [:name, "b"],
       [:oper, "-"], [:name, "c"]]
  end

  it 'doesnt take operator argument unless it is nested' do
    code = <<-CODE
      a +
      b -
         c
      CODE
    s(code).should ==
      [:block,
       [:chain, [:name, "a"], [:oper, "+"]],
       [:chain, [:name, "b"], [:oper, "-"], [:name, "c"]]]
  end

  it 'parses on nested block' do
    code = <<-CODE
    foo bar
       baz: bat
       man
    CODE
    s(code).should ==
      [:chain, [:name, "foo"], [:name, "bar"],
       [:block, [:kmsg, [:part, "baz", nil, [:name, "bat"]]], [:name, "man"]]]

  end

  it 'lets semicollon continue the block until nested block' do
    code = <<-CODE
    foo bar ;
       baz: bat
       man
    CODE
    s(code).should ==
      [:chain, [:block, [:chain, [:name, "foo"], [:name, "bar"]],
                [:kmsg, [:part, "baz", nil, [:name, "bat"]]]],
       [:name, "man"]]
  end

    it 'lets semicolon continue the block' do
    code = <<-CODE
    foo bar ;
       baz: bat ;
       man
    CODE
    s(code).should ==
      [:block, [:chain, [:name, "foo"], [:name, "bar"]],
       [:kmsg, [:part, "baz", nil, [:name, "bat"]]],
       [:name, "man"]]
  end

  it 'flattens message chain' do
    s('foo.bar.baz').should ==
      [:chain, [:name, "foo"], [:name, "bar"], [:name, "baz"]]
  end

  it 'flattens message chain with oper' do
    s('foo. + bar. baz', :root).should ==
      [:chain, [:name, "foo"], [:oper, "+"], [:name, "bar"], [:name, "baz"]]
  end

  it 'parses msg before sign oper' do
    s('foo: a, b .= a + b', :root).should ==
      [:chain,
       [:kmsg, [:part, "foo", nil, [:name, "a"], [:name, "b"]]],
       [:oper, "="], [:name, "a"], [:oper, "+"], [:name, "b"]]
  end


  describe 'symbol' do
    it 'starts with a semicolon char' do
      s(':foo').should == [:symbol, [:name, "foo"]]
    end

    it 'can be an string' do
      s(':"foo"').should == [:symbol, [:text, "foo"]]
    end

    it 'can be a number' do
      s(':22').should == [:symbol, [:fixnum, 22]]
    end

    it 'can be an activation' do
      s(':(a, b)').should == [:symbol, [:space, ["(", ")"],
                                        [:name, "a"],
                                        [:name, "b"]]]
    end
  end

    describe 'text' do
    it 'is parsed by literal rule' do
      s('"hi"').should ==
        [:text, "hi"]
    end

    it 'allows interpolation' do
      s('"hi #{world}"').should ==
        [:chain, [:text, "hi "], [:oper, "++"], [:name, "world"]]
    end

    it 'parses only interpolation as to_s message' do
      s('"#{world}"').should ==
        [:chain, [:name, "world"], [:name, "to_s"]]
    end

    it 'allows many interpolations' do
      s('"hi #{world} hola #{mundo}"').should ==
        [:chain, [:text, "hi "],
         [:oper, "++"], [:name, "world"],
         [:oper, "++"], [:text, " hola "],
         [:oper, "++"], [:name, "mundo"]]
    end

    it 'allows many interpolations from start' do
      s('"#{world} hola #{mundo} hi"').should ==
        [:chain, [:name, "world"],
         [:oper, "++"], [:text, " hola "],
         [:oper, "++"], [:name, "mundo"],
         [:oper, "++"], [:text, " hi"]]
    end

    it 'parses multi string' do
      s('"""hello "world" """').should ==
        [:text, "hello \"world\" "]
    end

    it 'parses simple string' do
      s("'foo \#{bar}'").should ==
        [:text, 'foo #{bar}']
    end
  end

end
