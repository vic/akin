# -*- coding: utf-8 -*-

require File.expand_path('../spec_helper', __FILE__)

describe 'Akin grammar' do
  include_context 'grammar'
  
  describe 'keyword' do
    it 'matches operator' do
      c(':+', :keyword).should == "+"
    end

    it 'doesnt match double collon' do
      c('::', :keyword).should be_false
    end

    it 'doesnt match keyword ending in collon' do
      c(':foo:', :keyword).should be_false
    end

    it 'matches simple name' do
      c(':foo', :keyword).should == "foo"
    end
  end

  describe 'cons' do
    it 'parses a cons of two values' do
      s('a : b', :cons).should == [:cons, [:name, "a"], [:name, "b"]]
    end
    
    it 'parses a cons of two values with no spaces in between' do
      s('a:b', :cons).should == [:cons, [:name, "a"], [:name, "b"]]
    end
    
    it 'parses a cons of two values with no space at right side' do
      s('a: b', :cons).should == [:cons, [:name, "a"], [:name, "b"]]
    end

    it 'parses a cons of three values' do
      s('a :b: c', :cons).should == [:cons, [:name, "a"],
                                     [:cons, [:name, "b"], [:name, "c"]]]
    end
    
    it 'parses a cons of four values' do
      s('a :b: c : d', :cons).should == [:cons, [:name, "a"],
                                         [:cons, [:name, "b"],
                                          [:cons, [:name, "c"],
                                           [:name, "d"]]]]
    end
  end

  describe 'tuple' do
    it 'parses two values' do
      s('a, b', :tuple).should == [:tuple, [:name, "a"], [:name, "b"]]
    end
    
    it 'parses three values' do
      s('a, b, c', :tuple).should == [:tuple, [:name, "a"],
                                              [:name, "b"],
                                              [:name, "c"]]
    end
  end

  describe 'args' do
    it 'parses empty args' do
      s('()', :args).should == ["()"]
    end
    
    it 'parses one arg' do
      s('(foo)', :args).should == ["()", [:name, "foo"]]
    end
    
    it 'parses two args' do
      s('(foo, bar)', :args).should == ["()", [:name, "foo"], [:name, "bar"]]
    end
  end

  describe 'act' do
    it 'parses round' do
      s('foo()', :chain).should == [:act, [:name, "foo"], "()"]
    end
    
    it 'parses curly' do
      s('foo{}', :chain).should == [:act, [:name, "foo"], "{}"]
    end
    
    it 'parses square' do
      s('foo[]', :chain).should == [:act, [:name, "foo"], "[]"]
    end
    
    it 'parses activation with arguments' do
      s('foo(bar)', :chain).should == [:act, [:name, "foo"], "()", [:name, "bar"]]
    end
    
    it 'parses space act' do
      s('foo (bar)', :chain).should ==
        [:chain, [:name, "foo"],
         [:act, nil, "()", [:name, "bar"]]]
    end        

    it 'parses chained activation' do
      s('foo[]()', :chain).should ==
        [:act, [:act, [:name, "foo"], "[]"], "()"]
    end
  end

  describe 'message' do
    it 'parses one part' do
      s(':foo', :msg).should == [:msg, ["foo", "()"]]
    end

    it 'parses a part with args' do
      s(':foo(bar)', :msg).should == [:msg, ["foo", "()", [:name, "bar"]]]
    end

    it 'parses a part with head' do
      s(':foo bar', :msg).should == [:msg, ["foo", "()", [:name, "bar"]]]
    end

    it 'parses a part with head and commas' do
      s(':foo bar, baz', :msg).should == [:msg, ["foo", "()",
                                                 [:name, "bar"],
                                                 [:name, "baz"]]]
    end
    
    it 'parses a part with args and head' do
      s(':foo(bar) baz', :msg).should == [:msg, ["foo", "()",
                                                 [:name, "bar"],
                                                 [:name, "baz"]]]
    end

    it 'parses a part with args and head with commas' do
      s(':foo(bar) baz, bat', :msg).should == [:msg, ["foo", "()",
                                                      [:name, "bar"],
                                                      [:name, "baz"],
                                                      [:name, "bat"]]]
    end

    it 'parses a two parts message' do
      s(':foo bar :baz bat', :msg).should ==
        [:msg, ["foo", "()", [:name, "bar"]],
               ["baz", "()", [:name, "bat"]]]
    end

    it 'parses an empty part and second path with head' do
      s(':foo :baz bat', :msg).should ==
        [:msg, ["foo", "()"],
               ["baz", "()", [:name, "bat"]]]
    end
    
    it 'parses three empty parts' do
      s(':foo :baz :bat', :msg).should ==
        [:msg, ["foo", "()"],
               ["baz", "()"],
               ["bat", "()"]]
    end
        
    it 'parses three empty parts second having args' do
      s(':foo :baz(a, b) :bat', :msg).should ==
        [:msg, ["foo", "()"],
               ["baz", "()", [:name, "a"], [:name, "b"]],
               ["bat", "()"]]
    end
    
    it 'parses second arg having commas' do
      s(':foo :baz a, b :bat c', :msg).should ==
        [:msg, ["foo", "()"],
               ["baz", "()",
                [:name, "a"],
                [:name, "b"]],
               ["bat", "()",
                [:name, "c"]]]
    end

    it 'parses second arg having cons' do
      s(':foo :baz (a: b) :bat c', :msg).should ==
        [:msg, ["foo", "()"],
         ["baz", "()",
          [:act, nil, "()", [:cons, [:name, "a"], [:name, "b"]]]],
         ["bat", "()", [:name, "c"]]]
    end

    it 'allow head to have commas' do
      code = ":foo a,\n b"
      s(code, :msg).should ==
        [:msg, ["foo", "()",
               [:name, "a"],
               [:name, "b"]]]
    end
    
    it 'parses head on same line as a single argument' do
      code = ":foo a\n b"
      s(code, :msg).should ==
        [:msg, ["foo", "()",
               [:name, "a"],
               [:name, "b"]]]
    end
  end

  describe 'chain' do
    it 'parses single value' do
      s('foo', :chain).should == [:name, "foo"]
    end

    it 'parses two values' do
      s('foo bar', :chain).should == [:chain, [:name, "foo"], [:name, "bar"]]
    end

    it 'parses until dot is found' do
      code = ":foo ."
      s(code, :chain).should ==
        [:msg, ["foo", "()"]]
    end

    it 'parses binary op' do
      code = "a < b"
      s(code, :chain).should ==
        [:chain, [:name, "a"], [:oper, "<"], [:name, "b"]]
    end

    it 'parses binary op with args' do
      code = "a <(b, c)"
      s(code, :chain).should ==
        [:chain, [:name, "a"], [:act, [:oper, "<"], "()", [:name, "b"], [:name, "c"]]]
    end
  end

  describe 'block' do
    it 'parses a single identifier as itself' do
      s('foo', :block).should ==
        [:name, "foo"]
    end

    it 'parses a single chain as itself' do
      s('foo bar', :block).should ==
        [:chain, [:name, "foo"], [:name, "bar"]]
    end

    it 'parses a simple block of two identifiers' do
      s('foo;bar', :block).should ==
        [:block, [:name, "foo"], [:name, "bar"]]
    end

    it 'parses a single block of two chains' do
      s('foo bar; baz bat', :block).should ==
        [:block, [:chain, [:name, "foo"], [:name, "bar"]],
                 [:chain, [:name, "baz"], [:name, "bat"]]]
    end

    it 'parses a message but doesnt include non-nested identifier' do
      code = "d :foo a\nb"
      s(code, :block).should ==
        [:block, [:chain, [:name, "d"], [:msg, ["foo", "()", [:name, "a"]]]],
                 [:name, "b"]]
    end

    it 'parses first message but doesnt include non-nested identifier' do
      code = ":foo a\nb"
      s(code, :block).should ==
        [:block, [:msg, ["foo", "()", [:name, "a"]]],
                 [:name, "b"]]
    end

    it 'parses two parts on same column as single message' do
      code = ":foo a\n:bar b"
      s(code, :block).should ==
        [:msg, ["foo", "()", [:name, "a"]],
               ["bar", "()", [:name, "b"]]]
    end    

    it 'parses two parts on same column as single message' do
      code = "m :foo a\n:bar b"
      s(code, :block).should ==
        [:chain, [:name, "m"],
         [:msg, ["foo", "()", [:name, "a"]],
          ["bar", "()", [:name, "b"]]]]
    end

    it 'parses two parts on same column as single message until non-part' do
      code = "m :foo a\n:bar b\nbaz\n:bat c"
      s(code, :block).should ==
        [:block, [:chain, [:name, "m"],
                  [:msg, ["foo", "()", [:name, "a"]],
                   ["bar", "()", [:name, "b"]]]],
         [:name, "baz"],
         [:msg, ["bat", "()", [:name, "c"]]]]
    end

    it 'parses message until semicolon-dot is found' do
      code = "a :b c :. d"
      s(code, :block).should ==
        [:chain, [:name, "a"],
         [:msg, ["b", "()", [:name, "c"]]],
         [:name, "d"]]
    end

    it 'parses message until semicolon-colon is found' do
      code = "a :b c :; d"
      s(code, :block).should ==
        [:block, 
         [:chain, [:name, "a"],
          [:msg, ["b", "()", [:name, "c"]]]],
         [:name, "d"]]
    end

    it 'parses message until semicolon-semicolon is found' do
      code = "a :b c :: d"
      s(code, :root).should ==
        [:chain, [:name, "a"],
         [:cons, [:msg, ["b", "()", [:name, "c"]]], [:name, "d"]]]
    end        
  end

  describe 'text' do
    it 'is parsed by literal rule' do
      s('"hi"', :literal).should ==
        [:text, "hi"]
    end

    it 'allows interpolation' do
      s('"hi #{world}"', :literal).should ==
        [:chain, [:text, "hi "], [:oper, "++"], [:name, "world"]]
    end

    it 'parses only interpolation as to_s message' do
      s('"#{world}"', :literal).should ==
        [:chain, [:name, "world"], [:name, "to_s"]]
    end

    it 'allows many interpolations' do
      s('"hi #{world} hola #{mundo}"', :literal).should ==
        [:chain, [:text, "hi "],
         [:oper, "++"], [:name, "world"],
         [:oper, "++"], [:text, " hola "],
         [:oper, "++"], [:name, "mundo"]]
    end
    
    it 'allows many interpolations from start' do
      s('"#{world} hola #{mundo} hi"', :literal).should ==
        [:chain, [:name, "world"],
         [:oper, "++"], [:text, " hola "],
         [:oper, "++"], [:name, "mundo"],
         [:oper, "++"], [:text, " hi"]]
    end

    it 'parses multi string' do
      s('"""hello "world" """', :literal).should ==
        [:text, "hello \"world\" "]
    end

    it 'parses simple string' do
      s("'foo \#{bar}'", :literal).should ==
        [:text, 'foo #{bar}']
    end
  end

  describe 'root' do
    it 'ignores sheebangs' do
      code = "#!/usr/bin/akin"
      s(code, :root).should be_nil
    end

    it 'does not include sheebang on block' do
      code = <<-CODE
      #!/usr/bin/akin
      foo
      bar
      CODE
      s(code, :root).should ==
        [:block, [:name, "foo"],
                 [:name, "bar"]]
    end

    it 'parses an object clone' do
      code = <<-CODE
      Point :x a :y b
      CODE
      s(code, :root).should ==
        [:chain, [:name, "Point"],
         [:msg, ["x", "()", [:name, "a"]],
                ["y", "()", [:name, "b"]]]]
    end

    it 'parses a pair of two identifiers' do
      code = <<-CODE
      foo: bar
      CODE
      s(code, :root).should ==
        [:cons, [:name, "foo"], [:name, "bar"]]
    end

    it 'parses an square message' do
      code = <<-CODE
      ["foo", bar]
      CODE
      s(code, :root).should ==
        [:act, nil, "[]", [:text, "foo"], [:name, "bar"]]
    end

    it 'parses a json object' do
      code = <<-CODE
      {
       hello: "world",
       from: ['mars', moon]
      }
      CODE
      s(code, :root).should ==
        [:act, nil, "{}",
         [:cons, [:name, "hello"], [:text, "world"]],
         [:cons, [:name, "from"],
          [:act, nil, "[]", [:text, "mars"], [:name, "moon"]]]
        ]
    end

    it 'parses nested blocks' do
      code = <<-CODE
      a :b c
        d
      :e f
        :g
          h
      CODE
      s(code, :root).should ==
        [:chain, [:name, "a"],
         [:msg, ["b", "()", [:name, "c"], [:name, "d"]],
          ["e", "()", [:name, "f"],
           [:msg, ["g", "()", [:name, "h"]]]]]]
    end
    
    it 'parses nested blocks until semicolon' do
      code = <<-CODE
      a :b u
      :c e
      ;
      :d
      CODE
      s(code, :root).should ==
        [:block, [:chain, [:name, "a"],
                  [:msg, ["b", "()", [:name, "u"]], ["c", "()", [:name, "e"]]]],
         [:msg, ["d", "()"]]]

    end
    
    it 'parses messages with args' do
      code = <<-CODE
      a :b(
        c, d
      ):e(f,
        :g
          h
      )
      CODE
      s(code, :root).should ==
        [:chain, [:name, "a"],
         [:msg, ["b", "()", [:name, "c"], [:name, "d"]],
          ["e", "()", [:name, "f"],
           [:msg, ["g", "()", [:name, "h"]]]]]]
    end

    it 'parses message with opchars' do
      code = "a :< b :> c"
      s(code, :root).should ==
        [:chain, [:name, "a"],
         [:msg, ["<", "()", [:name, "b"]],
                [">", "()", [:name, "c"]]]]
    end

    it 'parses a chain of unicode names' do
      code = "मूल नकल"
      s(code, :root).should ==
        [:chain, [:name, "मूल"], [:name, "नकल"]]
    end

    it 'allows operators chaining' do
      code = <<-CODE
      a + b - c
      CODE
      s(code, :root).should ==
        [:chain,
         [:name, "a"],
         [:oper, "+"], [:name, "b"],
         [:oper, "-"], [:name, "c"]]
    end
  end

  describe 'nested args' do
    it 'for operators can be continued on next line' do
      code = <<-CODE
      a +
        b -
          c
      CODE
      s(code, :root).should ==
        [:chain,
         [:name, "a"],
         [:oper, "+"], [:name, "b"],
         [:oper, "-"], [:name, "c"]]
    end

    it 'can be indicated on next line' do
      code = <<-CODE
      a foo
        bar
      CODE
      s(code, :root).should ==
        [:chain,
         [:name, "a"],
         [:act, [:name, "foo"], "()", [:name, "bar"]]]
    end

    it 'are not parsed if found dot terminator' do
      code = <<-CODE
      a foo .
        bar
      CODE
      s(code, :root).should ==
        [:chain,
         [:name, "a"],
         [:name, "foo"],
         [:name, "bar"]]
    end
    
    it 'are not parsed if found semicolon terminator' do
      code = <<-CODE
      a foo ;
        bar
      CODE
      s(code, :root).should ==
        [:block,
         [:chain, [:name, "a"], [:name, "foo"]],
         [:name, "bar"]]
    end

    it 'appends nested block to activation args' do
      code = <<-CODE
      a foo(baz)
        bar
      CODE
      s(code, :root).should ==
        [:chain,
         [:name, "a"],
         [:act, [:name, "foo"], "()", [:name, "baz"], [:name, "bar"]]]
    end

    it 'takes last tuple as arguments' do
      code = <<-CODE
      a foo bar, baz
      CODE
      s(code, :root).should ==
        [:chain,
         [:name, "a"],
         [:act, [:name, "foo"], "()", [:name, "bar"], [:name, "baz"]]]
    end


    it 'takes last one-tuple-ending-with-dot as argument' do
      code = <<-CODE
      a foo bar ,.
      CODE
      s(code, :root).should ==
        [:chain,
         [:name, "a"],
         [:act, [:name, "foo"], "()", [:name, "bar"]]]
    end

    it 'allows args to have many lines' do
      code = <<-CODE
      a foo bar,
        baz
      CODE
      s(code, :root).should ==
        [:chain,
         [:name, "a"],
         [:act, [:name, "foo"], "()", [:name, "bar"], [:name, "baz"]]]
    end

    it 'allows args to have many lines ignoring white space between comma' do
      code = <<-CODE
      a foo bar
      ,
        baz
      CODE
      s(code, :root).should ==
        [:chain,
         [:name, "a"],
         [:act, [:name, "foo"], "()", [:name, "bar"], [:name, "baz"]]]
    end

    it 'allows nested block with curly act' do
      code = <<-CODE
      a foo{} bar,
        baz,
        bat
      CODE
      s(code, :root).should ==
        [:chain,
         [:name, "a"],
         [:act, [:name, "foo"], "{}", [:name, "bar"], [:name, "baz"], [:name, "bat"]]]
    end
  end
end
