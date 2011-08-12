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
  end
  
end


