require File.expand_path('../spec_helper', __FILE__)

describe 'Akin operator shuffling' do
  include_context 'grammar'

  describe 'name' do
    it 'should return same node' do
      n = c('hi')
      n.shuffle.should be(n)
    end
  end

end

