# -*- coding: utf-8 -*-
module Akin
  
  class Shuffle
    
    class Operator < Struct.new(:name,
                                :precedence, :assoc,
                                :arity_l, :arity_r,
                                :node, :idx,
                                :inverted)

      def <=>(o)
        prec = precedence <=> o.precedence
        if prec.zero? && idx && assoc > 0
          o.idx <=> idx
        else
          prec
        end
      end
      
      def at(node, idx)
        self.class.new name, precedence, assoc, arity_l, arity_r, node, idx, inverted
      end

      def self.build(ary)
        ops = Hash.new
        ary.each_slice(2) do |n, p|
          ops[n] = Operator.new n, p.to_i, *DEFAULT[1..-1]
        end
        ops
      end      
    end

    # OPER    PRECED  ASOC    ARY_L  ARY_R
    DEFAULT = [10,     0,     0.0,     0.1]
    OPERATORS = Operator.build %w'
    !           0
    ?           0
    $           0
    ~           0
    #           0
    --          0
    ++          0
    **          1
    *           2
    /           2
    %           2
    +           3
    -           3
    ∩           3
    ∪           3
    <<          4
    >>          4
    <           5
    >           5
    <           5
    <=          5
    ≤           5
    >=          5
    ≥           5
    <>          5
    <>>         5
    <<>>        5
    ⊂           5
    ⊃           5
    ⊆           5
    ⊇           5
    ==          6
    !=          6
    ≠           6
    ===         6
    =~          6
    !~          6
    &           7
    ^           8
    |           9
    &&         10
    ?&         10
    ||         11
    ?|         11
    ..         12
    ...        12
    ∈          12
    ∉          12
    :::        12
    =>         12
    <->        12
    ->         12
    ∘          12
    +>         12
    !>         12
    &>         12
    %>         12
    #>         12
    @>         12
    />         12
    *>         12
    ?>         12
    |>         12
    ^>         12
    ~>         12
    ->>        12
    +>>        12
    !>>        12
    &>>        12
    %>>        12
    #>>        12
    @>>        12
    />>        12
    *>>        12
    ?>>        12
    |>>        12
    ^>>        12
    ~>>        12
    =>>        12
    **>        12
    **>>       12
    &&>        12
    &&>>       12
    ||>        12
    ||>>       12
    $>         12
    $>>        12
    +=         13
    -=         13
    **=        13
    *=         13
    /=         13
    %=         13
    and        13
    nand       13
    &=         13
    &&=        13
    ^=         13
    or         13
    xor        13
    nor        13
    |=         13
    ||=        13
    <<=        13
    >>=        13
    <-         14
    return     14
    ret        14
    use        14
    '
    PREFIX  = Operator.build %w'
    /           2
    *           2
    %           2
    +           3
    -           3
    $           6
    ~           6
    ?           6
    !           6
    =           6
    >           6
    <           6
    &           7
    ^           8
    |           9
    '

    %w[ * / % =  ].each { |i| PREFIX[i].assoc = 1 }
    %w[ * / % ** ].each { |i| OPERATORS[i].assoc = 1 }

    %w[ ++ -- ].each { |i| o = OPERATORS[i]; o.arity_l, o.arity_r = 1, 0 }

    %w[ = ].each { |i| o = PREFIX[i]; o.arity_l, o.arity_r = 0.1, 0.1 }
    %w[ ? ].each { |i| o = OPERATORS[i]; o.arity_l, o.arity_r = 1, -1 }
    %w[ $ ].each { |i| o = OPERATORS[i]; o.arity_l, o.arity_r = 0, -1 }

    %w[ ∈ ∉ ::: ].each { |i| o = OPERATORS[i]; o.inverted = o.assoc = 1 }

    def initialize(operators = OPERATORS)
      @operators = operators
    end

    def at(node, idx)
      if [:oper, :name].include?(node.name) && @operators.key?(node.args.first)
        @operators[node.args.first].at(node, idx)
      elsif :oper == node.name && PREFIX.key?(node.args.first[0,1])
        op = PREFIX[node.args.first[0,1]].at(node, idx)
        op.name = node.args.first
        op
      elsif :oper == node.name
        Operator.new(node.args.first, *DEFAULT).at(node, idx)
      end
    end

    def operators(ary)
      ops = []
      ary.each_with_index do |node, idx|
        op = at(node, idx)
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
          lhs = left.take_while { |n| at(n,0).nil? }.reverse
          left = left[lhs.size..-1].reverse
        end
      end

      unless op.arity_r.zero?
        if op.arity_r < 0
          rhs, right = right, []
        elsif op.arity_r >= 1
          rhs = right.shift(op.arity_r)
        else
          rhs = right.take_while { |n| at(n,0).nil? }
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
