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
        ops << op if op && !(ary[idx+1] && ary[idx+1].name == :send)
      end
      ops
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
    alias_method :shuffle_oper, :nothing

    def shuffle_block(node)
      node.with(:block, *shuffle(node.args))
    end

    def shuffle_send(node)
      a = node.args
      node.with(:send, a[0], *shuffle(a[1..-1]))
    end

    def shuffle_msg(node)
      a = node.args.map { |n| n.with(n.name, n.args.first, *shuffle(n.args[1..-1])) }
      node.with(:msg, *a)
    end

    def shuffle_chain(node)
      chain = node.args
      ops = operators chain # sorted by position
      ord = ops.sort # sorted by precedence
      until ord.empty?
        op = ord.first
        chain = shuffle_op(op, chain, ops)
        ord.shift
        ops.delete op
      end
      chain = shuffle(chain)
      chain.size == 1 && chain.first || node.with(:chain, *chain)
    end

    def shuffle_op(op, chain, ops)
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
        elsif ops.first == op
          lhs, left = left, []
        else
          bwd = ops[ops.index(op) - 1]
          from = left.index(bwd.node) + 1
          lhs, left = left[from..-1], left[0...from]
        end
      end

      unless op.arity_r.zero?
        if op.arity_r < 0
          rhs, right = right, []
        elsif op.arity_r >= 1
          rhs = right.shift(op.arity_r)
        elsif ops.last == op
          rhs, right = right, []
        else
          fwd = ops[ops.index(op) + 1]
          to = right.index(fwd.node)
          rhs, right = right[0...to], right[to..-1]
        end
      end

      if lhs || rhs
        lhs = lhs.size == 1 && lhs.first || lhs.first.with(:chain, *lhs) if lhs
        rhs = rhs.size == 1 && rhs.first || rhs.first.with(:chain, *rhs) if rhs
        now = [op.node.with(:oper, *op.node.args), 
               op.node.with(:send, nil, *(Array(lhs) + Array(rhs)))]
      end

      Array(left) + Array(now) + Array(right)
    end

  end

end
