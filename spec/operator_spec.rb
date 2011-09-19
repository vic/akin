# -*- coding: utf-8 -*-
require File.expand_path('../spec_helper', __FILE__)

describe Akin::Shuffle do
  include_context 'grammar'

  subject { Akin::Shuffle.new(Akin::Operator::Table.new) }

  describe '#operators returns an ary' do
    it 'non empty if found operators in chain' do
      subject.operators(c('+ * -').args).should_not be_empty
    end

    it 'including only operators' do
      subject.operators(c('+ b * c -').args).size.should == 3
    end

    it 'with operators sorted by precedence' do
      subject.operators(c('+ *').args).map(&:name).should == ["*", "+"]
    end

    it 'with +,- operators sorted by fixity' do
      subject.operators(c('+ - +').args).map(&:name).should == ["+", "-", "+"]
    end

    it 'with +,-,* operators sorted by fixity' do
      subject.operators(c('+ - * +').args).map(&:name).should == ["*", "+", "-", "+"]
    end

    it 'with +,-,*,/ operators sorted by fixity' do
      subject.operators(c('+ - * + /').args).map(&:name).should ==
        ["/", "*", "+", "-", "+"]
    end

    it 'detects and as an operator' do
      subject.operators(c('you and me').args).size.should == 1
    end

    it 'detects ∈ as an operator' do
      subject.operators(c('a ∈ b').args).size.should == 1
    end
  end
end

