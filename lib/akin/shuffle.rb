# -*- coding: utf-8 -*-
module Akin
  
  class Shuffle

    def initialize(operators)
      @operators = operators
    end

    def operators(ary)
      ops = []
      ary.each_with_index do |node, idx|
        op = @operators.operator(node, idx)
        ops << op if op
      end
      ops.sort
    end

    def shuffle(node)
      if Array === node
        node.map { |n| shuffle(n) }
      else
        send "shuffle_#{node.name}", node
      end
    end

    def nothing(node)
      node
    end

    alias_method :shuffle_name, :nothing
    alias_method :shuffle_text, :nothing
    alias_method :shuffle_fixnum, :nothing
    alias_method :shuffle_float, :nothing

    def shuffle_block(node)
      node.with(:block, *shuffle(node.args))
    end

    def shuffle_oper(node)
      node.with(:name, *node.args)
    end

    def shuffle_act(node)
      a = node.args
      node.with(:act, a[0], a[1], *shuffle(a[2..-1]))
    end

    def shuffle_msg(node)
      a = node.args.map { |n| n.with(n.name, n.args.first, *shuffle(n.args[1..-1])) }
      node.with(:msg, *a)
    end

    def shuffle_chain(node)
      ops = operators node.args
      chain = node.args
      until ops.empty?
        chain = shuffle_op(ops.first, chain)
        ops.shift
      end
      chain = shuffle(chain)
      chain.size == 1 && chain.first || node.with(:chain, *chain)
    end

    def shuffle_op(op, chain)
      return chain if chain.empty? || chain == [op.node]
      return chain unless idx = chain.index(op.node)

      left, right = chain[0...idx], chain[idx+1..-1]
      left, right = right, left if op.inverted
      now, lhs, rhs = nil, nil, nil

      unless op.arity_l.zero?
        if op.arity_l < 0
          lhs, left = left, []
        elsif op.arity_l >= 1
          lhs = left.pop(op.arity_l)
        else
          left.reverse!
          lhs = left.take_while { |n| !@operators.operator?(n) }.reverse
          left = left[lhs.size..-1].reverse
        end
      end

      unless op.arity_r.zero?
        if op.arity_r < 0
          rhs, right = right, []
        elsif op.arity_r >= 1
          rhs = right.shift(op.arity_r)
        else
          rhs = right.take_while { |n| !@operators.operator?(n) }
          right = right[rhs.size..-1]
        end
      end

      if lhs || rhs
        now = op.node.with(:act, op.name, nil)
        if lhs
          lhs = lhs.size == 1 && lhs.first || lhs.first.with(:chain, *lhs)
          now.args.push lhs
        end
        if rhs
          rhs = rhs.size == 1 && rhs.first || rhs.first.with(:chain, *rhs)
          now.args.push rhs
        end
      end

      Array(left) + Array(now) + Array(right)
    end
    
  end

end
