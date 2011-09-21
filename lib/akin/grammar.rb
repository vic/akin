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

 include Akin::Parser 

  def setup_foreign_grammar; end

  # root = - block(ctx)?:b - eof {b}
  def _root

    _save = self.pos
    while true # sequence
      _tmp = apply(:__hyphen_)
      unless _tmp
        self.pos = _save
        break
      end
      _save1 = self.pos
      _tmp = apply_with_args(:_block, ctx)
      @result = nil unless _tmp
      unless _tmp
        _tmp = true
        self.pos = _save1
      end
      b = @result
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
        break
      end
      @result = begin; b; end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_root unless _tmp
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

  # comment = /#!.*?$/
  def _comment
    _tmp = scan(/\A(?-mix:#!.*?$)/)
    set_failed_rule :_comment unless _tmp
    return _tmp
  end

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

  # ws = (" " | "\t")
  def _ws

    _save = self.pos
    while true # choice
      _tmp = match_string(" ")
      break if _tmp
      self.pos = _save
      _tmp = match_string("\t")
      break if _tmp
      self.pos = _save
      break
    end # end choice

    set_failed_rule :_ws unless _tmp
    return _tmp
  end

  # op = /[\~\!@\#\$%\^\&\|\?\<\>*\/+=:-]/
  def _op
    _tmp = scan(/\A(?-mix:[\~\!@\#\$%\^\&\|\?\<\>*\/+=:-])/)
    set_failed_rule :_op unless _tmp
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

  # - = (ws | nl | comment)*
  def __hyphen_
    while true

      _save1 = self.pos
      while true # choice
        _tmp = apply(:_ws)
        break if _tmp
        self.pos = _save1
        _tmp = apply(:_nl)
        break if _tmp
        self.pos = _save1
        _tmp = apply(:_comment)
        break if _tmp
        self.pos = _save1
        break
      end # end choice

      break unless _tmp
    end
    _tmp = true
    set_failed_rule :__hyphen_ unless _tmp
    return _tmp
  end

  # s = (ws | nl | comment | ";")*
  def _s
    while true

      _save1 = self.pos
      while true # choice
        _tmp = apply(:_ws)
        break if _tmp
        self.pos = _save1
        _tmp = apply(:_nl)
        break if _tmp
        self.pos = _save1
        _tmp = apply(:_comment)
        break if _tmp
        self.pos = _save1
        _tmp = match_string(";")
        break if _tmp
        self.pos = _save1
        break
      end # end choice

      break unless _tmp
    end
    _tmp = true
    set_failed_rule :_s unless _tmp
    return _tmp
  end

  # brace = < . > &{brace(text)} {brace(text)}
  def _brace

    _save = self.pos
    while true # sequence
      _text_start = self.pos
      _tmp = get_byte
      if _tmp
        text = get_text(_text_start)
      end
      unless _tmp
        self.pos = _save
        break
      end
      _save1 = self.pos
      _tmp = begin; brace(text); end
      self.pos = _save1
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin; brace(text); end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_brace unless _tmp
    return _tmp
  end

  # left_brace = < brace:b > &{ text == b.first} {b}
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
      @result = begin; b; end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_left_brace unless _tmp
    return _tmp
  end

  # right_brace = < brace:b > &{ text == l.last } {l}
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
      @result = begin; l; end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_right_brace unless _tmp
    return _tmp
  end

  # braced = left_brace:l - (braced_(ctx) | {nil}):a - right_brace(l) {[l] + Array(a)}
  def _braced

    _save = self.pos
    while true # sequence
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
        _tmp = apply_with_args(:_braced_, ctx)
        break if _tmp
        self.pos = _save1
        @result = begin; nil; end
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
      @result = begin; [l] + Array(a); end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_braced unless _tmp
    return _tmp
  end

  # braced_ = (braced_(x):a - "," - block(x):b {a + Array(b)} | block(x):b {Array(b)})
  def _braced_(x)

    _save = self.pos
    while true # choice

      _save1 = self.pos
      while true # sequence
        _tmp = apply_with_args(:_braced_, x)
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
        _tmp = apply_with_args(:_block, x)
        b = @result
        unless _tmp
          self.pos = _save1
          break
        end
        @result = begin; a + Array(b); end
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
        _tmp = apply_with_args(:_block, x)
        b = @result
        unless _tmp
          self.pos = _save2
          break
        end
        @result = begin; Array(b); end
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

    set_failed_rule :_braced_ unless _tmp
    return _tmp
  end

  # block = (block(x):a ws* nl - block(x):b &{a.pos.column < b.pos.column} { a.name == :chain && (a.args.push(b);a) || a.with(:chain, a, b) } | block_(x):b {b.size > 1 && n(b.first.pos, :block, *b) || b.first})
  def _block(x)

    _save = self.pos
    while true # choice

      _save1 = self.pos
      while true # sequence
        _tmp = apply_with_args(:_block, x)
        a = @result
        unless _tmp
          self.pos = _save1
          break
        end
        while true
          _tmp = apply(:_ws)
          break unless _tmp
        end
        _tmp = true
        unless _tmp
          self.pos = _save1
          break
        end
        _tmp = apply(:_nl)
        unless _tmp
          self.pos = _save1
          break
        end
        _tmp = apply(:__hyphen_)
        unless _tmp
          self.pos = _save1
          break
        end
        _tmp = apply_with_args(:_block, x)
        b = @result
        unless _tmp
          self.pos = _save1
          break
        end
        _save3 = self.pos
        _tmp = begin; a.pos.column < b.pos.column; end
        self.pos = _save3
        unless _tmp
          self.pos = _save1
          break
        end
        @result = begin;  a.name == :chain && (a.args.push(b);a) || a.with(:chain, a, b) ; end
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
        _tmp = apply_with_args(:_block_, x)
        b = @result
        unless _tmp
          self.pos = _save4
          break
        end
        @result = begin; b.size > 1 && n(b.first.pos, :block, *b) || b.first; end
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

    set_failed_rule :_block unless _tmp
    return _tmp
  end

  # block_ = (block_(x):b - ";" s chain(x):c {Array(c)}:a {b + a} | block_(x):b s chain(x):c {Array(c)}:a &{b.first.pos.column == a.first.pos.column} {b + a} | chain(x):c {Array(c)})
  def _block_(x)

    _save = self.pos
    while true # choice

      _save1 = self.pos
      while true # sequence
        _tmp = apply_with_args(:_block_, x)
        b = @result
        unless _tmp
          self.pos = _save1
          break
        end
        _tmp = apply(:__hyphen_)
        unless _tmp
          self.pos = _save1
          break
        end
        _tmp = match_string(";")
        unless _tmp
          self.pos = _save1
          break
        end
        _tmp = apply(:_s)
        unless _tmp
          self.pos = _save1
          break
        end
        _tmp = apply_with_args(:_chain, x)
        c = @result
        unless _tmp
          self.pos = _save1
          break
        end
        @result = begin; Array(c); end
        _tmp = true
        a = @result
        unless _tmp
          self.pos = _save1
          break
        end
        @result = begin; b + a; end
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
        _tmp = apply_with_args(:_block_, x)
        b = @result
        unless _tmp
          self.pos = _save2
          break
        end
        _tmp = apply(:_s)
        unless _tmp
          self.pos = _save2
          break
        end
        _tmp = apply_with_args(:_chain, x)
        c = @result
        unless _tmp
          self.pos = _save2
          break
        end
        @result = begin; Array(c); end
        _tmp = true
        a = @result
        unless _tmp
          self.pos = _save2
          break
        end
        _save3 = self.pos
        _tmp = begin; b.first.pos.column == a.first.pos.column; end
        self.pos = _save3
        unless _tmp
          self.pos = _save2
          break
        end
        @result = begin; b + a; end
        _tmp = true
        unless _tmp
          self.pos = _save2
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save

      _save4 = self.pos
      while true # sequence
        _tmp = apply_with_args(:_chain, x)
        c = @result
        unless _tmp
          self.pos = _save4
          break
        end
        @result = begin; Array(c); end
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

    set_failed_rule :_block_ unless _tmp
    return _tmp
  end

  # chain = chain_(x):c {c.size > 1 && n(c.first.pos, :chain, *c) || c.first}
  def _chain(x)

    _save = self.pos
    while true # sequence
      _tmp = apply_with_args(:_chain_, x)
      c = @result
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin; c.size > 1 && n(c.first.pos, :chain, *c) || c.first; end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_chain unless _tmp
    return _tmp
  end

  # chain_ = (chain_(x):c - "." &{x.kmsg?} - chain_(x):v {c + v} | chain_(x):c &{c.last.name == :oper} (ws* nl -)? value(x.at(c.first.pos)):v {c + v} | chain_(x):c oper:o {c + [o]} | chain_(x):c ws+ value(x.at(c.first.pos)):v {c + v} | value(x))
  def _chain_(x)

    _save = self.pos
    while true # choice

      _save1 = self.pos
      while true # sequence
        _tmp = apply_with_args(:_chain_, x)
        c = @result
        unless _tmp
          self.pos = _save1
          break
        end
        _tmp = apply(:__hyphen_)
        unless _tmp
          self.pos = _save1
          break
        end
        _tmp = match_string(".")
        unless _tmp
          self.pos = _save1
          break
        end
        _save2 = self.pos
        _tmp = begin; x.kmsg?; end
        self.pos = _save2
        unless _tmp
          self.pos = _save1
          break
        end
        _tmp = apply(:__hyphen_)
        unless _tmp
          self.pos = _save1
          break
        end
        _tmp = apply_with_args(:_chain_, x)
        v = @result
        unless _tmp
          self.pos = _save1
          break
        end
        @result = begin; c + v; end
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
        _tmp = apply_with_args(:_chain_, x)
        c = @result
        unless _tmp
          self.pos = _save3
          break
        end
        _save4 = self.pos
        _tmp = begin; c.last.name == :oper; end
        self.pos = _save4
        unless _tmp
          self.pos = _save3
          break
        end
        _save5 = self.pos

        _save6 = self.pos
        while true # sequence
          while true
            _tmp = apply(:_ws)
            break unless _tmp
          end
          _tmp = true
          unless _tmp
            self.pos = _save6
            break
          end
          _tmp = apply(:_nl)
          unless _tmp
            self.pos = _save6
            break
          end
          _tmp = apply(:__hyphen_)
          unless _tmp
            self.pos = _save6
          end
          break
        end # end sequence

        unless _tmp
          _tmp = true
          self.pos = _save5
        end
        unless _tmp
          self.pos = _save3
          break
        end
        _tmp = apply_with_args(:_value, x.at(c.first.pos))
        v = @result
        unless _tmp
          self.pos = _save3
          break
        end
        @result = begin; c + v; end
        _tmp = true
        unless _tmp
          self.pos = _save3
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save

      _save8 = self.pos
      while true # sequence
        _tmp = apply_with_args(:_chain_, x)
        c = @result
        unless _tmp
          self.pos = _save8
          break
        end
        _tmp = apply(:_oper)
        o = @result
        unless _tmp
          self.pos = _save8
          break
        end
        @result = begin; c + [o]; end
        _tmp = true
        unless _tmp
          self.pos = _save8
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save

      _save9 = self.pos
      while true # sequence
        _tmp = apply_with_args(:_chain_, x)
        c = @result
        unless _tmp
          self.pos = _save9
          break
        end
        _save10 = self.pos
        _tmp = apply(:_ws)
        if _tmp
          while true
            _tmp = apply(:_ws)
            break unless _tmp
          end
          _tmp = true
        else
          self.pos = _save10
        end
        unless _tmp
          self.pos = _save9
          break
        end
        _tmp = apply_with_args(:_value, x.at(c.first.pos))
        v = @result
        unless _tmp
          self.pos = _save9
          break
        end
        @result = begin; c + v; end
        _tmp = true
        unless _tmp
          self.pos = _save9
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save
      _tmp = apply_with_args(:_value, x)
      break if _tmp
      self.pos = _save
      break
    end # end choice

    set_failed_rule :_chain_ unless _tmp
    return _tmp
  end

  # value = value_(x):v {Array(v)}:a &{a.first.pos.column > x.pos.column} {a}
  def _value(x)

    _save = self.pos
    while true # sequence
      _tmp = apply_with_args(:_value_, x)
      v = @result
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin; Array(v); end
      _tmp = true
      a = @result
      unless _tmp
        self.pos = _save
        break
      end
      _save1 = self.pos
      _tmp = begin; a.first.pos.column > x.pos.column; end
      self.pos = _save1
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin; a; end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_value unless _tmp
    return _tmp
  end

  # value_ = (&{x.kmsg?} kmsg(x) | value_(x):v p:p braced:b !(&":") {Array(v) + [n(p, :send, *b)]} | empty(x) | space | literal(x):a (&{x.kmsg?} | !(&":")) {a})
  def _value_(x)

    _save = self.pos
    while true # choice

      _save1 = self.pos
      while true # sequence
        _save2 = self.pos
        _tmp = begin; x.kmsg?; end
        self.pos = _save2
        unless _tmp
          self.pos = _save1
          break
        end
        _tmp = apply_with_args(:_kmsg, x)
        unless _tmp
          self.pos = _save1
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save

      _save3 = self.pos
      while true # sequence
        _tmp = apply_with_args(:_value_, x)
        v = @result
        unless _tmp
          self.pos = _save3
          break
        end
        _tmp = apply(:_p)
        p = @result
        unless _tmp
          self.pos = _save3
          break
        end
        _tmp = apply(:_braced)
        b = @result
        unless _tmp
          self.pos = _save3
          break
        end
        _save4 = self.pos
        _save5 = self.pos
        _tmp = match_string(":")
        self.pos = _save5
        _tmp = _tmp ? nil : true
        self.pos = _save4
        unless _tmp
          self.pos = _save3
          break
        end
        @result = begin; Array(v) + [n(p, :send, *b)]; end
        _tmp = true
        unless _tmp
          self.pos = _save3
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save
      _tmp = apply_with_args(:_empty, x)
      break if _tmp
      self.pos = _save
      _tmp = apply(:_space)
      break if _tmp
      self.pos = _save

      _save6 = self.pos
      while true # sequence
        _tmp = apply_with_args(:_literal, x)
        a = @result
        unless _tmp
          self.pos = _save6
          break
        end

        _save7 = self.pos
        while true # choice
          _save8 = self.pos
          _tmp = begin; x.kmsg?; end
          self.pos = _save8
          break if _tmp
          self.pos = _save7
          _save9 = self.pos
          _save10 = self.pos
          _tmp = match_string(":")
          self.pos = _save10
          _tmp = _tmp ? nil : true
          self.pos = _save9
          break if _tmp
          self.pos = _save7
          break
        end # end choice

        unless _tmp
          self.pos = _save6
          break
        end
        @result = begin; a; end
        _tmp = true
        unless _tmp
          self.pos = _save6
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save
      break
    end # end choice

    set_failed_rule :_value_ unless _tmp
    return _tmp
  end

  # space = p:p braced:a {n(p, :space, *a)}
  def _space

    _save = self.pos
    while true # sequence
      _tmp = apply(:_p)
      p = @result
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = apply(:_braced)
      a = @result
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin; n(p, :space, *a); end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_space unless _tmp
    return _tmp
  end

  # empty = p:p braced:a ":" ws* empty_(x):b {n(p, :empty, *(a+b))}
  def _empty(x)

    _save = self.pos
    while true # sequence
      _tmp = apply(:_p)
      p = @result
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = apply(:_braced)
      a = @result
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = match_string(":")
      unless _tmp
        self.pos = _save
        break
      end
      while true
        _tmp = apply(:_ws)
        break unless _tmp
      end
      _tmp = true
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = apply_with_args(:_empty_, x)
      b = @result
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin; n(p, :empty, *(a+b)); end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_empty unless _tmp
    return _tmp
  end

  # empty_ = (braced_(x) | {nil}):a (ws* nl - block(x) | {nil}):b {Array(a) + Array(b)}
  def _empty_(x)

    _save = self.pos
    while true # sequence

      _save1 = self.pos
      while true # choice
        _tmp = apply_with_args(:_braced_, x)
        break if _tmp
        self.pos = _save1
        @result = begin; nil; end
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

      _save2 = self.pos
      while true # choice

        _save3 = self.pos
        while true # sequence
          while true
            _tmp = apply(:_ws)
            break unless _tmp
          end
          _tmp = true
          unless _tmp
            self.pos = _save3
            break
          end
          _tmp = apply(:_nl)
          unless _tmp
            self.pos = _save3
            break
          end
          _tmp = apply(:__hyphen_)
          unless _tmp
            self.pos = _save3
            break
          end
          _tmp = apply_with_args(:_block, x)
          unless _tmp
            self.pos = _save3
          end
          break
        end # end sequence

        break if _tmp
        self.pos = _save2
        @result = begin; nil; end
        _tmp = true
        break if _tmp
        self.pos = _save2
        break
      end # end choice

      b = @result
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin; Array(a) + Array(b); end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_empty_ unless _tmp
    return _tmp
  end

  # name = p:p < (!(&(ws | nl | brace | op | ":" | ";" | "," | ".")) .)+ > {n(p, :name, text)}
  def _name

    _save = self.pos
    while true # sequence
      _tmp = apply(:_p)
      p = @result
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
          _tmp = apply(:_ws)
          break if _tmp
          self.pos = _save5
          _tmp = apply(:_nl)
          break if _tmp
          self.pos = _save5
          _tmp = apply(:_brace)
          break if _tmp
          self.pos = _save5
          _tmp = apply(:_op)
          break if _tmp
          self.pos = _save5
          _tmp = match_string(":")
          break if _tmp
          self.pos = _save5
          _tmp = match_string(";")
          break if _tmp
          self.pos = _save5
          _tmp = match_string(",")
          break if _tmp
          self.pos = _save5
          _tmp = match_string(".")
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
              _tmp = apply(:_ws)
              break if _tmp
              self.pos = _save9
              _tmp = apply(:_nl)
              break if _tmp
              self.pos = _save9
              _tmp = apply(:_brace)
              break if _tmp
              self.pos = _save9
              _tmp = apply(:_op)
              break if _tmp
              self.pos = _save9
              _tmp = match_string(":")
              break if _tmp
              self.pos = _save9
              _tmp = match_string(";")
              break if _tmp
              self.pos = _save9
              _tmp = match_string(",")
              break if _tmp
              self.pos = _save9
              _tmp = match_string(".")
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
      @result = begin; n(p, :name, text); end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_name unless _tmp
    return _tmp
  end

  # oper = p:p < (".." (op | ".")* | op op*) > {n(p, :oper, text)}
  def _oper

    _save = self.pos
    while true # sequence
      _tmp = apply(:_p)
      p = @result
      unless _tmp
        self.pos = _save
        break
      end
      _text_start = self.pos

      _save1 = self.pos
      while true # choice

        _save2 = self.pos
        while true # sequence
          _tmp = match_string("..")
          unless _tmp
            self.pos = _save2
            break
          end
          while true

            _save4 = self.pos
            while true # choice
              _tmp = apply(:_op)
              break if _tmp
              self.pos = _save4
              _tmp = match_string(".")
              break if _tmp
              self.pos = _save4
              break
            end # end choice

            break unless _tmp
          end
          _tmp = true
          unless _tmp
            self.pos = _save2
          end
          break
        end # end sequence

        break if _tmp
        self.pos = _save1

        _save5 = self.pos
        while true # sequence
          _tmp = apply(:_op)
          unless _tmp
            self.pos = _save5
            break
          end
          while true
            _tmp = apply(:_op)
            break unless _tmp
          end
          _tmp = true
          unless _tmp
            self.pos = _save5
          end
          break
        end # end sequence

        break if _tmp
        self.pos = _save1
        break
      end # end choice

      if _tmp
        text = get_text(_text_start)
      end
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin; n(p, :oper, text); end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_oper unless _tmp
    return _tmp
  end

  # keyargs = (keyargs_(x.kmsg!) | {nil}):a (ws* nl - braced_(x) | {nil}):b {Array(a) + Array(b)}
  def _keyargs(x)

    _save = self.pos
    while true # sequence

      _save1 = self.pos
      while true # choice
        _tmp = apply_with_args(:_keyargs_, x.kmsg!)
        break if _tmp
        self.pos = _save1
        @result = begin; nil; end
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

      _save2 = self.pos
      while true # choice

        _save3 = self.pos
        while true # sequence
          while true
            _tmp = apply(:_ws)
            break unless _tmp
          end
          _tmp = true
          unless _tmp
            self.pos = _save3
            break
          end
          _tmp = apply(:_nl)
          unless _tmp
            self.pos = _save3
            break
          end
          _tmp = apply(:__hyphen_)
          unless _tmp
            self.pos = _save3
            break
          end
          _tmp = apply_with_args(:_braced_, x)
          unless _tmp
            self.pos = _save3
          end
          break
        end # end sequence

        break if _tmp
        self.pos = _save2
        @result = begin; nil; end
        _tmp = true
        break if _tmp
        self.pos = _save2
        break
      end # end choice

      b = @result
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin; Array(a) + Array(b); end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_keyargs unless _tmp
    return _tmp
  end

  # keyargs_ = (keyargs_(x):a ws* "," ws* chain(x):c {a + Array(c)} | chain(x):c {Array(c)})
  def _keyargs_(x)

    _save = self.pos
    while true # choice

      _save1 = self.pos
      while true # sequence
        _tmp = apply_with_args(:_keyargs_, x)
        a = @result
        unless _tmp
          self.pos = _save1
          break
        end
        while true
          _tmp = apply(:_ws)
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
        while true
          _tmp = apply(:_ws)
          break unless _tmp
        end
        _tmp = true
        unless _tmp
          self.pos = _save1
          break
        end
        _tmp = apply_with_args(:_chain, x)
        c = @result
        unless _tmp
          self.pos = _save1
          break
        end
        @result = begin; a + Array(c); end
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
        _tmp = apply_with_args(:_chain, x)
        c = @result
        unless _tmp
          self.pos = _save4
          break
        end
        @result = begin; Array(c); end
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

    set_failed_rule :_keyargs_ unless _tmp
    return _tmp
  end

  # keyw = < (name | oper) > ":" {[text, nil]}
  def _keyw(x)

    _save = self.pos
    while true # sequence
      _text_start = self.pos

      _save1 = self.pos
      while true # choice
        _tmp = apply(:_name)
        break if _tmp
        self.pos = _save1
        _tmp = apply(:_oper)
        break if _tmp
        self.pos = _save1
        break
      end # end choice

      if _tmp
        text = get_text(_text_start)
      end
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = match_string(":")
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin; [text, nil]; end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_keyw unless _tmp
    return _tmp
  end

  # keya = < (name | oper) > braced:a ":" {[text] + a}
  def _keya(x)

    _save = self.pos
    while true # sequence
      _text_start = self.pos

      _save1 = self.pos
      while true # choice
        _tmp = apply(:_name)
        break if _tmp
        self.pos = _save1
        _tmp = apply(:_oper)
        break if _tmp
        self.pos = _save1
        break
      end # end choice

      if _tmp
        text = get_text(_text_start)
      end
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = apply(:_braced)
      a = @result
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = match_string(":")
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin; [text] + a; end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_keya unless _tmp
    return _tmp
  end

  # keyword = (keyw(x) | keya(x))
  def _keyword(x)

    _save = self.pos
    while true # choice
      _tmp = apply_with_args(:_keyw, x)
      break if _tmp
      self.pos = _save
      _tmp = apply_with_args(:_keya, x)
      break if _tmp
      self.pos = _save
      break
    end # end choice

    set_failed_rule :_keyword unless _tmp
    return _tmp
  end

  # part = (p:p keyword(x):a &(ws* keyword(x)) {n(p, :part, *a)} | p:p keyword(x):a ws* "." - empty_(x):b {n(p, :part, *(a+b))} | p:p keyword(x):a ws* keyargs(x.in(x.pos.minor(p))):b {n(p, :part, *(a+b))})
  def _part(x)

    _save = self.pos
    while true # choice

      _save1 = self.pos
      while true # sequence
        _tmp = apply(:_p)
        p = @result
        unless _tmp
          self.pos = _save1
          break
        end
        _tmp = apply_with_args(:_keyword, x)
        a = @result
        unless _tmp
          self.pos = _save1
          break
        end
        _save2 = self.pos

        _save3 = self.pos
        while true # sequence
          while true
            _tmp = apply(:_ws)
            break unless _tmp
          end
          _tmp = true
          unless _tmp
            self.pos = _save3
            break
          end
          _tmp = apply_with_args(:_keyword, x)
          unless _tmp
            self.pos = _save3
          end
          break
        end # end sequence

        self.pos = _save2
        unless _tmp
          self.pos = _save1
          break
        end
        @result = begin; n(p, :part, *a); end
        _tmp = true
        unless _tmp
          self.pos = _save1
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
        _tmp = apply_with_args(:_keyword, x)
        a = @result
        unless _tmp
          self.pos = _save5
          break
        end
        while true
          _tmp = apply(:_ws)
          break unless _tmp
        end
        _tmp = true
        unless _tmp
          self.pos = _save5
          break
        end
        _tmp = match_string(".")
        unless _tmp
          self.pos = _save5
          break
        end
        _tmp = apply(:__hyphen_)
        unless _tmp
          self.pos = _save5
          break
        end
        _tmp = apply_with_args(:_empty_, x)
        b = @result
        unless _tmp
          self.pos = _save5
          break
        end
        @result = begin; n(p, :part, *(a+b)); end
        _tmp = true
        unless _tmp
          self.pos = _save5
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save

      _save7 = self.pos
      while true # sequence
        _tmp = apply(:_p)
        p = @result
        unless _tmp
          self.pos = _save7
          break
        end
        _tmp = apply_with_args(:_keyword, x)
        a = @result
        unless _tmp
          self.pos = _save7
          break
        end
        while true
          _tmp = apply(:_ws)
          break unless _tmp
        end
        _tmp = true
        unless _tmp
          self.pos = _save7
          break
        end
        _tmp = apply_with_args(:_keyargs, x.in(x.pos.minor(p)))
        b = @result
        unless _tmp
          self.pos = _save7
          break
        end
        @result = begin; n(p, :part, *(a+b)); end
        _tmp = true
        unless _tmp
          self.pos = _save7
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

  # parts = (parts(x):a - part(x):b {a + [b]} | part(x):a {[a]})
  def _parts(x)

    _save = self.pos
    while true # choice

      _save1 = self.pos
      while true # sequence
        _tmp = apply_with_args(:_parts, x)
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
        _tmp = apply_with_args(:_part, x)
        b = @result
        unless _tmp
          self.pos = _save1
          break
        end
        @result = begin; a + [b]; end
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
        _tmp = apply_with_args(:_part, x)
        a = @result
        unless _tmp
          self.pos = _save2
          break
        end
        @result = begin; [a]; end
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

    set_failed_rule :_parts unless _tmp
    return _tmp
  end

  # kmsg = parts(x):a {n(a.first.pos, :kmsg, *a)}
  def _kmsg(x)

    _save = self.pos
    while true # sequence
      _tmp = apply_with_args(:_parts, x)
      a = @result
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin; n(a.first.pos, :kmsg, *a); end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_kmsg unless _tmp
    return _tmp
  end

  # literal = (symbol(x) | infix | str | float | fixnum | regexp | name | oper)
  def _literal(x)

    _save = self.pos
    while true # choice
      _tmp = apply_with_args(:_symbol, x)
      break if _tmp
      self.pos = _save
      _tmp = apply(:_infix)
      break if _tmp
      self.pos = _save
      _tmp = apply(:_str)
      break if _tmp
      self.pos = _save
      _tmp = apply(:_float)
      break if _tmp
      self.pos = _save
      _tmp = apply(:_fixnum)
      break if _tmp
      self.pos = _save
      _tmp = apply(:_regexp)
      break if _tmp
      self.pos = _save
      _tmp = apply(:_name)
      break if _tmp
      self.pos = _save
      _tmp = apply(:_oper)
      break if _tmp
      self.pos = _save
      break
    end # end choice

    set_failed_rule :_literal unless _tmp
    return _tmp
  end

  # symbol = p:p ":" !(&":") value(x.kmsg):v {n(p, :symbol, v.first)}
  def _symbol(x)

    _save = self.pos
    while true # sequence
      _tmp = apply(:_p)
      p = @result
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = match_string(":")
      unless _tmp
        self.pos = _save
        break
      end
      _save1 = self.pos
      _save2 = self.pos
      _tmp = match_string(":")
      self.pos = _save2
      _tmp = _tmp ? nil : true
      self.pos = _save1
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = apply_with_args(:_value, x.kmsg)
      v = @result
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin; n(p, :symbol, v.first); end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_symbol unless _tmp
    return _tmp
  end

  # infix_ = (< "#"+ > !(&(brace | "!")) {text.size} | {0})
  def _infix_

    _save = self.pos
    while true # choice

      _save1 = self.pos
      while true # sequence
        _text_start = self.pos
        _save2 = self.pos
        _tmp = match_string("#")
        if _tmp
          while true
            _tmp = match_string("#")
            break unless _tmp
          end
          _tmp = true
        else
          self.pos = _save2
        end
        if _tmp
          text = get_text(_text_start)
        end
        unless _tmp
          self.pos = _save1
          break
        end
        _save3 = self.pos
        _save4 = self.pos

        _save5 = self.pos
        while true # choice
          _tmp = apply(:_brace)
          break if _tmp
          self.pos = _save5
          _tmp = match_string("!")
          break if _tmp
          self.pos = _save5
          break
        end # end choice

        self.pos = _save4
        _tmp = _tmp ? nil : true
        self.pos = _save3
        unless _tmp
          self.pos = _save1
          break
        end
        @result = begin; text.size; end
        _tmp = true
        unless _tmp
          self.pos = _save1
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save
      @result = begin; 0; end
      _tmp = true
      break if _tmp
      self.pos = _save
      break
    end # end choice

    set_failed_rule :_infix_ unless _tmp
    return _tmp
  end

  # infix = p:p infix_:l < (name | oper) > infix_:r &{ l+r > 0 } {n(p, :infix, text, l, r)}
  def _infix

    _save = self.pos
    while true # sequence
      _tmp = apply(:_p)
      p = @result
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = apply(:_infix_)
      l = @result
      unless _tmp
        self.pos = _save
        break
      end
      _text_start = self.pos

      _save1 = self.pos
      while true # choice
        _tmp = apply(:_name)
        break if _tmp
        self.pos = _save1
        _tmp = apply(:_oper)
        break if _tmp
        self.pos = _save1
        break
      end # end choice

      if _tmp
        text = get_text(_text_start)
      end
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = apply(:_infix_)
      r = @result
      unless _tmp
        self.pos = _save
        break
      end
      _save2 = self.pos
      _tmp = begin;  l+r > 0 ; end
      self.pos = _save2
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin; n(p, :infix, text, l, r); end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_infix unless _tmp
    return _tmp
  end

  # regexp = p:p quoted(:text, &"/"):b {n(p, :regexp, text_node(p, b))}
  def _regexp

    _save = self.pos
    while true # sequence
      _tmp = apply(:_p)
      p = @result
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = apply_with_args(:_quoted, :text, (@refargs[0] ||= Proc.new {
        _tmp = match_string("/")
        _tmp
      }))
      b = @result
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin; n(p, :regexp, text_node(p, b)); end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_regexp unless _tmp
    return _tmp
  end

  # float = p:p sign:s dec:n "." dec:f {n(p, :float, (s+n+"."+f).to_f)}
  def _float

    _save = self.pos
    while true # sequence
      _tmp = apply(:_p)
      p = @result
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = apply(:_sign)
      s = @result
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = apply(:_dec)
      n = @result
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = match_string(".")
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = apply(:_dec)
      f = @result
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin; n(p, :float, (s+n+"."+f).to_f); end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_float unless _tmp
    return _tmp
  end

  # fixnum = p:p (hexadec | binary | octal | decimal):n {n(p, :fixnum, n)}
  def _fixnum

    _save = self.pos
    while true # sequence
      _tmp = apply(:_p)
      p = @result
      unless _tmp
        self.pos = _save
        break
      end

      _save1 = self.pos
      while true # choice
        _tmp = apply(:_hexadec)
        break if _tmp
        self.pos = _save1
        _tmp = apply(:_binary)
        break if _tmp
        self.pos = _save1
        _tmp = apply(:_octal)
        break if _tmp
        self.pos = _save1
        _tmp = apply(:_decimal)
        break if _tmp
        self.pos = _save1
        break
      end # end choice

      n = @result
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin; n(p, :fixnum, n); end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_fixnum unless _tmp
    return _tmp
  end

  # digits = < d+ ("_" d+)* > { text.gsub('_', '') }
  def _digits(d)

    _save = self.pos
    while true # sequence
      _text_start = self.pos

      _save1 = self.pos
      while true # sequence
        _save2 = self.pos
        _tmp = d.call()
        if _tmp
          while true
            _tmp = d.call()
            break unless _tmp
          end
          _tmp = true
        else
          self.pos = _save2
        end
        unless _tmp
          self.pos = _save1
          break
        end
        while true

          _save4 = self.pos
          while true # sequence
            _tmp = match_string("_")
            unless _tmp
              self.pos = _save4
              break
            end
            _save5 = self.pos
            _tmp = d.call()
            if _tmp
              while true
                _tmp = d.call()
                break unless _tmp
              end
              _tmp = true
            else
              self.pos = _save5
            end
            unless _tmp
              self.pos = _save4
            end
            break
          end # end sequence

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
      @result = begin;  text.gsub('_', '') ; end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_digits unless _tmp
    return _tmp
  end

  # sign = ("+" {"+"} | "-" { "-"} | {"+"})
  def _sign

    _save = self.pos
    while true # choice

      _save1 = self.pos
      while true # sequence
        _tmp = match_string("+")
        unless _tmp
          self.pos = _save1
          break
        end
        @result = begin; "+"; end
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
        _tmp = match_string("-")
        unless _tmp
          self.pos = _save2
          break
        end
        @result = begin;  "-"; end
        _tmp = true
        unless _tmp
          self.pos = _save2
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save
      @result = begin; "+"; end
      _tmp = true
      break if _tmp
      self.pos = _save
      break
    end # end choice

    set_failed_rule :_sign unless _tmp
    return _tmp
  end

  # dec = digits(&/[0-9]/):d {d}
  def _dec

    _save = self.pos
    while true # sequence
      _tmp = apply_with_args(:_digits, (@refargs[1] ||= Proc.new {
        _tmp = scan(/\A(?-mix:[0-9])/)
        _tmp
      }))
      d = @result
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin; d; end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_dec unless _tmp
    return _tmp
  end

  # oct = "0" /[oO]/? digits(&/[0-7]/):d {d}
  def _oct

    _save = self.pos
    while true # sequence
      _tmp = match_string("0")
      unless _tmp
        self.pos = _save
        break
      end
      _save1 = self.pos
      _tmp = scan(/\A(?-mix:[oO])/)
      unless _tmp
        _tmp = true
        self.pos = _save1
      end
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = apply_with_args(:_digits, (@refargs[2] ||= Proc.new {
        _tmp = scan(/\A(?-mix:[0-7])/)
        _tmp
      }))
      d = @result
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin; d; end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_oct unless _tmp
    return _tmp
  end

  # hex = "0" /[xX]/ digits(&/[0-9a-fA-F]/):d {d}
  def _hex

    _save = self.pos
    while true # sequence
      _tmp = match_string("0")
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = scan(/\A(?-mix:[xX])/)
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = apply_with_args(:_digits, (@refargs[3] ||= Proc.new {
        _tmp = scan(/\A(?-mix:[0-9a-fA-F])/)
        _tmp
      }))
      d = @result
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin; d; end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_hex unless _tmp
    return _tmp
  end

  # bin = "0" /[bB]/ digits(&/[0-1]/):d {d}
  def _bin

    _save = self.pos
    while true # sequence
      _tmp = match_string("0")
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = scan(/\A(?-mix:[bB])/)
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = apply_with_args(:_digits, (@refargs[4] ||= Proc.new {
        _tmp = scan(/\A(?-mix:[0-1])/)
        _tmp
      }))
      d = @result
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin; d; end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_bin unless _tmp
    return _tmp
  end

  # hexadec = sign:s hex:d {(s+d).to_i(16)}
  def _hexadec

    _save = self.pos
    while true # sequence
      _tmp = apply(:_sign)
      s = @result
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = apply(:_hex)
      d = @result
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin; (s+d).to_i(16); end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_hexadec unless _tmp
    return _tmp
  end

  # binary = sign:s bin:d {(s+d).to_i(2)}
  def _binary

    _save = self.pos
    while true # sequence
      _tmp = apply(:_sign)
      s = @result
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = apply(:_bin)
      d = @result
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin; (s+d).to_i(2); end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_binary unless _tmp
    return _tmp
  end

  # octal = sign:s oct:d {(s+d).to_i(8)}
  def _octal

    _save = self.pos
    while true # sequence
      _tmp = apply(:_sign)
      s = @result
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = apply(:_oct)
      d = @result
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin; (s+d).to_i(8); end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_octal unless _tmp
    return _tmp
  end

  # decimal = sign:s dec:d {(s+d).to_i(10)}
  def _decimal

    _save = self.pos
    while true # sequence
      _tmp = apply(:_sign)
      s = @result
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = apply(:_dec)
      d = @result
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin; (s+d).to_i(10); end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_decimal unless _tmp
    return _tmp
  end

  # str = (mstr | sstr | qstr)
  def _str

    _save = self.pos
    while true # choice
      _tmp = apply(:_mstr)
      break if _tmp
      self.pos = _save
      _tmp = apply(:_sstr)
      break if _tmp
      self.pos = _save
      _tmp = apply(:_qstr)
      break if _tmp
      self.pos = _save
      break
    end # end choice

    set_failed_rule :_str unless _tmp
    return _tmp
  end

  # qstr = p:p "'" < ("\\" escape | "\\'" | !(&"'") .)* > "'" {n(p, :text, text)}
  def _qstr

    _save = self.pos
    while true # sequence
      _tmp = apply(:_p)
      p = @result
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = match_string("'")
      unless _tmp
        self.pos = _save
        break
      end
      _text_start = self.pos
      while true

        _save2 = self.pos
        while true # choice

          _save3 = self.pos
          while true # sequence
            _tmp = match_string("\\")
            unless _tmp
              self.pos = _save3
              break
            end
            _tmp = apply(:_escape)
            unless _tmp
              self.pos = _save3
            end
            break
          end # end sequence

          break if _tmp
          self.pos = _save2
          _tmp = match_string("\\'")
          break if _tmp
          self.pos = _save2

          _save4 = self.pos
          while true # sequence
            _save5 = self.pos
            _save6 = self.pos
            _tmp = match_string("'")
            self.pos = _save6
            _tmp = _tmp ? nil : true
            self.pos = _save5
            unless _tmp
              self.pos = _save4
              break
            end
            _tmp = get_byte
            unless _tmp
              self.pos = _save4
            end
            break
          end # end sequence

          break if _tmp
          self.pos = _save2
          break
        end # end choice

        break unless _tmp
      end
      _tmp = true
      if _tmp
        text = get_text(_text_start)
      end
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = match_string("'")
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin; n(p, :text, text); end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_qstr unless _tmp
    return _tmp
  end

  # sstr = p:p quoted(:text, &"\""):b {text_node(p, b)}
  def _sstr

    _save = self.pos
    while true # sequence
      _tmp = apply(:_p)
      p = @result
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = apply_with_args(:_quoted, :text, (@refargs[5] ||= Proc.new {
        _tmp = match_string("\"")
        _tmp
      }))
      b = @result
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin; text_node(p, b); end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_sstr unless _tmp
    return _tmp
  end

  # quoted = q quoted_inner(t, q)*:b q {b}
  def _quoted(t,q)

    _save = self.pos
    while true # sequence
      _tmp = q.call()
      unless _tmp
        self.pos = _save
        break
      end
      _ary = []
      while true
        _tmp = apply_with_args(:_quoted_inner, t, q)
        _ary << @result if _tmp
        break unless _tmp
      end
      _tmp = true
      @result = _ary
      b = @result
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = q.call()
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin; b; end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_quoted unless _tmp
    return _tmp
  end

  # quoted_inner = (p:p "#{" - block(ctx)?:b - "}" {b} | p:p < ("\\" escape | ("\\" q | "\\#" | &(!(q | "#{")) .))+ > {n(p, t, text)})
  def _quoted_inner(t,q)

    _save = self.pos
    while true # choice

      _save1 = self.pos
      while true # sequence
        _tmp = apply(:_p)
        p = @result
        unless _tmp
          self.pos = _save1
          break
        end
        _tmp = match_string("\#{")
        unless _tmp
          self.pos = _save1
          break
        end
        _tmp = apply(:__hyphen_)
        unless _tmp
          self.pos = _save1
          break
        end
        _save2 = self.pos
        _tmp = apply_with_args(:_block, ctx)
        @result = nil unless _tmp
        unless _tmp
          _tmp = true
          self.pos = _save2
        end
        b = @result
        unless _tmp
          self.pos = _save1
          break
        end
        _tmp = apply(:__hyphen_)
        unless _tmp
          self.pos = _save1
          break
        end
        _tmp = match_string("}")
        unless _tmp
          self.pos = _save1
          break
        end
        @result = begin; b; end
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
        _tmp = apply(:_p)
        p = @result
        unless _tmp
          self.pos = _save3
          break
        end
        _text_start = self.pos
        _save4 = self.pos

        _save5 = self.pos
        while true # choice

          _save6 = self.pos
          while true # sequence
            _tmp = match_string("\\")
            unless _tmp
              self.pos = _save6
              break
            end
            _tmp = apply(:_escape)
            unless _tmp
              self.pos = _save6
            end
            break
          end # end sequence

          break if _tmp
          self.pos = _save5

          _save7 = self.pos
          while true # choice

            _save8 = self.pos
            while true # sequence
              _tmp = match_string("\\")
              unless _tmp
                self.pos = _save8
                break
              end
              _tmp = q.call()
              unless _tmp
                self.pos = _save8
              end
              break
            end # end sequence

            break if _tmp
            self.pos = _save7
            _tmp = match_string("\\#")
            break if _tmp
            self.pos = _save7

            _save9 = self.pos
            while true # sequence
              _save10 = self.pos
              _save11 = self.pos

              _save12 = self.pos
              while true # choice
                _tmp = q.call()
                break if _tmp
                self.pos = _save12
                _tmp = match_string("\#{")
                break if _tmp
                self.pos = _save12
                break
              end # end choice

              _tmp = _tmp ? nil : true
              self.pos = _save11
              self.pos = _save10
              unless _tmp
                self.pos = _save9
                break
              end
              _tmp = get_byte
              unless _tmp
                self.pos = _save9
              end
              break
            end # end sequence

            break if _tmp
            self.pos = _save7
            break
          end # end choice

          break if _tmp
          self.pos = _save5
          break
        end # end choice

        if _tmp
          while true

            _save13 = self.pos
            while true # choice

              _save14 = self.pos
              while true # sequence
                _tmp = match_string("\\")
                unless _tmp
                  self.pos = _save14
                  break
                end
                _tmp = apply(:_escape)
                unless _tmp
                  self.pos = _save14
                end
                break
              end # end sequence

              break if _tmp
              self.pos = _save13

              _save15 = self.pos
              while true # choice

                _save16 = self.pos
                while true # sequence
                  _tmp = match_string("\\")
                  unless _tmp
                    self.pos = _save16
                    break
                  end
                  _tmp = q.call()
                  unless _tmp
                    self.pos = _save16
                  end
                  break
                end # end sequence

                break if _tmp
                self.pos = _save15
                _tmp = match_string("\\#")
                break if _tmp
                self.pos = _save15

                _save17 = self.pos
                while true # sequence
                  _save18 = self.pos
                  _save19 = self.pos

                  _save20 = self.pos
                  while true # choice
                    _tmp = q.call()
                    break if _tmp
                    self.pos = _save20
                    _tmp = match_string("\#{")
                    break if _tmp
                    self.pos = _save20
                    break
                  end # end choice

                  _tmp = _tmp ? nil : true
                  self.pos = _save19
                  self.pos = _save18
                  unless _tmp
                    self.pos = _save17
                    break
                  end
                  _tmp = get_byte
                  unless _tmp
                    self.pos = _save17
                  end
                  break
                end # end sequence

                break if _tmp
                self.pos = _save15
                break
              end # end choice

              break if _tmp
              self.pos = _save13
              break
            end # end choice

            break unless _tmp
          end
          _tmp = true
        else
          self.pos = _save4
        end
        if _tmp
          text = get_text(_text_start)
        end
        unless _tmp
          self.pos = _save3
          break
        end
        @result = begin; n(p, t, text); end
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

    set_failed_rule :_quoted_inner unless _tmp
    return _tmp
  end

  # mstr = p:p "\"\"\"" mstr_inner*:b "\"\"\"" {text_node(p, b)}
  def _mstr

    _save = self.pos
    while true # sequence
      _tmp = apply(:_p)
      p = @result
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = match_string("\"\"\"")
      unless _tmp
        self.pos = _save
        break
      end
      _ary = []
      while true
        _tmp = apply(:_mstr_inner)
        _ary << @result if _tmp
        break unless _tmp
      end
      _tmp = true
      @result = _ary
      b = @result
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = match_string("\"\"\"")
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin; text_node(p, b); end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_mstr unless _tmp
    return _tmp
  end

  # mstr_inner = (p:p "#{" - block(h)?:b - "}" {b} | p:p < ("\\" escape | ("\\\"\"\"" | !(&("\"\"\"" | "#{")) . | . &"\"\"\""))+ > {n(p, :text, text)})
  def _mstr_inner

    _save = self.pos
    while true # choice

      _save1 = self.pos
      while true # sequence
        _tmp = apply(:_p)
        p = @result
        unless _tmp
          self.pos = _save1
          break
        end
        _tmp = match_string("\#{")
        unless _tmp
          self.pos = _save1
          break
        end
        _tmp = apply(:__hyphen_)
        unless _tmp
          self.pos = _save1
          break
        end
        _save2 = self.pos
        _tmp = apply_with_args(:_block, h)
        @result = nil unless _tmp
        unless _tmp
          _tmp = true
          self.pos = _save2
        end
        b = @result
        unless _tmp
          self.pos = _save1
          break
        end
        _tmp = apply(:__hyphen_)
        unless _tmp
          self.pos = _save1
          break
        end
        _tmp = match_string("}")
        unless _tmp
          self.pos = _save1
          break
        end
        @result = begin; b; end
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
        _tmp = apply(:_p)
        p = @result
        unless _tmp
          self.pos = _save3
          break
        end
        _text_start = self.pos
        _save4 = self.pos

        _save5 = self.pos
        while true # choice

          _save6 = self.pos
          while true # sequence
            _tmp = match_string("\\")
            unless _tmp
              self.pos = _save6
              break
            end
            _tmp = apply(:_escape)
            unless _tmp
              self.pos = _save6
            end
            break
          end # end sequence

          break if _tmp
          self.pos = _save5

          _save7 = self.pos
          while true # choice
            _tmp = match_string("\\\"\"\"")
            break if _tmp
            self.pos = _save7

            _save8 = self.pos
            while true # sequence
              _save9 = self.pos
              _save10 = self.pos

              _save11 = self.pos
              while true # choice
                _tmp = match_string("\"\"\"")
                break if _tmp
                self.pos = _save11
                _tmp = match_string("\#{")
                break if _tmp
                self.pos = _save11
                break
              end # end choice

              self.pos = _save10
              _tmp = _tmp ? nil : true
              self.pos = _save9
              unless _tmp
                self.pos = _save8
                break
              end
              _tmp = get_byte
              unless _tmp
                self.pos = _save8
              end
              break
            end # end sequence

            break if _tmp
            self.pos = _save7

            _save12 = self.pos
            while true # sequence
              _tmp = get_byte
              unless _tmp
                self.pos = _save12
                break
              end
              _save13 = self.pos
              _tmp = match_string("\"\"\"")
              self.pos = _save13
              unless _tmp
                self.pos = _save12
              end
              break
            end # end sequence

            break if _tmp
            self.pos = _save7
            break
          end # end choice

          break if _tmp
          self.pos = _save5
          break
        end # end choice

        if _tmp
          while true

            _save14 = self.pos
            while true # choice

              _save15 = self.pos
              while true # sequence
                _tmp = match_string("\\")
                unless _tmp
                  self.pos = _save15
                  break
                end
                _tmp = apply(:_escape)
                unless _tmp
                  self.pos = _save15
                end
                break
              end # end sequence

              break if _tmp
              self.pos = _save14

              _save16 = self.pos
              while true # choice
                _tmp = match_string("\\\"\"\"")
                break if _tmp
                self.pos = _save16

                _save17 = self.pos
                while true # sequence
                  _save18 = self.pos
                  _save19 = self.pos

                  _save20 = self.pos
                  while true # choice
                    _tmp = match_string("\"\"\"")
                    break if _tmp
                    self.pos = _save20
                    _tmp = match_string("\#{")
                    break if _tmp
                    self.pos = _save20
                    break
                  end # end choice

                  self.pos = _save19
                  _tmp = _tmp ? nil : true
                  self.pos = _save18
                  unless _tmp
                    self.pos = _save17
                    break
                  end
                  _tmp = get_byte
                  unless _tmp
                    self.pos = _save17
                  end
                  break
                end # end sequence

                break if _tmp
                self.pos = _save16

                _save21 = self.pos
                while true # sequence
                  _tmp = get_byte
                  unless _tmp
                    self.pos = _save21
                    break
                  end
                  _save22 = self.pos
                  _tmp = match_string("\"\"\"")
                  self.pos = _save22
                  unless _tmp
                    self.pos = _save21
                  end
                  break
                end # end sequence

                break if _tmp
                self.pos = _save16
                break
              end # end choice

              break if _tmp
              self.pos = _save14
              break
            end # end choice

            break unless _tmp
          end
          _tmp = true
        else
          self.pos = _save4
        end
        if _tmp
          text = get_text(_text_start)
        end
        unless _tmp
          self.pos = _save3
          break
        end
        @result = begin; n(p, :text, text); end
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

    set_failed_rule :_mstr_inner unless _tmp
    return _tmp
  end

  # escape = (number_escapes | escapes)
  def _escape

    _save = self.pos
    while true # choice
      _tmp = apply(:_number_escapes)
      break if _tmp
      self.pos = _save
      _tmp = apply(:_escapes)
      break if _tmp
      self.pos = _save
      break
    end # end choice

    set_failed_rule :_escape unless _tmp
    return _tmp
  end

  # escapes = ("n" { "\n" } | "s" { " " } | "r" { "\r" } | "t" { "\t" } | "v" { "\v" } | "f" { "\f" } | "b" { "\b" } | "a" { "\a" } | "e" { "\e" } | "\\" { "\\" } | "\"" { "\"" } | "BS" { "\b" } | "HT" { "\t" } | "LF" { "\n" } | "VT" { "\v" } | "FF" { "\f" } | "CR" { "\r" } | "SO" { "\016" } | "SI" { "\017" } | "EM" { "\031" } | "FS" { "\034" } | "GS" { "\035" } | "RS" { "\036" } | "US" { "\037" } | "SP" { " " } | "NUL" { "\000" } | "SOH" { "\001" } | "STX" { "\002" } | "ETX" { "\003" } | "EOT" { "\004" } | "ENQ" { "\005" } | "ACK" { "\006" } | "BEL" { "\a" } | "DLE" { "\020" } | "DC1" { "\021" } | "DC2" { "\022" } | "DC3" { "\023" } | "DC4" { "\024" } | "NAK" { "\025" } | "SYN" { "\026" } | "ETB" { "\027" } | "CAN" { "\030" } | "SUB" { "\032" } | "ESC" { "\e" } | "DEL" { "\177" } | < . > { "\\" + text })
  def _escapes

    _save = self.pos
    while true # choice

      _save1 = self.pos
      while true # sequence
        _tmp = match_string("n")
        unless _tmp
          self.pos = _save1
          break
        end
        @result = begin;  "\n" ; end
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
        _tmp = match_string("s")
        unless _tmp
          self.pos = _save2
          break
        end
        @result = begin;  " " ; end
        _tmp = true
        unless _tmp
          self.pos = _save2
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save

      _save3 = self.pos
      while true # sequence
        _tmp = match_string("r")
        unless _tmp
          self.pos = _save3
          break
        end
        @result = begin;  "\r" ; end
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
        _tmp = match_string("t")
        unless _tmp
          self.pos = _save4
          break
        end
        @result = begin;  "\t" ; end
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
        _tmp = match_string("v")
        unless _tmp
          self.pos = _save5
          break
        end
        @result = begin;  "\v" ; end
        _tmp = true
        unless _tmp
          self.pos = _save5
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save

      _save6 = self.pos
      while true # sequence
        _tmp = match_string("f")
        unless _tmp
          self.pos = _save6
          break
        end
        @result = begin;  "\f" ; end
        _tmp = true
        unless _tmp
          self.pos = _save6
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save

      _save7 = self.pos
      while true # sequence
        _tmp = match_string("b")
        unless _tmp
          self.pos = _save7
          break
        end
        @result = begin;  "\b" ; end
        _tmp = true
        unless _tmp
          self.pos = _save7
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save

      _save8 = self.pos
      while true # sequence
        _tmp = match_string("a")
        unless _tmp
          self.pos = _save8
          break
        end
        @result = begin;  "\a" ; end
        _tmp = true
        unless _tmp
          self.pos = _save8
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save

      _save9 = self.pos
      while true # sequence
        _tmp = match_string("e")
        unless _tmp
          self.pos = _save9
          break
        end
        @result = begin;  "\e" ; end
        _tmp = true
        unless _tmp
          self.pos = _save9
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save

      _save10 = self.pos
      while true # sequence
        _tmp = match_string("\\")
        unless _tmp
          self.pos = _save10
          break
        end
        @result = begin;  "\\" ; end
        _tmp = true
        unless _tmp
          self.pos = _save10
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save

      _save11 = self.pos
      while true # sequence
        _tmp = match_string("\"")
        unless _tmp
          self.pos = _save11
          break
        end
        @result = begin;  "\"" ; end
        _tmp = true
        unless _tmp
          self.pos = _save11
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save

      _save12 = self.pos
      while true # sequence
        _tmp = match_string("BS")
        unless _tmp
          self.pos = _save12
          break
        end
        @result = begin;  "\b" ; end
        _tmp = true
        unless _tmp
          self.pos = _save12
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save

      _save13 = self.pos
      while true # sequence
        _tmp = match_string("HT")
        unless _tmp
          self.pos = _save13
          break
        end
        @result = begin;  "\t" ; end
        _tmp = true
        unless _tmp
          self.pos = _save13
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save

      _save14 = self.pos
      while true # sequence
        _tmp = match_string("LF")
        unless _tmp
          self.pos = _save14
          break
        end
        @result = begin;  "\n" ; end
        _tmp = true
        unless _tmp
          self.pos = _save14
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save

      _save15 = self.pos
      while true # sequence
        _tmp = match_string("VT")
        unless _tmp
          self.pos = _save15
          break
        end
        @result = begin;  "\v" ; end
        _tmp = true
        unless _tmp
          self.pos = _save15
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save

      _save16 = self.pos
      while true # sequence
        _tmp = match_string("FF")
        unless _tmp
          self.pos = _save16
          break
        end
        @result = begin;  "\f" ; end
        _tmp = true
        unless _tmp
          self.pos = _save16
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save

      _save17 = self.pos
      while true # sequence
        _tmp = match_string("CR")
        unless _tmp
          self.pos = _save17
          break
        end
        @result = begin;  "\r" ; end
        _tmp = true
        unless _tmp
          self.pos = _save17
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save

      _save18 = self.pos
      while true # sequence
        _tmp = match_string("SO")
        unless _tmp
          self.pos = _save18
          break
        end
        @result = begin;  "\016" ; end
        _tmp = true
        unless _tmp
          self.pos = _save18
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save

      _save19 = self.pos
      while true # sequence
        _tmp = match_string("SI")
        unless _tmp
          self.pos = _save19
          break
        end
        @result = begin;  "\017" ; end
        _tmp = true
        unless _tmp
          self.pos = _save19
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save

      _save20 = self.pos
      while true # sequence
        _tmp = match_string("EM")
        unless _tmp
          self.pos = _save20
          break
        end
        @result = begin;  "\031" ; end
        _tmp = true
        unless _tmp
          self.pos = _save20
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save

      _save21 = self.pos
      while true # sequence
        _tmp = match_string("FS")
        unless _tmp
          self.pos = _save21
          break
        end
        @result = begin;  "\034" ; end
        _tmp = true
        unless _tmp
          self.pos = _save21
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save

      _save22 = self.pos
      while true # sequence
        _tmp = match_string("GS")
        unless _tmp
          self.pos = _save22
          break
        end
        @result = begin;  "\035" ; end
        _tmp = true
        unless _tmp
          self.pos = _save22
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save

      _save23 = self.pos
      while true # sequence
        _tmp = match_string("RS")
        unless _tmp
          self.pos = _save23
          break
        end
        @result = begin;  "\036" ; end
        _tmp = true
        unless _tmp
          self.pos = _save23
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save

      _save24 = self.pos
      while true # sequence
        _tmp = match_string("US")
        unless _tmp
          self.pos = _save24
          break
        end
        @result = begin;  "\037" ; end
        _tmp = true
        unless _tmp
          self.pos = _save24
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save

      _save25 = self.pos
      while true # sequence
        _tmp = match_string("SP")
        unless _tmp
          self.pos = _save25
          break
        end
        @result = begin;  " " ; end
        _tmp = true
        unless _tmp
          self.pos = _save25
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save

      _save26 = self.pos
      while true # sequence
        _tmp = match_string("NUL")
        unless _tmp
          self.pos = _save26
          break
        end
        @result = begin;  "\000" ; end
        _tmp = true
        unless _tmp
          self.pos = _save26
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save

      _save27 = self.pos
      while true # sequence
        _tmp = match_string("SOH")
        unless _tmp
          self.pos = _save27
          break
        end
        @result = begin;  "\001" ; end
        _tmp = true
        unless _tmp
          self.pos = _save27
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save

      _save28 = self.pos
      while true # sequence
        _tmp = match_string("STX")
        unless _tmp
          self.pos = _save28
          break
        end
        @result = begin;  "\002" ; end
        _tmp = true
        unless _tmp
          self.pos = _save28
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save

      _save29 = self.pos
      while true # sequence
        _tmp = match_string("ETX")
        unless _tmp
          self.pos = _save29
          break
        end
        @result = begin;  "\003" ; end
        _tmp = true
        unless _tmp
          self.pos = _save29
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save

      _save30 = self.pos
      while true # sequence
        _tmp = match_string("EOT")
        unless _tmp
          self.pos = _save30
          break
        end
        @result = begin;  "\004" ; end
        _tmp = true
        unless _tmp
          self.pos = _save30
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save

      _save31 = self.pos
      while true # sequence
        _tmp = match_string("ENQ")
        unless _tmp
          self.pos = _save31
          break
        end
        @result = begin;  "\005" ; end
        _tmp = true
        unless _tmp
          self.pos = _save31
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save

      _save32 = self.pos
      while true # sequence
        _tmp = match_string("ACK")
        unless _tmp
          self.pos = _save32
          break
        end
        @result = begin;  "\006" ; end
        _tmp = true
        unless _tmp
          self.pos = _save32
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save

      _save33 = self.pos
      while true # sequence
        _tmp = match_string("BEL")
        unless _tmp
          self.pos = _save33
          break
        end
        @result = begin;  "\a" ; end
        _tmp = true
        unless _tmp
          self.pos = _save33
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save

      _save34 = self.pos
      while true # sequence
        _tmp = match_string("DLE")
        unless _tmp
          self.pos = _save34
          break
        end
        @result = begin;  "\020" ; end
        _tmp = true
        unless _tmp
          self.pos = _save34
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save

      _save35 = self.pos
      while true # sequence
        _tmp = match_string("DC1")
        unless _tmp
          self.pos = _save35
          break
        end
        @result = begin;  "\021" ; end
        _tmp = true
        unless _tmp
          self.pos = _save35
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save

      _save36 = self.pos
      while true # sequence
        _tmp = match_string("DC2")
        unless _tmp
          self.pos = _save36
          break
        end
        @result = begin;  "\022" ; end
        _tmp = true
        unless _tmp
          self.pos = _save36
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save

      _save37 = self.pos
      while true # sequence
        _tmp = match_string("DC3")
        unless _tmp
          self.pos = _save37
          break
        end
        @result = begin;  "\023" ; end
        _tmp = true
        unless _tmp
          self.pos = _save37
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save

      _save38 = self.pos
      while true # sequence
        _tmp = match_string("DC4")
        unless _tmp
          self.pos = _save38
          break
        end
        @result = begin;  "\024" ; end
        _tmp = true
        unless _tmp
          self.pos = _save38
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save

      _save39 = self.pos
      while true # sequence
        _tmp = match_string("NAK")
        unless _tmp
          self.pos = _save39
          break
        end
        @result = begin;  "\025" ; end
        _tmp = true
        unless _tmp
          self.pos = _save39
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save

      _save40 = self.pos
      while true # sequence
        _tmp = match_string("SYN")
        unless _tmp
          self.pos = _save40
          break
        end
        @result = begin;  "\026" ; end
        _tmp = true
        unless _tmp
          self.pos = _save40
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save

      _save41 = self.pos
      while true # sequence
        _tmp = match_string("ETB")
        unless _tmp
          self.pos = _save41
          break
        end
        @result = begin;  "\027" ; end
        _tmp = true
        unless _tmp
          self.pos = _save41
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save

      _save42 = self.pos
      while true # sequence
        _tmp = match_string("CAN")
        unless _tmp
          self.pos = _save42
          break
        end
        @result = begin;  "\030" ; end
        _tmp = true
        unless _tmp
          self.pos = _save42
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save

      _save43 = self.pos
      while true # sequence
        _tmp = match_string("SUB")
        unless _tmp
          self.pos = _save43
          break
        end
        @result = begin;  "\032" ; end
        _tmp = true
        unless _tmp
          self.pos = _save43
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save

      _save44 = self.pos
      while true # sequence
        _tmp = match_string("ESC")
        unless _tmp
          self.pos = _save44
          break
        end
        @result = begin;  "\e" ; end
        _tmp = true
        unless _tmp
          self.pos = _save44
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save

      _save45 = self.pos
      while true # sequence
        _tmp = match_string("DEL")
        unless _tmp
          self.pos = _save45
          break
        end
        @result = begin;  "\177" ; end
        _tmp = true
        unless _tmp
          self.pos = _save45
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save

      _save46 = self.pos
      while true # sequence
        _text_start = self.pos
        _tmp = get_byte
        if _tmp
          text = get_text(_text_start)
        end
        unless _tmp
          self.pos = _save46
          break
        end
        @result = begin;  "\\" + text ; end
        _tmp = true
        unless _tmp
          self.pos = _save46
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save
      break
    end # end choice

    set_failed_rule :_escapes unless _tmp
    return _tmp
  end

  # number_escapes = (/[xX]/ < /[0-9a-fA-F]{1,5}/ > { [text.to_i(16)].pack("U") } | < /\d{1,6}/ > { [text.to_i].pack("U") } | /[oO]/ < /[0-7]{1,7}/ > { [text.to_i(16)].pack("U") } | /[uU]/ < /[0-9a-fA-F]{4}/ > { [text.to_i(16)].pack("U") })
  def _number_escapes

    _save = self.pos
    while true # choice

      _save1 = self.pos
      while true # sequence
        _tmp = scan(/\A(?-mix:[xX])/)
        unless _tmp
          self.pos = _save1
          break
        end
        _text_start = self.pos
        _tmp = scan(/\A(?-mix:[0-9a-fA-F]{1,5})/)
        if _tmp
          text = get_text(_text_start)
        end
        unless _tmp
          self.pos = _save1
          break
        end
        @result = begin;  [text.to_i(16)].pack("U") ; end
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
        _text_start = self.pos
        _tmp = scan(/\A(?-mix:\d{1,6})/)
        if _tmp
          text = get_text(_text_start)
        end
        unless _tmp
          self.pos = _save2
          break
        end
        @result = begin;  [text.to_i].pack("U") ; end
        _tmp = true
        unless _tmp
          self.pos = _save2
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save

      _save3 = self.pos
      while true # sequence
        _tmp = scan(/\A(?-mix:[oO])/)
        unless _tmp
          self.pos = _save3
          break
        end
        _text_start = self.pos
        _tmp = scan(/\A(?-mix:[0-7]{1,7})/)
        if _tmp
          text = get_text(_text_start)
        end
        unless _tmp
          self.pos = _save3
          break
        end
        @result = begin;  [text.to_i(16)].pack("U") ; end
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
        _tmp = scan(/\A(?-mix:[uU])/)
        unless _tmp
          self.pos = _save4
          break
        end
        _text_start = self.pos
        _tmp = scan(/\A(?-mix:[0-9a-fA-F]{4})/)
        if _tmp
          text = get_text(_text_start)
        end
        unless _tmp
          self.pos = _save4
          break
        end
        @result = begin;  [text.to_i(16)].pack("U") ; end
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

    set_failed_rule :_number_escapes unless _tmp
    return _tmp
  end

  Rules = {}
  Rules[:_root] = rule_info("root", "- block(ctx)?:b - eof {b}")
  Rules[:_eof] = rule_info("eof", "!.")
  Rules[:_comment] = rule_info("comment", "/\#!.*?$/")
  Rules[:_nl] = rule_info("nl", "(\"\\n\" | \"\\n\")")
  Rules[:_ws] = rule_info("ws", "(\" \" | \"\\t\")")
  Rules[:_op] = rule_info("op", "/[\\~\\!@\\\#\\$%\\^\\&\\|\\?\\<\\>*\\/+=:-]/")
  Rules[:_p] = rule_info("p", "&. {current_position}")
  Rules[:__hyphen_] = rule_info("-", "(ws | nl | comment)*")
  Rules[:_s] = rule_info("s", "(ws | nl | comment | \";\")*")
  Rules[:_brace] = rule_info("brace", "< . > &{brace(text)} {brace(text)}")
  Rules[:_left_brace] = rule_info("left_brace", "< brace:b > &{ text == b.first} {b}")
  Rules[:_right_brace] = rule_info("right_brace", "< brace:b > &{ text == l.last } {l}")
  Rules[:_braced] = rule_info("braced", "left_brace:l - (braced_(ctx) | {nil}):a - right_brace(l) {[l] + Array(a)}")
  Rules[:_braced_] = rule_info("braced_", "(braced_(x):a - \",\" - block(x):b {a + Array(b)} | block(x):b {Array(b)})")
  Rules[:_block] = rule_info("block", "(block(x):a ws* nl - block(x):b &{a.pos.column < b.pos.column} { a.name == :chain && (a.args.push(b);a) || a.with(:chain, a, b) } | block_(x):b {b.size > 1 && n(b.first.pos, :block, *b) || b.first})")
  Rules[:_block_] = rule_info("block_", "(block_(x):b - \";\" s chain(x):c {Array(c)}:a {b + a} | block_(x):b s chain(x):c {Array(c)}:a &{b.first.pos.column == a.first.pos.column} {b + a} | chain(x):c {Array(c)})")
  Rules[:_chain] = rule_info("chain", "chain_(x):c {c.size > 1 && n(c.first.pos, :chain, *c) || c.first}")
  Rules[:_chain_] = rule_info("chain_", "(chain_(x):c - \".\" &{x.kmsg?} - chain_(x):v {c + v} | chain_(x):c &{c.last.name == :oper} (ws* nl -)? value(x.at(c.first.pos)):v {c + v} | chain_(x):c oper:o {c + [o]} | chain_(x):c ws+ value(x.at(c.first.pos)):v {c + v} | value(x))")
  Rules[:_value] = rule_info("value", "value_(x):v {Array(v)}:a &{a.first.pos.column > x.pos.column} {a}")
  Rules[:_value_] = rule_info("value_", "(&{x.kmsg?} kmsg(x) | value_(x):v p:p braced:b !(&\":\") {Array(v) + [n(p, :send, *b)]} | empty(x) | space | literal(x):a (&{x.kmsg?} | !(&\":\")) {a})")
  Rules[:_space] = rule_info("space", "p:p braced:a {n(p, :space, *a)}")
  Rules[:_empty] = rule_info("empty", "p:p braced:a \":\" ws* empty_(x):b {n(p, :empty, *(a+b))}")
  Rules[:_empty_] = rule_info("empty_", "(braced_(x) | {nil}):a (ws* nl - block(x) | {nil}):b {Array(a) + Array(b)}")
  Rules[:_name] = rule_info("name", "p:p < (!(&(ws | nl | brace | op | \":\" | \";\" | \",\" | \".\")) .)+ > {n(p, :name, text)}")
  Rules[:_oper] = rule_info("oper", "p:p < (\"..\" (op | \".\")* | op op*) > {n(p, :oper, text)}")
  Rules[:_keyargs] = rule_info("keyargs", "(keyargs_(x.kmsg!) | {nil}):a (ws* nl - braced_(x) | {nil}):b {Array(a) + Array(b)}")
  Rules[:_keyargs_] = rule_info("keyargs_", "(keyargs_(x):a ws* \",\" ws* chain(x):c {a + Array(c)} | chain(x):c {Array(c)})")
  Rules[:_keyw] = rule_info("keyw", "< (name | oper) > \":\" {[text, nil]}")
  Rules[:_keya] = rule_info("keya", "< (name | oper) > braced:a \":\" {[text] + a}")
  Rules[:_keyword] = rule_info("keyword", "(keyw(x) | keya(x))")
  Rules[:_part] = rule_info("part", "(p:p keyword(x):a &(ws* keyword(x)) {n(p, :part, *a)} | p:p keyword(x):a ws* \".\" - empty_(x):b {n(p, :part, *(a+b))} | p:p keyword(x):a ws* keyargs(x.in(x.pos.minor(p))):b {n(p, :part, *(a+b))})")
  Rules[:_parts] = rule_info("parts", "(parts(x):a - part(x):b {a + [b]} | part(x):a {[a]})")
  Rules[:_kmsg] = rule_info("kmsg", "parts(x):a {n(a.first.pos, :kmsg, *a)}")
  Rules[:_literal] = rule_info("literal", "(symbol(x) | infix | str | float | fixnum | regexp | name | oper)")
  Rules[:_symbol] = rule_info("symbol", "p:p \":\" !(&\":\") value(x.kmsg):v {n(p, :symbol, v.first)}")
  Rules[:_infix_] = rule_info("infix_", "(< \"\#\"+ > !(&(brace | \"!\")) {text.size} | {0})")
  Rules[:_infix] = rule_info("infix", "p:p infix_:l < (name | oper) > infix_:r &{ l+r > 0 } {n(p, :infix, text, l, r)}")
  Rules[:_regexp] = rule_info("regexp", "p:p quoted(:text, &\"/\"):b {n(p, :regexp, text_node(p, b))}")
  Rules[:_float] = rule_info("float", "p:p sign:s dec:n \".\" dec:f {n(p, :float, (s+n+\".\"+f).to_f)}")
  Rules[:_fixnum] = rule_info("fixnum", "p:p (hexadec | binary | octal | decimal):n {n(p, :fixnum, n)}")
  Rules[:_digits] = rule_info("digits", "< d+ (\"_\" d+)* > { text.gsub('_', '') }")
  Rules[:_sign] = rule_info("sign", "(\"+\" {\"+\"} | \"-\" { \"-\"} | {\"+\"})")
  Rules[:_dec] = rule_info("dec", "digits(&/[0-9]/):d {d}")
  Rules[:_oct] = rule_info("oct", "\"0\" /[oO]/? digits(&/[0-7]/):d {d}")
  Rules[:_hex] = rule_info("hex", "\"0\" /[xX]/ digits(&/[0-9a-fA-F]/):d {d}")
  Rules[:_bin] = rule_info("bin", "\"0\" /[bB]/ digits(&/[0-1]/):d {d}")
  Rules[:_hexadec] = rule_info("hexadec", "sign:s hex:d {(s+d).to_i(16)}")
  Rules[:_binary] = rule_info("binary", "sign:s bin:d {(s+d).to_i(2)}")
  Rules[:_octal] = rule_info("octal", "sign:s oct:d {(s+d).to_i(8)}")
  Rules[:_decimal] = rule_info("decimal", "sign:s dec:d {(s+d).to_i(10)}")
  Rules[:_str] = rule_info("str", "(mstr | sstr | qstr)")
  Rules[:_qstr] = rule_info("qstr", "p:p \"'\" < (\"\\\\\" escape | \"\\\\'\" | !(&\"'\") .)* > \"'\" {n(p, :text, text)}")
  Rules[:_sstr] = rule_info("sstr", "p:p quoted(:text, &\"\\\"\"):b {text_node(p, b)}")
  Rules[:_quoted] = rule_info("quoted", "q quoted_inner(t, q)*:b q {b}")
  Rules[:_quoted_inner] = rule_info("quoted_inner", "(p:p \"\#{\" - block(ctx)?:b - \"}\" {b} | p:p < (\"\\\\\" escape | (\"\\\\\" q | \"\\\\\#\" | &(!(q | \"\#{\")) .))+ > {n(p, t, text)})")
  Rules[:_mstr] = rule_info("mstr", "p:p \"\\\"\\\"\\\"\" mstr_inner*:b \"\\\"\\\"\\\"\" {text_node(p, b)}")
  Rules[:_mstr_inner] = rule_info("mstr_inner", "(p:p \"\#{\" - block(h)?:b - \"}\" {b} | p:p < (\"\\\\\" escape | (\"\\\\\\\"\\\"\\\"\" | !(&(\"\\\"\\\"\\\"\" | \"\#{\")) . | . &\"\\\"\\\"\\\"\"))+ > {n(p, :text, text)})")
  Rules[:_escape] = rule_info("escape", "(number_escapes | escapes)")
  Rules[:_escapes] = rule_info("escapes", "(\"n\" { \"\\n\" } | \"s\" { \" \" } | \"r\" { \"\\r\" } | \"t\" { \"\\t\" } | \"v\" { \"\\v\" } | \"f\" { \"\\f\" } | \"b\" { \"\\b\" } | \"a\" { \"\\a\" } | \"e\" { \"\\e\" } | \"\\\\\" { \"\\\\\" } | \"\\\"\" { \"\\\"\" } | \"BS\" { \"\\b\" } | \"HT\" { \"\\t\" } | \"LF\" { \"\\n\" } | \"VT\" { \"\\v\" } | \"FF\" { \"\\f\" } | \"CR\" { \"\\r\" } | \"SO\" { \"\\016\" } | \"SI\" { \"\\017\" } | \"EM\" { \"\\031\" } | \"FS\" { \"\\034\" } | \"GS\" { \"\\035\" } | \"RS\" { \"\\036\" } | \"US\" { \"\\037\" } | \"SP\" { \" \" } | \"NUL\" { \"\\000\" } | \"SOH\" { \"\\001\" } | \"STX\" { \"\\002\" } | \"ETX\" { \"\\003\" } | \"EOT\" { \"\\004\" } | \"ENQ\" { \"\\005\" } | \"ACK\" { \"\\006\" } | \"BEL\" { \"\\a\" } | \"DLE\" { \"\\020\" } | \"DC1\" { \"\\021\" } | \"DC2\" { \"\\022\" } | \"DC3\" { \"\\023\" } | \"DC4\" { \"\\024\" } | \"NAK\" { \"\\025\" } | \"SYN\" { \"\\026\" } | \"ETB\" { \"\\027\" } | \"CAN\" { \"\\030\" } | \"SUB\" { \"\\032\" } | \"ESC\" { \"\\e\" } | \"DEL\" { \"\\177\" } | < . > { \"\\\\\" + text })")
  Rules[:_number_escapes] = rule_info("number_escapes", "(/[xX]/ < /[0-9a-fA-F]{1,5}/ > { [text.to_i(16)].pack(\"U\") } | < /\\d{1,6}/ > { [text.to_i].pack(\"U\") } | /[oO]/ < /[0-7]{1,7}/ > { [text.to_i(16)].pack(\"U\") } | /[uU]/ < /[0-9a-fA-F]{4}/ > { [text.to_i(16)].pack(\"U\") })")
end
