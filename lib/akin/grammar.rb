class Akin::Grammar
# STANDALONE START
    def setup_parser(str, debug=false)
      @string = str
      @pos = 0
      @memoizations = Hash.new { |h,k| h[k] = {} }
      @refargs = Array.new
      @result = nil
      @failed_rule = nil
      @failing_rule_offset = -1

      setup_foreign_grammar
    end

    # This is distinct from setup_parser so that a standalone parser
    # can redefine #initialize and still have access to the proper
    # parser setup code.
    #
    def initialize(str, debug=false)
      setup_parser(str, debug)
    end

    attr_reader :string
    attr_reader :failing_rule_offset
    attr_accessor :result, :pos

    # STANDALONE START
    def current_column(target=pos)
      return unless string[target - 1]
      o = string[target,1] == "\n" && 1 || 0
      if target - 1 > 0 && c = string.rindex("\n", target - 1)
        target - c - o
      else
        target + 1
      end
    end

    def current_line(target=pos)
      return unless string[target - 1]
      cur_offset = 0
      cur_line = 0

      string.each_line do |line|
        cur_line += 1
        cur_offset += line.size
        return cur_line if cur_offset > target
      end

      cur_line + 1
    end

    def lines
      lines = []
      string.each_line { |l| lines << l }
      lines
    end

    #

    def get_text(start)
      @string[start..@pos-1]
    end

    def show_pos
      width = 10
      if @pos < width
        "#{@pos} (\"#{@string[0,@pos]}\" @ \"#{@string[@pos,width]}\")"
      else
        "#{@pos} (\"... #{@string[@pos - width, width]}\" @ \"#{@string[@pos,width]}\")"
      end
    end

    def failure_info
      l = current_line @failing_rule_offset
      c = current_column @failing_rule_offset

      if @failed_rule.kind_of? Symbol
        info = self.class::Rules[@failed_rule]
        "line #{l}, column #{c}: failed rule '#{info.name}' = '#{info.rendered}'"
      else
        "line #{l}, column #{c}: failed rule '#{@failed_rule}'"
      end
    end

    def failure_caret
      l = current_line @failing_rule_offset
      c = current_column @failing_rule_offset

      line = lines[l-1]
      "#{line}\n#{' ' * (c - 1)}^"
    end

    def failure_character
      l = current_line @failing_rule_offset
      c = current_column @failing_rule_offset
      lines[l-1][c-1, 1]
    end

    def failure_oneline
      l = current_line @failing_rule_offset
      c = current_column @failing_rule_offset

      char = lines[l-1][c-1, 1]

      if @failed_rule.kind_of? Symbol
        info = self.class::Rules[@failed_rule]
        "@#{l}:#{c} failed rule '#{info.name}', got '#{char}'"
      else
        "@#{l}:#{c} failed rule '#{@failed_rule}', got '#{char}'"
      end
    end

    class ParseError < RuntimeError
    end

    def raise_error
      raise ParseError, failure_oneline
    end

    def show_error(io=STDOUT)
      error_pos = @failing_rule_offset
      line_no = current_line(error_pos)
      col_no = current_column(error_pos)

      io.puts "On line #{line_no}, column #{col_no}:"

      if @failed_rule.kind_of? Symbol
        info = self.class::Rules[@failed_rule]
        io.puts "Failed to match '#{info.rendered}' (rule '#{info.name}')"
      else
        io.puts "Failed to match rule '#{@failed_rule}'"
      end

      io.puts "Got: #{string[error_pos,1].inspect}"
      line = lines[line_no-1]
      io.puts "=> #{line}"
      io.print(" " * (col_no + 3))
      io.puts "^"
    end

    def set_failed_rule(name)
      if @pos > @failing_rule_offset
        @failed_rule = name
        @failing_rule_offset = @pos
      end
    end

    attr_reader :failed_rule

    def match_string(str)
      len = str.size
      if @string[pos,len] == str
        @pos += len
        return str
      end

      return nil
    end

    def scan(reg)
      if m = reg.match(@string[@pos..-1])
        width = m.end(0)
        @pos += width
        return true
      end

      return nil
    end

    if "".respond_to? :getbyte
      def get_byte
        if @pos >= @string.size
          return nil
        end

        s = @string.getbyte @pos
        @pos += 1
        s
      end
    else
      def get_byte
        if @pos >= @string.size
          return nil
        end

        s = @string[@pos]
        @pos += 1
        s
      end
    end

    def parse(rule=nil)
      if !rule
        _root ? true : false
      else
        # This is not shared with code_generator.rb so this can be standalone
        method = rule.gsub("-","_hyphen_")
        __send__("_#{method}") ? true : false
      end
    end

    class LeftRecursive
      def initialize(detected=false)
        @detected = detected
      end

      attr_accessor :detected
    end

    class MemoEntry
      def initialize(ans, pos)
        @ans = ans
        @pos = pos
        @uses = 1
        @result = nil
      end

      attr_reader :ans, :pos, :uses, :result

      def inc!
        @uses += 1
      end

      def move!(ans, pos, result)
        @ans = ans
        @pos = pos
        @result = result
      end
    end

    def external_invoke(other, rule, *args)
      old_pos = @pos
      old_string = @string

      @pos = other.pos
      @string = other.string

      begin
        if val = __send__(rule, *args)
          other.pos = @pos
          other.result = @result
        else
          other.set_failed_rule "#{self.class}##{rule}"
        end
        val
      ensure
        @pos = old_pos
        @string = old_string
      end
    end

    def apply_with_args(rule, *args)
      memo_key = [rule, args]
      if m = @memoizations[memo_key][@pos]
        m.inc!

        prev = @pos
        @pos = m.pos
        if m.ans.kind_of? LeftRecursive
          m.ans.detected = true
          return nil
        end

        @result = m.result

        return m.ans
      else
        lr = LeftRecursive.new(false)
        m = MemoEntry.new(lr, @pos)
        @memoizations[memo_key][@pos] = m
        start_pos = @pos

        ans = __send__ rule, *args

        m.move! ans, @pos, @result

        # Don't bother trying to grow the left recursion
        # if it's failing straight away (thus there is no seed)
        if ans and lr.detected
          return grow_lr(rule, args, start_pos, m)
        else
          return ans
        end

        return ans
      end
    end

    def apply(rule)
      if m = @memoizations[rule][@pos]
        m.inc!

        prev = @pos
        @pos = m.pos
        if m.ans.kind_of? LeftRecursive
          m.ans.detected = true
          return nil
        end

        @result = m.result

        return m.ans
      else
        lr = LeftRecursive.new(false)
        m = MemoEntry.new(lr, @pos)
        @memoizations[rule][@pos] = m
        start_pos = @pos

        ans = __send__ rule

        m.move! ans, @pos, @result

        # Don't bother trying to grow the left recursion
        # if it's failing straight away (thus there is no seed)
        if ans and lr.detected
          return grow_lr(rule, nil, start_pos, m)
        else
          return ans
        end

        return ans
      end
    end

    def grow_lr(rule, args, start_pos, m)
      while true
        @pos = start_pos
        @result = m.result

        if args
          ans = __send__ rule, *args
        else
          ans = __send__ rule
        end
        return nil unless ans

        break if @pos <= m.pos

        m.move! ans, @pos, @result
      end

      @result = m.result
      @pos = m.pos
      return m.ans
    end

    class RuleInfo
      def initialize(name, rendered)
        @name = name
        @rendered = rendered
      end

      attr_reader :name, :rendered
    end

    def self.rule_info(name, rendered)
      RuleInfo.new(name, rendered)
    end

    #


    BRACES_ALIST = [
                    ['(', ')'],
                    ['{', '}'],
                    ['[', ']'],
                    ['\(', '\)'],
                    ['\{', '\}'],
                    ['\[', '\]']
                   ]
    
    def braces
      @braces ||= BRACES_ALIST.dup
    end
    
    def brace(text)
      braces.assoc(text) || braces.rassoc(text)
    end
    
    def node(*a, &b)
      Node.new(*a, &b)
    end

    alias_method :n, :node

    def current_position(o = pos)
      Position.new(current_line(o), current_column(o))
    end

    def h
      Position.new(0, 0)
    end 
    

    class Position
      attr_accessor :line, :column
      def initialize(line = nil, column = nil)
        @line, @column = line, column
      end
      def |(other)
        if @line.nil? || @line.zero?
          other
        else
          self
        end
      end
    end

    class Node
      def initialize(position = Position.new, name = nil, *args)
        @pos, @name, @args = position, name, args
      end

      attr_reader :pos, :name, :args

      def first
        @args.first
      end

      def last
        @args.last
      end

      def [](idx)
        @args[idx]
      end

      def sexp
        sexp = []
        sexp << name if name
        sexp.push *args.map { |a| a.respond_to?(:sexp) && a.sexp || a }
        sexp
      end
    end    



  def setup_foreign_grammar; end

  # nl = ("\n" | "\n")
  def _nl

    _save = self.pos
    while true # choice
      _tmp = match_string("\n")
      break if _tmp
      self.pos = _save
      _tmp = match_string("\r\n")
      break if _tmp
      self.pos = _save
      break
    end # end choice

    set_failed_rule :_nl unless _tmp
    return _tmp
  end

  # sp = (" " | "\t" | "\\" nl)
  def _sp

    _save = self.pos
    while true # choice
      _tmp = match_string(" ")
      break if _tmp
      self.pos = _save
      _tmp = match_string("\t")
      break if _tmp
      self.pos = _save

      _save1 = self.pos
      while true # sequence
        _tmp = match_string("\\")
        unless _tmp
          self.pos = _save1
          break
        end
        _tmp = apply(:_nl)
        unless _tmp
          self.pos = _save1
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save
      break
    end # end choice

    set_failed_rule :_sp unless _tmp
    return _tmp
  end

  # p = &. {current_position}
  def _p

    _save = self.pos
    while true # sequence
      _save1 = self.pos
      _tmp = get_byte
      self.pos = _save1
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin; current_position; end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_p unless _tmp
    return _tmp
  end

  # sheebang = "#!" /.*?$/
  def _sheebang

    _save = self.pos
    while true # sequence
      _tmp = match_string("#!")
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = scan(/\A(?-mix:.*?$)/)
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_sheebang unless _tmp
    return _tmp
  end

  # t = (sheebang | nl | ";")
  def _t

    _save = self.pos
    while true # choice
      _tmp = apply(:_sheebang)
      break if _tmp
      self.pos = _save
      _tmp = apply(:_nl)
      break if _tmp
      self.pos = _save
      _tmp = match_string(";")
      break if _tmp
      self.pos = _save
      break
    end # end choice

    set_failed_rule :_t unless _tmp
    return _tmp
  end

  # n = (t | sp | ".")
  def _n

    _save = self.pos
    while true # choice
      _tmp = apply(:_t)
      break if _tmp
      self.pos = _save
      _tmp = apply(:_sp)
      break if _tmp
      self.pos = _save
      _tmp = match_string(".")
      break if _tmp
      self.pos = _save
      break
    end # end choice

    set_failed_rule :_n unless _tmp
    return _tmp
  end

  # - = n*
  def __hyphen_
    while true
      _tmp = apply(:_n)
      break unless _tmp
    end
    _tmp = true
    set_failed_rule :__hyphen_ unless _tmp
    return _tmp
  end

  # brace = (< . . > &{ brace(text) } { brace(text) } | < . > &{ brace(text) } { brace(text) })
  def _brace

    _save = self.pos
    while true # choice

      _save1 = self.pos
      while true # sequence
        _text_start = self.pos

        _save2 = self.pos
        while true # sequence
          _tmp = get_byte
          unless _tmp
            self.pos = _save2
            break
          end
          _tmp = get_byte
          unless _tmp
            self.pos = _save2
          end
          break
        end # end sequence

        if _tmp
          text = get_text(_text_start)
        end
        unless _tmp
          self.pos = _save1
          break
        end
        _save3 = self.pos
        _tmp = begin;  brace(text) ; end
        self.pos = _save3
        unless _tmp
          self.pos = _save1
          break
        end
        @result = begin;  brace(text) ; end
        _tmp = true
        unless _tmp
          self.pos = _save1
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save

      _save4 = self.pos
      while true # sequence
        _text_start = self.pos
        _tmp = get_byte
        if _tmp
          text = get_text(_text_start)
        end
        unless _tmp
          self.pos = _save4
          break
        end
        _save5 = self.pos
        _tmp = begin;  brace(text) ; end
        self.pos = _save5
        unless _tmp
          self.pos = _save4
          break
        end
        @result = begin;  brace(text) ; end
        _tmp = true
        unless _tmp
          self.pos = _save4
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save
      break
    end # end choice

    set_failed_rule :_brace unless _tmp
    return _tmp
  end

  # left_brace = < brace:b > &{ text == b.first} { b }
  def _left_brace

    _save = self.pos
    while true # sequence
      _text_start = self.pos
      _tmp = apply(:_brace)
      b = @result
      if _tmp
        text = get_text(_text_start)
      end
      unless _tmp
        self.pos = _save
        break
      end
      _save1 = self.pos
      _tmp = begin;  text == b.first; end
      self.pos = _save1
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin;  b ; end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_left_brace unless _tmp
    return _tmp
  end

  # right_brace = < brace:b > &{ text == l.last } { l }
  def _right_brace(l)

    _save = self.pos
    while true # sequence
      _text_start = self.pos
      _tmp = apply(:_brace)
      b = @result
      if _tmp
        text = get_text(_text_start)
      end
      unless _tmp
        self.pos = _save
        break
      end
      _save1 = self.pos
      _tmp = begin;  text == l.last ; end
      self.pos = _save1
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin;  l ; end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_right_brace unless _tmp
    return _tmp
  end

  # ident = < /[a-z_]/ /[a-zA-Z0-9_]/* > {text}
  def _ident

    _save = self.pos
    while true # sequence
      _text_start = self.pos

      _save1 = self.pos
      while true # sequence
        _tmp = scan(/\A(?-mix:[a-z_])/)
        unless _tmp
          self.pos = _save1
          break
        end
        while true
          _tmp = scan(/\A(?-mix:[a-zA-Z0-9_])/)
          break unless _tmp
        end
        _tmp = true
        unless _tmp
          self.pos = _save1
        end
        break
      end # end sequence

      if _tmp
        text = get_text(_text_start)
      end
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin; text; end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_ident unless _tmp
    return _tmp
  end

  # const = < /[A-Z]/ /[a-zA-Z0-9_]/* > {text}
  def _const

    _save = self.pos
    while true # sequence
      _text_start = self.pos

      _save1 = self.pos
      while true # sequence
        _tmp = scan(/\A(?-mix:[A-Z])/)
        unless _tmp
          self.pos = _save1
          break
        end
        while true
          _tmp = scan(/\A(?-mix:[a-zA-Z0-9_])/)
          break unless _tmp
        end
        _tmp = true
        unless _tmp
          self.pos = _save1
        end
        break
      end # end sequence

      if _tmp
        text = get_text(_text_start)
      end
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin; text; end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_const unless _tmp
    return _tmp
  end

  # identifier = p:p ident:i {n(p, :ident, i)}
  def _identifier

    _save = self.pos
    while true # sequence
      _tmp = apply(:_p)
      p = @result
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = apply(:_ident)
      i = @result
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin; n(p, :ident, i); end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_identifier unless _tmp
    return _tmp
  end

  # constant = p:p const:c {n(p, :const, c)}
  def _constant

    _save = self.pos
    while true # sequence
      _tmp = apply(:_p)
      p = @result
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = apply(:_const)
      c = @result
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin; n(p, :const, c); end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_constant unless _tmp
    return _tmp
  end

  # keyword = ":" < (!(&(n | ":" | left_brace)) .)+ > !(&":") &{text.size > 0} {text}
  def _keyword

    _save = self.pos
    while true # sequence
      _tmp = match_string(":")
      unless _tmp
        self.pos = _save
        break
      end
      _text_start = self.pos
      _save1 = self.pos

      _save2 = self.pos
      while true # sequence
        _save3 = self.pos
        _save4 = self.pos

        _save5 = self.pos
        while true # choice
          _tmp = apply(:_n)
          break if _tmp
          self.pos = _save5
          _tmp = match_string(":")
          break if _tmp
          self.pos = _save5
          _tmp = apply(:_left_brace)
          break if _tmp
          self.pos = _save5
          break
        end # end choice

        self.pos = _save4
        _tmp = _tmp ? nil : true
        self.pos = _save3
        unless _tmp
          self.pos = _save2
          break
        end
        _tmp = get_byte
        unless _tmp
          self.pos = _save2
        end
        break
      end # end sequence

      if _tmp
        while true

          _save6 = self.pos
          while true # sequence
            _save7 = self.pos
            _save8 = self.pos

            _save9 = self.pos
            while true # choice
              _tmp = apply(:_n)
              break if _tmp
              self.pos = _save9
              _tmp = match_string(":")
              break if _tmp
              self.pos = _save9
              _tmp = apply(:_left_brace)
              break if _tmp
              self.pos = _save9
              break
            end # end choice

            self.pos = _save8
            _tmp = _tmp ? nil : true
            self.pos = _save7
            unless _tmp
              self.pos = _save6
              break
            end
            _tmp = get_byte
            unless _tmp
              self.pos = _save6
            end
            break
          end # end sequence

          break unless _tmp
        end
        _tmp = true
      else
        self.pos = _save1
      end
      if _tmp
        text = get_text(_text_start)
      end
      unless _tmp
        self.pos = _save
        break
      end
      _save10 = self.pos
      _save11 = self.pos
      _tmp = match_string(":")
      self.pos = _save11
      _tmp = _tmp ? nil : true
      self.pos = _save10
      unless _tmp
        self.pos = _save
        break
      end
      _save12 = self.pos
      _tmp = begin; text.size > 0; end
      self.pos = _save12
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin; text; end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_keyword unless _tmp
    return _tmp
  end

  # value = (msg(h) | args | identifier | constant):e &{ e.pos.column > h.column } {e}
  def _value(h)

    _save = self.pos
    while true # sequence

      _save1 = self.pos
      while true # choice
        _tmp = apply_with_args(:_msg, h)
        break if _tmp
        self.pos = _save1
        _tmp = apply(:_args)
        break if _tmp
        self.pos = _save1
        _tmp = apply(:_identifier)
        break if _tmp
        self.pos = _save1
        _tmp = apply(:_constant)
        break if _tmp
        self.pos = _save1
        break
      end # end choice

      e = @result
      unless _tmp
        self.pos = _save
        break
      end
      _save2 = self.pos
      _tmp = begin;  e.pos.column > h.column ; end
      self.pos = _save2
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin; e; end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_value unless _tmp
    return _tmp
  end

  # comma = (block(h):a sp* "," - comma(h):b { b.unshift a ; b } | block(h):a sp* "," - block(h):b { [a,b] })
  def _comma(h)

    _save = self.pos
    while true # choice

      _save1 = self.pos
      while true # sequence
        _tmp = apply_with_args(:_block, h)
        a = @result
        unless _tmp
          self.pos = _save1
          break
        end
        while true
          _tmp = apply(:_sp)
          break unless _tmp
        end
        _tmp = true
        unless _tmp
          self.pos = _save1
          break
        end
        _tmp = match_string(",")
        unless _tmp
          self.pos = _save1
          break
        end
        _tmp = apply(:__hyphen_)
        unless _tmp
          self.pos = _save1
          break
        end
        _tmp = apply_with_args(:_comma, h)
        b = @result
        unless _tmp
          self.pos = _save1
          break
        end
        @result = begin;  b.unshift a ; b ; end
        _tmp = true
        unless _tmp
          self.pos = _save1
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save

      _save3 = self.pos
      while true # sequence
        _tmp = apply_with_args(:_block, h)
        a = @result
        unless _tmp
          self.pos = _save3
          break
        end
        while true
          _tmp = apply(:_sp)
          break unless _tmp
        end
        _tmp = true
        unless _tmp
          self.pos = _save3
          break
        end
        _tmp = match_string(",")
        unless _tmp
          self.pos = _save3
          break
        end
        _tmp = apply(:__hyphen_)
        unless _tmp
          self.pos = _save3
          break
        end
        _tmp = apply_with_args(:_block, h)
        b = @result
        unless _tmp
          self.pos = _save3
          break
        end
        @result = begin;  [a,b] ; end
        _tmp = true
        unless _tmp
          self.pos = _save3
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save
      break
    end # end choice

    set_failed_rule :_comma unless _tmp
    return _tmp
  end

  # tuple = comma(h):c {n(p, :tuple, *c)}
  def _tuple(h)

    _save = self.pos
    while true # sequence
      _tmp = apply_with_args(:_comma, h)
      c = @result
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin; n(p, :tuple, *c); end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_tuple unless _tmp
    return _tmp
  end

  # cons = (expr(h):a sp* ":" - cons(h):b {n(p, :cons, a, b)} | expr(h):a sp* ":" - expr(h):b {n(p, :cons, a, b)})
  def _cons(h)

    _save = self.pos
    while true # choice

      _save1 = self.pos
      while true # sequence
        _tmp = apply_with_args(:_expr, h)
        a = @result
        unless _tmp
          self.pos = _save1
          break
        end
        while true
          _tmp = apply(:_sp)
          break unless _tmp
        end
        _tmp = true
        unless _tmp
          self.pos = _save1
          break
        end
        _tmp = match_string(":")
        unless _tmp
          self.pos = _save1
          break
        end
        _tmp = apply(:__hyphen_)
        unless _tmp
          self.pos = _save1
          break
        end
        _tmp = apply_with_args(:_cons, h)
        b = @result
        unless _tmp
          self.pos = _save1
          break
        end
        @result = begin; n(p, :cons, a, b); end
        _tmp = true
        unless _tmp
          self.pos = _save1
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save

      _save3 = self.pos
      while true # sequence
        _tmp = apply_with_args(:_expr, h)
        a = @result
        unless _tmp
          self.pos = _save3
          break
        end
        while true
          _tmp = apply(:_sp)
          break unless _tmp
        end
        _tmp = true
        unless _tmp
          self.pos = _save3
          break
        end
        _tmp = match_string(":")
        unless _tmp
          self.pos = _save3
          break
        end
        _tmp = apply(:__hyphen_)
        unless _tmp
          self.pos = _save3
          break
        end
        _tmp = apply_with_args(:_expr, h)
        b = @result
        unless _tmp
          self.pos = _save3
          break
        end
        @result = begin; n(p, :cons, a, b); end
        _tmp = true
        unless _tmp
          self.pos = _save3
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save
      break
    end # end choice

    set_failed_rule :_cons unless _tmp
    return _tmp
  end

  # args = p:p left_brace:l - (comma(h) | block(h) | {[]}):a - right_brace(l) {n(p, l.join, *Array(a))}
  def _args

    _save = self.pos
    while true # sequence
      _tmp = apply(:_p)
      p = @result
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = apply(:_left_brace)
      l = @result
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = apply(:__hyphen_)
      unless _tmp
        self.pos = _save
        break
      end

      _save1 = self.pos
      while true # choice
        _tmp = apply_with_args(:_comma, h)
        break if _tmp
        self.pos = _save1
        _tmp = apply_with_args(:_block, h)
        break if _tmp
        self.pos = _save1
        @result = begin; []; end
        _tmp = true
        break if _tmp
        self.pos = _save1
        break
      end # end choice

      a = @result
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = apply(:__hyphen_)
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = apply_with_args(:_right_brace, l)
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin; n(p, l.join, *Array(a)); end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_args unless _tmp
    return _tmp
  end

  # msg = (part(h):a - msg(h | a.pos):m {n(a.pos, :msg, a, *m.args)} | part(h):a {n(a.pos, :msg, a)})
  def _msg(h)

    _save = self.pos
    while true # choice

      _save1 = self.pos
      while true # sequence
        _tmp = apply_with_args(:_part, h)
        a = @result
        unless _tmp
          self.pos = _save1
          break
        end
        _tmp = apply(:__hyphen_)
        unless _tmp
          self.pos = _save1
          break
        end
        _tmp = apply_with_args(:_msg, h | a.pos)
        m = @result
        unless _tmp
          self.pos = _save1
          break
        end
        @result = begin; n(a.pos, :msg, a, *m.args); end
        _tmp = true
        unless _tmp
          self.pos = _save1
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save

      _save2 = self.pos
      while true # sequence
        _tmp = apply_with_args(:_part, h)
        a = @result
        unless _tmp
          self.pos = _save2
          break
        end
        @result = begin; n(a.pos, :msg, a); end
        _tmp = true
        unless _tmp
          self.pos = _save2
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save
      break
    end # end choice

    set_failed_rule :_msg unless _tmp
    return _tmp
  end

  # part = (part(h):p sp* t - block(h | p.pos):e { p.args.push *Array(e) ; p } | part(h):p part_head(h | p.pos):e { p.args.push *Array(e) ; p } | p:p keyword:k args:a {n(p, k, a.name, *a.args)} | p:p keyword:k {n(p, k, "()")})
  def _part(h)

    _save = self.pos
    while true # choice

      _save1 = self.pos
      while true # sequence
        _tmp = apply_with_args(:_part, h)
        p = @result
        unless _tmp
          self.pos = _save1
          break
        end
        while true
          _tmp = apply(:_sp)
          break unless _tmp
        end
        _tmp = true
        unless _tmp
          self.pos = _save1
          break
        end
        _tmp = apply(:_t)
        unless _tmp
          self.pos = _save1
          break
        end
        _tmp = apply(:__hyphen_)
        unless _tmp
          self.pos = _save1
          break
        end
        _tmp = apply_with_args(:_block, h | p.pos)
        e = @result
        unless _tmp
          self.pos = _save1
          break
        end
        @result = begin;  p.args.push *Array(e) ; p ; end
        _tmp = true
        unless _tmp
          self.pos = _save1
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save

      _save3 = self.pos
      while true # sequence
        _tmp = apply_with_args(:_part, h)
        p = @result
        unless _tmp
          self.pos = _save3
          break
        end
        _tmp = apply_with_args(:_part_head, h | p.pos)
        e = @result
        unless _tmp
          self.pos = _save3
          break
        end
        @result = begin;  p.args.push *Array(e) ; p ; end
        _tmp = true
        unless _tmp
          self.pos = _save3
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save

      _save4 = self.pos
      while true # sequence
        _tmp = apply(:_p)
        p = @result
        unless _tmp
          self.pos = _save4
          break
        end
        _tmp = apply(:_keyword)
        k = @result
        unless _tmp
          self.pos = _save4
          break
        end
        _tmp = apply(:_args)
        a = @result
        unless _tmp
          self.pos = _save4
          break
        end
        @result = begin; n(p, k, a.name, *a.args); end
        _tmp = true
        unless _tmp
          self.pos = _save4
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save

      _save5 = self.pos
      while true # sequence
        _tmp = apply(:_p)
        p = @result
        unless _tmp
          self.pos = _save5
          break
        end
        _tmp = apply(:_keyword)
        k = @result
        unless _tmp
          self.pos = _save5
          break
        end
        @result = begin; n(p, k, "()"); end
        _tmp = true
        unless _tmp
          self.pos = _save5
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save
      break
    end # end choice

    set_failed_rule :_part unless _tmp
    return _tmp
  end

  # part_head = sp+ !(&keyword) (ph_comma(h) | expr(h) | {[]})
  def _part_head(h)

    _save = self.pos
    while true # sequence
      _save1 = self.pos
      _tmp = apply(:_sp)
      if _tmp
        while true
          _tmp = apply(:_sp)
          break unless _tmp
        end
        _tmp = true
      else
        self.pos = _save1
      end
      unless _tmp
        self.pos = _save
        break
      end
      _save2 = self.pos
      _save3 = self.pos
      _tmp = apply(:_keyword)
      self.pos = _save3
      _tmp = _tmp ? nil : true
      self.pos = _save2
      unless _tmp
        self.pos = _save
        break
      end

      _save4 = self.pos
      while true # choice
        _tmp = apply_with_args(:_ph_comma, h)
        break if _tmp
        self.pos = _save4
        _tmp = apply_with_args(:_expr, h)
        break if _tmp
        self.pos = _save4
        @result = begin; []; end
        _tmp = true
        break if _tmp
        self.pos = _save4
        break
      end # end choice

      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_part_head unless _tmp
    return _tmp
  end

  # ph_comma = (expr(h):a sp* "," - ph_comma(h):b { b.unshift a ; b } | expr(h):a sp* "," - expr(h):b { [a,b] })
  def _ph_comma(h)

    _save = self.pos
    while true # choice

      _save1 = self.pos
      while true # sequence
        _tmp = apply_with_args(:_expr, h)
        a = @result
        unless _tmp
          self.pos = _save1
          break
        end
        while true
          _tmp = apply(:_sp)
          break unless _tmp
        end
        _tmp = true
        unless _tmp
          self.pos = _save1
          break
        end
        _tmp = match_string(",")
        unless _tmp
          self.pos = _save1
          break
        end
        _tmp = apply(:__hyphen_)
        unless _tmp
          self.pos = _save1
          break
        end
        _tmp = apply_with_args(:_ph_comma, h)
        b = @result
        unless _tmp
          self.pos = _save1
          break
        end
        @result = begin;  b.unshift a ; b ; end
        _tmp = true
        unless _tmp
          self.pos = _save1
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save

      _save3 = self.pos
      while true # sequence
        _tmp = apply_with_args(:_expr, h)
        a = @result
        unless _tmp
          self.pos = _save3
          break
        end
        while true
          _tmp = apply(:_sp)
          break unless _tmp
        end
        _tmp = true
        unless _tmp
          self.pos = _save3
          break
        end
        _tmp = match_string(",")
        unless _tmp
          self.pos = _save3
          break
        end
        _tmp = apply(:__hyphen_)
        unless _tmp
          self.pos = _save3
          break
        end
        _tmp = apply_with_args(:_expr, h)
        b = @result
        unless _tmp
          self.pos = _save3
          break
        end
        @result = begin;  [a,b] ; end
        _tmp = true
        unless _tmp
          self.pos = _save3
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save
      break
    end # end choice

    set_failed_rule :_ph_comma unless _tmp
    return _tmp
  end

  # expr = value(h)
  def _expr(h)
    _tmp = apply_with_args(:_value, h)
    set_failed_rule :_expr unless _tmp
    return _tmp
  end

  # chain = (expr(h):a sp* chain(a.pos):b {n(a.pos, :chain, a, *Array(b.name == :chain && b.args || b))} | expr(h))
  def _chain(h)

    _save = self.pos
    while true # choice

      _save1 = self.pos
      while true # sequence
        _tmp = apply_with_args(:_expr, h)
        a = @result
        unless _tmp
          self.pos = _save1
          break
        end
        while true
          _tmp = apply(:_sp)
          break unless _tmp
        end
        _tmp = true
        unless _tmp
          self.pos = _save1
          break
        end
        _tmp = apply_with_args(:_chain, a.pos)
        b = @result
        unless _tmp
          self.pos = _save1
          break
        end
        @result = begin; n(a.pos, :chain, a, *Array(b.name == :chain && b.args || b)); end
        _tmp = true
        unless _tmp
          self.pos = _save1
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save
      _tmp = apply_with_args(:_expr, h)
      break if _tmp
      self.pos = _save
      break
    end # end choice

    set_failed_rule :_chain unless _tmp
    return _tmp
  end

  # block = (chain(h):a sp* t - block(h):b {n(a.pos, :block, a, *Array(b.name == :block && b.args || b))} | chain(h))
  def _block(h)

    _save = self.pos
    while true # choice

      _save1 = self.pos
      while true # sequence
        _tmp = apply_with_args(:_chain, h)
        a = @result
        unless _tmp
          self.pos = _save1
          break
        end
        while true
          _tmp = apply(:_sp)
          break unless _tmp
        end
        _tmp = true
        unless _tmp
          self.pos = _save1
          break
        end
        _tmp = apply(:_t)
        unless _tmp
          self.pos = _save1
          break
        end
        _tmp = apply(:__hyphen_)
        unless _tmp
          self.pos = _save1
          break
        end
        _tmp = apply_with_args(:_block, h)
        b = @result
        unless _tmp
          self.pos = _save1
          break
        end
        @result = begin; n(a.pos, :block, a, *Array(b.name == :block && b.args || b)); end
        _tmp = true
        unless _tmp
          self.pos = _save1
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save
      _tmp = apply_with_args(:_chain, h)
      break if _tmp
      self.pos = _save
      break
    end # end choice

    set_failed_rule :_block unless _tmp
    return _tmp
  end

  # root = - block(h) - eof
  def _root

    _save = self.pos
    while true # sequence
      _tmp = apply(:__hyphen_)
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = apply_with_args(:_block, h)
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = apply(:__hyphen_)
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = apply(:_eof)
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_root unless _tmp
    return _tmp
  end

  # unit = - chain(h) -
  def _unit

    _save = self.pos
    while true # sequence
      _tmp = apply(:__hyphen_)
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = apply_with_args(:_chain, h)
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = apply(:__hyphen_)
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_unit unless _tmp
    return _tmp
  end

  # eof = !.
  def _eof
    _save = self.pos
    _tmp = get_byte
    _tmp = _tmp ? nil : true
    self.pos = _save
    set_failed_rule :_eof unless _tmp
    return _tmp
  end

  Rules = {}
  Rules[:_nl] = rule_info("nl", "(\"\\n\" | \"\\n\")")
  Rules[:_sp] = rule_info("sp", "(\" \" | \"\\t\" | \"\\\\\" nl)")
  Rules[:_p] = rule_info("p", "&. {current_position}")
  Rules[:_sheebang] = rule_info("sheebang", "\"\#!\" /.*?$/")
  Rules[:_t] = rule_info("t", "(sheebang | nl | \";\")")
  Rules[:_n] = rule_info("n", "(t | sp | \".\")")
  Rules[:__hyphen_] = rule_info("-", "n*")
  Rules[:_brace] = rule_info("brace", "(< . . > &{ brace(text) } { brace(text) } | < . > &{ brace(text) } { brace(text) })")
  Rules[:_left_brace] = rule_info("left_brace", "< brace:b > &{ text == b.first} { b }")
  Rules[:_right_brace] = rule_info("right_brace", "< brace:b > &{ text == l.last } { l }")
  Rules[:_ident] = rule_info("ident", "< /[a-z_]/ /[a-zA-Z0-9_]/* > {text}")
  Rules[:_const] = rule_info("const", "< /[A-Z]/ /[a-zA-Z0-9_]/* > {text}")
  Rules[:_identifier] = rule_info("identifier", "p:p ident:i {n(p, :ident, i)}")
  Rules[:_constant] = rule_info("constant", "p:p const:c {n(p, :const, c)}")
  Rules[:_keyword] = rule_info("keyword", "\":\" < (!(&(n | \":\" | left_brace)) .)+ > !(&\":\") &{text.size > 0} {text}")
  Rules[:_value] = rule_info("value", "(msg(h) | args | identifier | constant):e &{ e.pos.column > h.column } {e}")
  Rules[:_comma] = rule_info("comma", "(block(h):a sp* \",\" - comma(h):b { b.unshift a ; b } | block(h):a sp* \",\" - block(h):b { [a,b] })")
  Rules[:_tuple] = rule_info("tuple", "comma(h):c {n(p, :tuple, *c)}")
  Rules[:_cons] = rule_info("cons", "(expr(h):a sp* \":\" - cons(h):b {n(p, :cons, a, b)} | expr(h):a sp* \":\" - expr(h):b {n(p, :cons, a, b)})")
  Rules[:_args] = rule_info("args", "p:p left_brace:l - (comma(h) | block(h) | {[]}):a - right_brace(l) {n(p, l.join, *Array(a))}")
  Rules[:_msg] = rule_info("msg", "(part(h):a - msg(h | a.pos):m {n(a.pos, :msg, a, *m.args)} | part(h):a {n(a.pos, :msg, a)})")
  Rules[:_part] = rule_info("part", "(part(h):p sp* t - block(h | p.pos):e { p.args.push *Array(e) ; p } | part(h):p part_head(h | p.pos):e { p.args.push *Array(e) ; p } | p:p keyword:k args:a {n(p, k, a.name, *a.args)} | p:p keyword:k {n(p, k, \"()\")})")
  Rules[:_part_head] = rule_info("part_head", "sp+ !(&keyword) (ph_comma(h) | expr(h) | {[]})")
  Rules[:_ph_comma] = rule_info("ph_comma", "(expr(h):a sp* \",\" - ph_comma(h):b { b.unshift a ; b } | expr(h):a sp* \",\" - expr(h):b { [a,b] })")
  Rules[:_expr] = rule_info("expr", "value(h)")
  Rules[:_chain] = rule_info("chain", "(expr(h):a sp* chain(a.pos):b {n(a.pos, :chain, a, *Array(b.name == :chain && b.args || b))} | expr(h))")
  Rules[:_block] = rule_info("block", "(chain(h):a sp* t - block(h):b {n(a.pos, :block, a, *Array(b.name == :block && b.args || b))} | chain(h))")
  Rules[:_root] = rule_info("root", "- block(h) - eof")
  Rules[:_unit] = rule_info("unit", "- chain(h) -")
  Rules[:_eof] = rule_info("eof", "!.")
end
