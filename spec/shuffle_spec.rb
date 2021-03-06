# -*- coding: utf-8 -*-
require File.expand_path('../spec_helper', __FILE__)

describe 'Akin operator shuffle' do
  include_context 'grammar'

  describe 'basic math opers' do
    it 'associates correctly + and *' do
      n('a + b * c - d').should ==
        [:chain,
         [:name, "a"],
         [:cell, "+"],
         [:send, nil,
          [:chain, [:name, "b"], [:cell, "*"], [:send, nil, [:name, "c"]]]],
         [:cell, "-"],
         [:send, nil, [:name, "d"]]]
    end

    it 'should not shuffle already shuffled operators' do
      sexp = [:chain,
              [:name, "a"],
              [:cell, "+"],
              [:send, nil,
               [:chain, [:name, "b"], [:cell, "*"], [:send, nil, [:name, "c"]]]],
              [:cell, "-"],
              [:send, nil, [:name, "d"]]]
      n = c('a + b * c - d')
      s = shuffler.shuffle(n)
      s.sexp.should == sexp
      m = shuffler.shuffle(s)
      m.sexp.should == sexp
    end
  end



  describe 'assignment' do
    it 'takes lhs and rhs' do
      n('a = b').should ==
        [:chain, [:cell, "="],
         [:send, nil, [:name, "a"], [:name, "b"]]]
    end

    it 'has higher precedence than +' do
      [:chain, [:cell, "="],
       [:send, nil, [:name, "a"],
        [:chain, [:name, "b"], [:cell, "+"],
         [:send, nil, [:name, "c"]]]]]
    end

    it 'has higher precedence than both + and *' do
      n('a * d = b + c').should ==
        [:chain, [:cell, "="],
         [:send, nil,
          [:chain, [:name, "a"], [:cell, "*"], [:send, nil, [:name, "d"]]],
          [:chain, [:name, "b"], [:cell, "+"], [:send, nil, [:name, "c"]]]]]
    end

    it 'is right associative' do
      n('a = b = c').should ==
        [:chain, [:cell, "="],
         [:send, nil,
          [:name, "a"], [:chain, [:cell, "="],
                         [:send, nil, [:name, "b"], [:name, "c"]]]]]
    end

    it 'is parsed correctly with &&' do
      n('a && b = c').should ==
        [:chain, [:name, "a"],
         [:cell, "&&"],
         [:send, nil,
          [:chain, [:cell, "="], [:send, nil, [:name, "b"], [:name, "c"]]]]]
    end

    it 'is parsed correctly with and' do
      n('a and b = c').should ==
        [:chain, [:name, "a"],
         [:cell, "and"],
         [:send, nil,
          [:chain, [:cell, "="], [:send, nil, [:name, "b"], [:name, "c"]]]]]
    end

    it 'shuffles correctly with or' do
      n('a = b = c or d').should ==
        [:chain,
         [:cell, "="],
         [:send, nil, [:name, "a"],
          [:chain, [:cell, "="],
           [:send, nil, [:name, "b"], [:name, "c"]]]],
         [:cell, "or"], [:send, nil, [:name, "d"]]]
     end
  end

  describe 'unary negation' do
    it 'binds to right' do
      n('!b').should == [:chain, [:cell, "!"], [:send, nil, [:name, "b"]]]
    end

    it 'binds chain to right' do
      n('!b c d').should ==
        [:chain, [:cell, "!"], [:send, nil,
         [:chain, [:name, "b"], [:name, "c"], [:name, "d"]]]]
    end

    it 'binds chain to right till oper' do
      n('!b c + d').should ==
        [:chain,
         [:cell, "!"],
         [:send, nil, [:chain, [:name, "b"], [:name, "c"]]],
         [:cell, "+"],
         [:send, nil, [:name, "d"]]]
    end

    it 'binds chain to right till end' do
      n('b + ! c d').should ==
        [:chain, [:name, "b"], [:cell, "+"],
         [:send, nil, [:chain, [:cell, "!"],
                       [:send, nil, [:chain, [:name, "c"], [:name, "d"]]]]]]
    end

    it 'shuffles correctly with logical opers' do
      n('a = !c || b && d').should ==
        [:chain, [:cell, "="],
         [:send, nil,
          [:name, "a"],
          [:chain, [:cell, "!"],
           [:send, nil, [:name, "c"]]]],
         [:cell, "||"],
         [:send, nil,
          [:chain, [:name, "b"], [:cell, "&&"], [:send, nil, [:name, "d"]]]]]
    end
  end


  describe 'logical operator &&' do
    it 'associates correctly with logical opers' do
      n('a = b && c || d').should ==
        [:chain,
         [:cell, "="],
         [:send, nil, [:name, "a"], [:name, "b"]],
         [:cell, "&&"], [:send, nil, [:name, "c"]],
         [:cell, "||"], [:send, nil, [:name, "d"]]]
    end

    it 'can be chained' do
      n('a && b && c').should ==
        [:chain,
         [:name, "a"],
         [:cell, "&&"],
         [:send, nil, [:name, "b"]],
         [:cell, "&&"],
         [:send, nil, [:name, "c"]]]
    end
  end

  describe 'decrement operator --' do
    it 'binds left expression' do
      n('a --').should ==
        [:chain, [:cell, "--"], [:send, nil, [:name, "a"]]]
    end

    it 'doesnt takes right chain' do
      n('a -- b').should ==
        [:chain, [:cell, "--"], [:send, nil, [:name, "a"]], [:name, "b"]]
    end
  end

  describe '∈ operator' do
    it 'invers its lhs and rhs' do
      n('a ∈ b').should ==
        [:chain,
         [:name, "b"],
         [:cell, "∈"], [:send, nil, [:name, "a"]]]
    end

    it 'can be chained with other inverted operator and is right associative' do
      n('a ∈ b ∉ c').should ==
        [:chain,
         [:name, "c"],
         [:cell, "∉"],
         [:send, nil,
          [:chain, [:name, "b"],
           [:cell, "∈"],
           [:send, nil, [:name, "a"]]]]]
    end
  end

  describe '? operator' do
    it 'takes its left expr and rest of rhs including other operators' do
      n('a b ? c + d').should ==
        [:chain,
         [:name, "a"],
         [:cell, "?"],
         [:send, nil,
          [:name, "b"],
          [:chain, [:name, "c"], [:cell, "+"], [:send, nil, [:name, "d"]]]]]
    end
  end

  describe 'on message sends' do
    it 'shuffles chain inside activation' do
      n('a(b + c)').should ==
        [:chain,
         [:cell, "a"],
         [:send, ["(", ")"],
          [:chain, [:name, "b"], [:cell, "+"], [:send, nil, [:name, "c"]]]]]
    end

    it 'shuffles chain inside args' do
      n('(b + c)').should ==
        [:space,
         ["(", ")"],
         [:chain, [:name, "b"], [:cell, "+"], [:send, nil, [:name, "c"]]]]

    end
  end

  describe 'on keyword messages' do
    it 'shuffles chain inside args' do
      n('a(b + c):').should ==
        [:kmsg,
         [:part, "a", ["(", ")"],
          [:chain, [:name, "b"], [:cell, "+"], [:send, nil, [:name, "c"]]]]]
    end

    it 'shuffles chain inside keyword arg' do
      n('a: b + c').should ==
        [:kmsg,
         [:part, "a", nil,
          [:chain, [:name, "b"], [:cell, "+"], [:send, nil, [:name, "c"]]]]]
    end
  end

  describe 'named infix operator' do
    
    it 'shuffles chain with binary infix operator' do
      n('a #b# c').should ==
        [:chain, [:cell, "b"], [:send, nil, [:name, "a"], [:name, "c"]]]
    end

    it 'shuffles chain with left unary infix operator' do
      n('a #b c').should ==
        [:chain, [:cell, "b"], [:send, nil, [:name, "a"]], [:name, "c"]]
    end

    it 'shuffles chain with right unary infix operator' do
      n('a b# c').should ==
        [:chain, [:name, "a"], [:cell, "b"], [:send, nil, [:name, "c"]]]
    end
    
  end

end
