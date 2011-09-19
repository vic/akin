# -*- coding: utf-8 -*-
require File.expand_path('../spec_helper', __FILE__)

describe 'Akin operator shuffle' do
  include_context 'grammar'

  describe 'basic math opers' do
    it 'associates correctly + and *' do
      n('a + b * c - d').should ==
        [:chain,
         [:chain, [:name, "a"], [:oper, "+"],
          [:send, nil, 
           [:chain, [:name, "b"], [:oper, "*"], [:send, nil, [:name, "c"]]]]],
         [:oper, "-"],
         [:send, nil, [:name, "d"]]]
    end
  end


=begin
  describe 'assignment' do
    it 'takes lhs and rhs' do
      n('a = b').should ==
        [:act, "=", nil, [:name, "a"], [:name, "b"]]
    end

    it 'has higher precedence than +' do
      n('a = b + c').should ==
        [:act, "=", nil,
         [:name, "a"],
         [:chain, [:name, "b"],
          [:act, "+", nil, [:name, "c"]]]]
    end

    it 'has higher precedence than both + and *' do
      n('a * d = b + c').should ==
        [:act, "=", nil,
         [:chain, [:name, "a"],
          [:act, "*", nil, [:name, "d"]]],
         [:chain, [:name, "b"],
          [:act, "+", nil, [:name, "c"]]]]
    end

    it 'is right associative' do
      n('a = b = c').should ==
        [:act, "=", nil, [:name, "a"], [:act, "=", nil, [:name, "b"], [:name, "c"]]]
    end

    it 'is parsed correctly with &&' do
      n('a && b = c').should ==
        [:chain, [:name, "a"],
         [:act, "&&", nil, [:act, "=", nil, [:name, "b"], [:name, "c"]]]]
    end

    it 'is parsed correctly with and' do
      n('a and b = c').should ==
        [:chain, [:name, "a"],
         [:act, "and", nil, [:act, "=", nil, [:name, "b"], [:name, "c"]]]]
    end

    it 'shuffles correctly with or' do
      n('a = b = c or d').should ==
        [:chain, [:act, "=", nil,
                  [:name, "a"],
                  [:act, "=", nil, [:name, "b"], [:name, "c"]]],
         [:act, "or", nil, [:name, "d"]]]
    end
  end

  describe 'unary negation' do
    it 'binds to right' do
      n('!b').should ==
        [:act, "!", nil, [:name, "b"]]
    end

    it 'binds chain to right' do
      n('!b c d').should ==
        [:act, "!", nil,
         [:chain, [:name, "b"], [:name, "c"], [:name, "d"]]]
    end

    it 'binds chain to right till oper' do
      n('!b c + d').should ==
        [:chain,
         [:act, "!", nil, [:chain, [:name, "b"], [:name, "c"]]],
         [:act, "+", nil, [:name, "d"]]]
    end

    it 'binds chain to right till end' do
      n('b + ! c d').should ==
        [:chain,
         [:name, "b"],
         [:act, "+", nil,
           [:act, "!", nil,
            [:chain, [:name, "c"], [:name, "d"]]]]]
    end

    it 'shuffles correctly with logical opers' do
      n('a = !c || b && d').should ==
        [:chain,

         [:act, "=", nil,
          [:name, "a"],
          [:act, "!", nil, [:name, "c"]]],

         [:act, "||", nil,
          [:chain, [:name, "b"],
           [:act, "&&", nil, [:name, "d"]]]]]
    end
  end

  describe 'logical operator &&' do
    it 'associates correctly with logical opers' do
      n('a = b && c || d').should ==
        [:chain,
         [:act, "=", nil,
          [:name, "a"],
          [:name, "b"]],
         [:act, "&&", nil, [:name, "c"]],
         [:act, "||", nil, [:name, "d"]]]
    end

    it 'can be chained' do
      n('a && b && c').should ==
        [:chain, [:name, "a"],
         [:act, "&&", nil, [:name, "b"]], [:act, "&&", nil, [:name, "c"]]]
    end
  end

  describe 'decrement operator --' do
    it 'binds left expression' do
      n('a --').should ==
        [:act, "--", nil, [:name, "a"]]
    end

    it 'doesnt takes right chain' do
      n('a -- b').should ==
        [:chain, [:act, "--", nil, [:name, "a"]], [:name, "b"]]
    end
  end

  describe '∈ operator' do
    it 'invers its lhs and rhs' do
      n('a ∈ b').should ==
        [:chain,
         [:name, "b"],
         [:act, "∈", nil, [:name, "a"]]]
    end

    it 'can be chained with other inverted operator and is right associative' do
      n('a ∈ b ∉ c').should ==
        [:chain,
         [:name, "b"],
         [:act, "∈", nil,
          [:chain,
           [:name, "c"],
           [:act, "∉", nil, [:name, "a"]]]]]
    end
  end

  describe '? operator' do
    it 'takes its left expr and rest of rhs including other operators' do
      n('a b ? c + d').should ==
        [:chain,
         [:name, "a"],
         [:act, "?", nil, [:name, "b"],
          [:chain,
           [:name, "c"],
           [:act, "+", nil, [:name, "d"]]]]]
    end
  end

  describe 'on message sends' do
    it 'shuffles chain inside activation' do
      n('a(b + c)').should ==
        [:act, [:name, "a"], "()",
         [:chain, [:name, "b"],
          [:act, "+", nil, [:name, "c"]]]]
    end

    it 'shuffles chain inside args' do
      n('(b + c)').should ==
        [:act, nil, "()",
         [:chain, [:name, "b"],
          [:act, "+", nil, [:name, "c"]]]]
    end
  end

  describe 'on keyword messages' do
    it 'shuffles chain inside args' do
      n('a(b + c):').should ==
        [:msg, ["a", "()",
                [:chain, [:name, "b"],
                 [:act, "+", nil, [:name, "c"]]]]]
    end

    it 'shuffles chain inside keyword arg' do
      n('a: b + c').should ==
        [:msg, ["a", nil,
                [:chain, [:name, "b"],
                 [:act, "+", nil, [:name, "c"]]]]]
    end
  end
=end
end
