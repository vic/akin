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
      s('a : b', :cons).should == [:cons, [:ident, "a"], [:ident, "b"]]
    end
    
    it 'parses a cons of two values with no spaces in between' do
      s('a:b', :cons).should == [:cons, [:ident, "a"], [:ident, "b"]]
    end
    
    it 'parses a cons of two values with no space at right side' do
      s('a: b', :cons).should == [:cons, [:ident, "a"], [:ident, "b"]]
    end

    it 'parses a cons of three values' do
      s('a :b: c', :cons).should == [:cons, [:ident, "a"],
                                     [:cons, [:ident, "b"], [:ident, "c"]]]
    end
    
    it 'parses a cons of four values' do
      s('a :b: c : d', :cons).should == [:cons, [:ident, "a"],
                                         [:cons, [:ident, "b"],
                                          [:cons, [:ident, "c"],
                                           [:ident, "d"]]]]
    end
  end

  describe 'tuple' do
    it 'parses two values' do
      s('a, b', :tuple).should == [:tuple, [:ident, "a"], [:ident, "b"]]
    end
    it 'parses three values' do
      s('a, b, c', :tuple).should == [:tuple, [:ident, "a"],
                                              [:ident, "b"],
                                              [:ident, "c"]]
    end
  end

  describe 'args' do
    it 'parses empty args' do
      s('()', :args).should == ["()"]
    end
    it 'parses one arg' do
      s('(foo)', :args).should == ["()", [:ident, "foo"]]
    end
    it 'parses two args' do
      s('(foo, bar)', :args).should == ["()", [:ident, "foo"], [:ident, "bar"]]
    end
  end

  describe 'call' do
    it 'parses round' do
      s('foo()', :chain).should == [:chain, [:ident, "foo"], ["()"]]
    end
    it 'parses curly' do
      s('foo{}', :chain).should == [:chain, [:ident, "foo"], ["{}"]]
    end
    it 'parses square' do
      s('foo[]', :chain).should == [:chain, [:ident, "foo"], ["[]"]]
    end    
    it 'parses activation with arguments' do
      s('foo(bar)', :chain).should == [:chain, [:ident, "foo"],
                                          ["()", [:ident, "bar"]]]
    end    
  end

  describe 'chain' do
    it 'parses single value' do
      s('foo', :chain).should == [:ident, "foo"]
    end

    it 'parses two values' do
      s('foo bar', :chain).should == [:chain, [:ident, "foo"], [:ident, "bar"]]
    end    
  end

  describe 'message' do
    it 'parses one part' do
      s(':foo', :msg).should == [:msg, ["foo", "()"]]
    end

    it 'parses a part with args' do
      s(':foo(bar)', :msg).should == [:msg, ["foo", "()", [:ident, "bar"]]]
    end

    it 'parses a part with head' do
      s(':foo bar', :msg).should == [:msg, ["foo", "()", [:ident, "bar"]]]
    end

    it 'parses a part with head and commas' do
      s(':foo bar, baz', :msg).should == [:msg, ["foo", "()",
                                                 [:ident, "bar"],
                                                 [:ident, "baz"]]]
    end
    
    it 'parses a part with args and head' do
      s(':foo(bar) baz', :msg).should == [:msg, ["foo", "()",
                                                 [:ident, "bar"],
                                                 [:ident, "baz"]]]
    end

    it 'parses a part with args and head with commas' do
      s(':foo(bar) baz, bat', :msg).should == [:msg, ["foo", "()",
                                                      [:ident, "bar"],
                                                      [:ident, "baz"],
                                                      [:ident, "bat"]]]
    end

    it 'parses a two parts message' do
      s(':foo bar :baz bat', :msg).should ==
        [:msg, ["foo", "()", [:ident, "bar"]],
               ["baz", "()", [:ident, "bat"]]]
    end

    it 'parses an empty part and second path with head' do
      s(':foo :baz bat', :msg).should ==
        [:msg, ["foo", "()"],
               ["baz", "()", [:ident, "bat"]]]
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
               ["baz", "()", [:ident, "a"], [:ident, "b"]],
               ["bat", "()"]]
    end
    
    it 'parses second arg having commas' do
      s(':foo :baz a, b :bat c', :msg).should ==
        [:msg, ["foo", "()"],
               ["baz", "()",
                [:ident, "a"],
                [:ident, "b"]],
               ["bat", "()",
                [:ident, "c"]]]
    end

    it 'parses second arg having cons', :pending => true do
      s(':foo :baz a: b :bat c', :msg).should ==
        [:msg, ["foo", "()"],
               ["baz", "()",
                [:cons, [:ident, "a"],
                 [:ident, "b"]]],
               ["bat", "()",
                [:ident, "c"]]]
    end

    it 'allow head to have commas' do
      code = ":foo a,\n b"
      s(code, :msg).should ==
        [:msg, ["foo", "()",
               [:ident, "a"],
               [:ident, "b"]]]
    end
    
    it 'parses head on same line as a single argument' do
      code = ":foo a\n b"
      s(code, :msg).should ==
        [:msg, ["foo", "()",
               [:ident, "a"],
               [:ident, "b"]]]
    end
  end

  describe 'block' do
    it 'parses a single identifier as itself' do
      s('foo', :block).should ==
        [:ident, "foo"]
    end

    it 'parses a single chain as itself' do
      s('foo bar', :block).should ==
        [:chain, [:ident, "foo"], [:ident, "bar"]]
    end

    it 'parses a simple block of two identifiers' do
      s('foo;bar', :block).should ==
        [:block, [:ident, "foo"], [:ident, "bar"]]
    end

    it 'parses a single block of two chains' do
      s('foo bar; baz bat', :block).should ==
        [:block, [:chain, [:ident, "foo"], [:ident, "bar"]],
                 [:chain, [:ident, "baz"], [:ident, "bat"]]]
    end

    it 'parses a message but doesnt include non-nested identifier' do
      code = "d :foo a\nb"
      s(code, :block).should ==
        [:block, [:chain, [:ident, "d"], [:msg, ["foo", "()", [:ident, "a"]]]],
                 [:ident, "b"]]
    end

    it 'parses first message but doesnt include non-nested identifier' do
      code = ":foo a\nb"
      s(code, :block).should ==
        [:block, [:msg, ["foo", "()", [:ident, "a"]]],
                 [:ident, "b"]]
    end

    it 'parses two parts on same column as single message' do
      code = ":foo a\n:bar b"
      s(code, :block).should ==
        [:msg, ["foo", "()", [:ident, "a"]],
               ["bar", "()", [:ident, "b"]]]
    end    

    it 'parses two parts on same column as single message' do
      code = "m :foo a\n:bar b"
      s(code, :block).should ==
        [:chain, [:ident, "m"],
         [:msg, ["foo", "()", [:ident, "a"]],
          ["bar", "()", [:ident, "b"]]]]
    end

    it 'parses two parts on same column as single message until non-part' do
      code = "m :foo a\n:bar b\nbaz\n:bat c"
      s(code, :block).should ==
        [:block, [:chain, [:ident, "m"],
                  [:msg, ["foo", "()", [:ident, "a"]],
                   ["bar", "()", [:ident, "b"]]]],
         [:ident, "baz"],
         [:msg, ["bat", "()", [:ident, "c"]]]]
    end    
  end

  describe 'text' do
    it 'is parsed by literal rule' do
      s('"hi"', :literal).should ==
        [:text, "hi"]
    end

    it 'allows interpolation' do
      s('"hi #{world}"', :literal).should ==
        [:chain, [:text, "hi "],
         ["++", "()", [:ident, "world"]]]
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
        [:block, [:ident, "foo"],
                 [:ident, "bar"]]
    end

    it 'parses an object clone' do
      code = <<-CODE
      Point :x a :y b
      CODE
      s(code, :root).should ==
        [:chain, [:const, "Point"],
         [:msg, ["x", "()", [:ident, "a"]],
                ["y", "()", [:ident, "b"]]]]
    end

    it 'parses a pair of two identifiers' do
      code = <<-CODE
      foo: bar
      CODE
      s(code, :root).should ==
        [:cons, [:ident, "foo"], [:ident, "bar"]]
    end

    it 'parses an square message' do
      code = <<-CODE
      ["foo", bar]
      CODE
      s(code, :root).should ==
        ["[]", [:text, "foo"], [:ident, "bar"]]
    end

    it 'parses a json object' do
      code = <<-CODE
      {
       hello: "world",
       from: ['mars', moon]
      }
      CODE
      s(code, :root).should ==
        ["{}",
         [:cons, [:ident, "hello"], [:text, "world"]],
         [:cons, [:ident, "from"], ["[]", [:text, "mars"], [:ident, "moon"]]]
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
        [:chain, [:ident, "a"],
         [:msg, ["b", "()", [:ident, "c"], [:ident, "d"]],
          ["e", "()", [:ident, "f"],
           [:msg, ["g", "()", [:ident, "h"]]]]]]
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
        [:chain, [:ident, "a"],
         [:msg, ["b", "()", [:ident, "c"], [:ident, "d"]],
          ["e", "()", [:ident, "f"],
           [:msg, ["g", "()", [:ident, "h"]]]]]]
    end
  end
  
end


