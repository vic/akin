require File.expand_path('../spec_helper', __FILE__)

describe 'Akin operator shuffling' do
  include_context 'grammar'

  describe 'name' do
    it 'should return same node' do
      n = c('hi')
      n.shuffle.should be(n)
    end
  end
  
  describe 'basic math opers' do
    it 'associates correctly + and *' do
      n('a + b * c - d').should ==
        [:chain,
         [:name, "a"],
         [:act, "+", nil,
          [:chain, [:name, "b"], [:act, "*", nil, [:name, "c"]]]],
         [:act, "-", nil, [:name, "d"]]]
    end
  end

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
  end

  describe 'unary negation' do
    it 'binds to right' do
      n('!b').should ==
        [:chain, [:name, "b"], [:act, "!", nil]]
    end
    
    it 'binds chain to right' do
      n('!b c d').should ==
        [:chain,
         [:name, "b"], [:name, "c"], [:name, "d"],
         [:act, "!", nil]]
    end

    it 'binds chain to right till oper' do
      n('!b c + d').should ==
        [:chain,
         [:name, "b"], [:name, "c"],
         [:act, "!", nil],
         [:act, "+", nil, [:name, "d"]]]
    end    

    it 'binds chain to right till oper' do
      n('b + ! c d').should ==
        [:chain,
         [:name, "b"], 
         [:act, "+", nil,
          [:chain, [:name, "c"], [:name, "d"], [:act, "!", nil]]]]
    end    
  end

end

