module Akin
  module Shuffle
    extend self

    def shuffle(node)
      send "shuffle_#{node.name}", node
    end

    def nothing(node)
      node
    end

    alias_method :shuffle_name, :nothing
    alias_method :shuffle_text, :nothing
    alias_method :shuffle_fixnum, :nothing
    alias_method :shuffle_float, :nothing

    def shuffle_chain(node)
      ops = opers(node.args)
      return node if ops.empty?
      ary = node.args
      until ops.empty?
        ary = ops.first.shuffle(ary)
        ops.shift
      end
      if ary.length == 1
        ary.first
      else
        node.with(:chain, *ary)
      end
    end

    def opers(ary)
      ops = []
      ary.each_with_index do |node, idx|
        if node.name == :oper
          ops.push Oper.new(idx, node, info(node.args.first))
        end
      end
      ops.sort
    end


    class Oper
      include Comparable
      
      attr_reader :idx, :node, :info
      def initialize(idx, node, info)
        @idx, @node, @info = idx, node, info
      end

      def lhs?
        info.assoc <= 0
      end

      def rhs?
        info.assoc >= 0
      end

      def <=>(other)
        o = info <=> other.info
        if o.zero?
          idx <=> other.idx
        else
          o
        end
      end

      def oper
        node.args.first
      end

      def shuffle(ary)
        act = node.with(:act, oper, nil)
        lhs, rhs = nil, nil
        pre, post = ary[0...ary.index(node)], ary[ary.index(node)+1..-1]
        if lhs? && pre
          lhs = pre.reverse.take_while { |i| i.name != :oper }.reverse
          unless lhs.empty?
            pre = ary[0...ary.index(lhs.first)]
            if lhs.size == 1
              act.args.push lhs.first
            else
              act.args.push lhs.first.with(:chain, *lhs)
            end
          end
        end
        if rhs? && post
          rhs = post.take_while { |i| i.name != :oper }
          unless rhs.empty?
            post = ary[ary.index(rhs.last)+1..-1]
            if rhs.size == 1
              act.args.push rhs.first
            else
              act.args.push rhs.first.with(:chain, *rhs)
            end
          end
        end
        Array(pre) + Array(act) + Array(post)
      end

      class Info
        attr_reader :prec, :assoc
        
        def initialize(prec = 5, assoc = 1)
          @prec, @assoc = prec, assoc
        end

        def <=>(other)
          if prec == other.prec
            assoc <=> other.assoc
          else
            prec <=> other.prec
          end
        end
      end
    end

    OPERATORS = {
      "*" => Oper::Info.new(5),
      "+" => Oper::Info.new(6),
      "-" => Oper::Info.new(6),
      "=" => Oper::Info.new(16, 0)
    }

    def info(op)
      OPERATORS[op] || Oper::Info.new
    end

  end
end
