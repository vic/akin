# -*- coding: utf-8 -*-
module Akin
  class Operator < Struct.new(:name,
                              :precedence, :assoc,
                              :arity_l, :arity_r,
                              :node, :idx,
                              :inverted)

    def <=>(o)
      prec = precedence <=> o.precedence
      if prec.zero? && idx
        if assoc > 0 # right associative
          o.idx <=> idx
        else # left associative
          idx <=> o.idx
        end
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

    class Table
      def initialize(operators = OPERATORS, prefix = PREFIX, default = DEFAULT)
        @operators, @prefix, @default = operators, prefix, default
      end

      def operator?(node)
        !operator(node,0).nil?
      end

      def operator(node, idx)
        if [:oper, :name].include?(node.name) && @operators.key?(node.args.first)
          @operators[node.args.first].at(node, idx)
        elsif :oper == node.name && @prefix.key?(node.args.first[0,1])
          op = @prefix[node.args.first[0,1]].at(node, idx)
          op.name = node.args.first
          op
        elsif :oper == node.name
          Operator.new(node.args.first, *@default).at(node, idx)
        end
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

  end
end
