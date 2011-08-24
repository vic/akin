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
      n = c('a + b * c - d')
      n.shuffle.sexp.should ==
        [:chain,
         [:name, "a"],
         [:act, "+", nil,
          [:chain, [:name, "b"], [:act, "*", nil, [:name, "c"]]]],
         [:act, "-", nil, [:name, "d"]]]
    end
  end

  describe 'assignment' do
    it 'takes lhs and rhs' do
      n = c('a = b')
      n.shuffle.sexp.should ==
        [:act, "=", nil, [:name, "a"], [:name, "b"]]
    end

    it 'has higher precedence than +' do
      n = c('a = b + c')
      n.shuffle.sexp.should ==
        [:act, "=", nil,
         [:name, "a"],
         [:chain, [:name, "b"],
          [:act, "+", nil, [:name, "c"]]]]
    end

    it 'has higher precedence than both + and *' do
      n = c('a * d = b + c')
      n.shuffle.sexp.should ==
        [:act, "=", nil,
         [:chain, [:name, "a"],
          [:act, "*", nil, [:name, "d"]]],
         [:chain, [:name, "b"],
          [:act, "+", nil, [:name, "c"]]]]
    end
end

    

end

