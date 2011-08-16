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

  # w = (sp | sheebang | nl)*
  def _w
    while true

      _save1 = self.pos
      while true # choice
        _tmp = apply(:_sp)
        break if _tmp
        self.pos = _save1
        _tmp = apply(:_sheebang)
        break if _tmp
        self.pos = _save1
        _tmp = apply(:_nl)
        break if _tmp
        self.pos = _save1
        break
      end # end choice

      break unless _tmp
    end
    _tmp = true
    set_failed_rule :_w unless _tmp
    return _tmp
  end

  # o = sp* (sheebang | nl)
  def _o

    _save = self.pos
    while true # sequence
      while true
        _tmp = apply(:_sp)
        break unless _tmp
      end
      _tmp = true
      unless _tmp
        self.pos = _save
        break
      end

      _save2 = self.pos
      while true # choice
        _tmp = apply(:_sheebang)
        break if _tmp
        self.pos = _save2
        _tmp = apply(:_nl)
        break if _tmp
        self.pos = _save2
        break
      end # end choice

      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_o unless _tmp
    return _tmp
  end

  # t = (";" | sheebang | nl)
  def _t

    _save = self.pos
    while true # choice
      _tmp = match_string(";")
      break if _tmp
      self.pos = _save
      _tmp = apply(:_sheebang)
      break if _tmp
      self.pos = _save
      _tmp = apply(:_nl)
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

  # literal = (float | fixnum | str | regexp)
  def _literal

    _save = self.pos
    while true # choice
      _tmp = apply(:_float)
      break if _tmp
      self.pos = _save
      _tmp = apply(:_fixnum)
      break if _tmp
      self.pos = _save
      _tmp = apply(:_str)
      break if _tmp
      self.pos = _save
      _tmp = apply(:_regexp)
      break if _tmp
      self.pos = _save
      break
    end # end choice

    set_failed_rule :_literal unless _tmp
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

  # qstr = p:p "'" < ("\\'" | !(&"'") .)* > "'" {n(p, :text, text)}
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
          _tmp = match_string("\\'")
          break if _tmp
          self.pos = _save2

          _save3 = self.pos
          while true # sequence
            _save4 = self.pos
            _save5 = self.pos
            _tmp = match_string("'")
            self.pos = _save5
            _tmp = _tmp ? nil : true
            self.pos = _save4
            unless _tmp
              self.pos = _save3
              break
            end
            _tmp = get_byte
            unless _tmp
              self.pos = _save3
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

  # quoted_inner = (p:p "#{" - block(h)?:b - "}" {b} | p:p < ("\\" q | "\\#" | &(!(q | "#{")) .)+ > {n(p, t, text)})
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
            _tmp = q.call()
            unless _tmp
              self.pos = _save6
            end
            break
          end # end sequence

          break if _tmp
          self.pos = _save5
          _tmp = match_string("\\#")
          break if _tmp
          self.pos = _save5

          _save7 = self.pos
          while true # sequence
            _save8 = self.pos
            _save9 = self.pos

            _save10 = self.pos
            while true # choice
              _tmp = q.call()
              break if _tmp
              self.pos = _save10
              _tmp = match_string("\#{")
              break if _tmp
              self.pos = _save10
              break
            end # end choice

            _tmp = _tmp ? nil : true
            self.pos = _save9
            self.pos = _save8
            unless _tmp
              self.pos = _save7
              break
            end
            _tmp = get_byte
            unless _tmp
              self.pos = _save7
            end
            break
          end # end sequence

          break if _tmp
          self.pos = _save5
          break
        end # end choice

        if _tmp
          while true

            _save11 = self.pos
            while true # choice

              _save12 = self.pos
              while true # sequence
                _tmp = match_string("\\")
                unless _tmp
                  self.pos = _save12
                  break
                end
                _tmp = q.call()
                unless _tmp
                  self.pos = _save12
                end
                break
              end # end sequence

              break if _tmp
              self.pos = _save11
              _tmp = match_string("\\#")
              break if _tmp
              self.pos = _save11

              _save13 = self.pos
              while true # sequence
                _save14 = self.pos
                _save15 = self.pos

                _save16 = self.pos
                while true # choice
                  _tmp = q.call()
                  break if _tmp
                  self.pos = _save16
                  _tmp = match_string("\#{")
                  break if _tmp
                  self.pos = _save16
                  break
                end # end choice

                _tmp = _tmp ? nil : true
                self.pos = _save15
                self.pos = _save14
                unless _tmp
                  self.pos = _save13
                  break
                end
                _tmp = get_byte
                unless _tmp
                  self.pos = _save13
                end
                break
              end # end sequence

              break if _tmp
              self.pos = _save11
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

  # mstr_inner = (p:p "#{" - block(h)?:b - "}" {b} | p:p < ("\\\"\"\"" | !(&("\"\"\"" | "#{")) . | . &"\"\"\"")+ > {n(p, :text, text)})
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
          _tmp = match_string("\\\"\"\"")
          break if _tmp
          self.pos = _save5

          _save6 = self.pos
          while true # sequence
            _save7 = self.pos
            _save8 = self.pos

            _save9 = self.pos
            while true # choice
              _tmp = match_string("\"\"\"")
              break if _tmp
              self.pos = _save9
              _tmp = match_string("\#{")
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

          break if _tmp
          self.pos = _save5

          _save10 = self.pos
          while true # sequence
            _tmp = get_byte
            unless _tmp
              self.pos = _save10
              break
            end
            _save11 = self.pos
            _tmp = match_string("\"\"\"")
            self.pos = _save11
            unless _tmp
              self.pos = _save10
            end
            break
          end # end sequence

          break if _tmp
          self.pos = _save5
          break
        end # end choice

        if _tmp
          while true

            _save12 = self.pos
            while true # choice
              _tmp = match_string("\\\"\"\"")
              break if _tmp
              self.pos = _save12

              _save13 = self.pos
              while true # sequence
                _save14 = self.pos
                _save15 = self.pos

                _save16 = self.pos
                while true # choice
                  _tmp = match_string("\"\"\"")
                  break if _tmp
                  self.pos = _save16
                  _tmp = match_string("\#{")
                  break if _tmp
                  self.pos = _save16
                  break
                end # end choice

                self.pos = _save15
                _tmp = _tmp ? nil : true
                self.pos = _save14
                unless _tmp
                  self.pos = _save13
                  break
                end
                _tmp = get_byte
                unless _tmp
                  self.pos = _save13
                end
                break
              end # end sequence

              break if _tmp
              self.pos = _save12

              _save17 = self.pos
              while true # sequence
                _tmp = get_byte
                unless _tmp
                  self.pos = _save17
                  break
                end
                _save18 = self.pos
                _tmp = match_string("\"\"\"")
                self.pos = _save18
                unless _tmp
                  self.pos = _save17
                end
                break
              end # end sequence

              break if _tmp
              self.pos = _save12
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

  # opchr = /[\~\!@\#\$%\^\&\|\?\<\>*\/+-]/
  def _opchr
    _tmp = scan(/\A(?-mix:[\~\!@\#\$%\^\&\|\?\<\>*\/+-])/)
    set_failed_rule :_opchr unless _tmp
    return _tmp
  end

  # oper = < opchr (opchr | /[=]/)* > {text}
  def _oper

    _save = self.pos
    while true # sequence
      _text_start = self.pos

      _save1 = self.pos
      while true # sequence
        _tmp = apply(:_opchr)
        unless _tmp
          self.pos = _save1
          break
        end
        while true

          _save3 = self.pos
          while true # choice
            _tmp = apply(:_opchr)
            break if _tmp
            self.pos = _save3
            _tmp = scan(/\A(?-mix:[=])/)
            break if _tmp
            self.pos = _save3
            break
          end # end choice

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

    set_failed_rule :_oper unless _tmp
    return _tmp
  end

  # operator = p:p oper:o {n(p, :oper, o)}
  def _operator

    _save = self.pos
    while true # sequence
      _tmp = apply(:_p)
      p = @result
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = apply(:_oper)
      o = @result
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin; n(p, :oper, o); end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_operator unless _tmp
    return _tmp
  end

  # name = p:p < (&(!(sp | nl | brace | opchr | ":" | ";" | "," | ".")) .)+ > {n(p, :name, text)}
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
          _tmp = apply(:_sp)
          break if _tmp
          self.pos = _save5
          _tmp = apply(:_nl)
          break if _tmp
          self.pos = _save5
          _tmp = apply(:_brace)
          break if _tmp
          self.pos = _save5
          _tmp = apply(:_opchr)
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

        _tmp = _tmp ? nil : true
        self.pos = _save4
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
              _tmp = apply(:_sp)
              break if _tmp
              self.pos = _save9
              _tmp = apply(:_nl)
              break if _tmp
              self.pos = _save9
              _tmp = apply(:_brace)
              break if _tmp
              self.pos = _save9
              _tmp = apply(:_opchr)
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

            _tmp = _tmp ? nil : true
            self.pos = _save8
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

  # keyword = ":" < (!(&(n | ":" | brace)) .)+ > !(&(":" | ";" | ".")) &{text.size > 0} {text}
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
          _tmp = apply(:_brace)
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
              _tmp = apply(:_brace)
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

      _save12 = self.pos
      while true # choice
        _tmp = match_string(":")
        break if _tmp
        self.pos = _save12
        _tmp = match_string(";")
        break if _tmp
        self.pos = _save12
        _tmp = match_string(".")
        break if _tmp
        self.pos = _save12
        break
      end # end choice

      self.pos = _save11
      _tmp = _tmp ? nil : true
      self.pos = _save10
      unless _tmp
        self.pos = _save
        break
      end
      _save13 = self.pos
      _tmp = begin; text.size > 0; end
      self.pos = _save13
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

  # value = (msg(h) | value(h):v args:a {n(v.pos, :act, v, a.name, *a.args)} | args:a {n(a.pos, :act, nil, a.name, *a.args)} | literal | operator | name)
  def _value(h)

    _save = self.pos
    while true # choice
      _tmp = apply_with_args(:_msg, h)
      break if _tmp
      self.pos = _save

      _save1 = self.pos
      while true # sequence
        _tmp = apply_with_args(:_value, h)
        v = @result
        unless _tmp
          self.pos = _save1
          break
        end
        _tmp = apply(:_args)
        a = @result
        unless _tmp
          self.pos = _save1
          break
        end
        @result = begin; n(v.pos, :act, v, a.name, *a.args); end
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
        _tmp = apply(:_args)
        a = @result
        unless _tmp
          self.pos = _save2
          break
        end
        @result = begin; n(a.pos, :act, nil, a.name, *a.args); end
        _tmp = true
        unless _tmp
          self.pos = _save2
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save
      _tmp = apply(:_literal)
      break if _tmp
      self.pos = _save
      _tmp = apply(:_operator)
      break if _tmp
      self.pos = _save
      _tmp = apply(:_name)
      break if _tmp
      self.pos = _save
      break
    end # end choice

    set_failed_rule :_value unless _tmp
    return _tmp
  end

  # comma_left = block(h):a w "," {a}
  def _comma_left(h)

    _save = self.pos
    while true # sequence
      _tmp = apply_with_args(:_block, h)
      a = @result
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = apply(:_w)
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = match_string(",")
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

    set_failed_rule :_comma_left unless _tmp
    return _tmp
  end

  # comma = (comma_left(h):a w comma(h):b { b.unshift a ; b } | comma_left(h):a w block(h):b { [a,b] } | comma_left(h):a &(sp* ("." | "," | t | brace)) {[a]})
  def _comma(h)

    _save = self.pos
    while true # choice

      _save1 = self.pos
      while true # sequence
        _tmp = apply_with_args(:_comma_left, h)
        a = @result
        unless _tmp
          self.pos = _save1
          break
        end
        _tmp = apply(:_w)
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

      _save2 = self.pos
      while true # sequence
        _tmp = apply_with_args(:_comma_left, h)
        a = @result
        unless _tmp
          self.pos = _save2
          break
        end
        _tmp = apply(:_w)
        unless _tmp
          self.pos = _save2
          break
        end
        _tmp = apply_with_args(:_block, h)
        b = @result
        unless _tmp
          self.pos = _save2
          break
        end
        @result = begin;  [a,b] ; end
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
        _tmp = apply_with_args(:_comma_left, h)
        a = @result
        unless _tmp
          self.pos = _save3
          break
        end
        _save4 = self.pos

        _save5 = self.pos
        while true # sequence
          while true
            _tmp = apply(:_sp)
            break unless _tmp
          end
          _tmp = true
          unless _tmp
            self.pos = _save5
            break
          end

          _save7 = self.pos
          while true # choice
            _tmp = match_string(".")
            break if _tmp
            self.pos = _save7
            _tmp = match_string(",")
            break if _tmp
            self.pos = _save7
            _tmp = apply(:_t)
            break if _tmp
            self.pos = _save7
            _tmp = apply(:_brace)
            break if _tmp
            self.pos = _save7
            break
          end # end choice

          unless _tmp
            self.pos = _save5
          end
          break
        end # end sequence

        self.pos = _save4
        unless _tmp
          self.pos = _save3
          break
        end
        @result = begin; [a]; end
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

  # cons_left = expr(h):a sp* ":" !(&(":" | ";" | ".")) {a}
  def _cons_left(h)

    _save = self.pos
    while true # sequence
      _tmp = apply_with_args(:_expr, h)
      a = @result
      unless _tmp
        self.pos = _save
        break
      end
      while true
        _tmp = apply(:_sp)
        break unless _tmp
      end
      _tmp = true
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = match_string(":")
      unless _tmp
        self.pos = _save
        break
      end
      _save2 = self.pos
      _save3 = self.pos

      _save4 = self.pos
      while true # choice
        _tmp = match_string(":")
        break if _tmp
        self.pos = _save4
        _tmp = match_string(";")
        break if _tmp
        self.pos = _save4
        _tmp = match_string(".")
        break if _tmp
        self.pos = _save4
        break
      end # end choice

      self.pos = _save3
      _tmp = _tmp ? nil : true
      self.pos = _save2
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

    set_failed_rule :_cons_left unless _tmp
    return _tmp
  end

  # cons = (cons_left(h):a - cons(h):b {n(p, :cons, a, b)} | cons_left(h):a - expr(h):b {n(p, :cons, a, b)})
  def _cons(h)

    _save = self.pos
    while true # choice

      _save1 = self.pos
      while true # sequence
        _tmp = apply_with_args(:_cons_left, h)
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

      _save2 = self.pos
      while true # sequence
        _tmp = apply_with_args(:_cons_left, h)
        a = @result
        unless _tmp
          self.pos = _save2
          break
        end
        _tmp = apply(:__hyphen_)
        unless _tmp
          self.pos = _save2
          break
        end
        _tmp = apply_with_args(:_expr, h)
        b = @result
        unless _tmp
          self.pos = _save2
          break
        end
        @result = begin; n(p, :cons, a, b); end
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

  # msg = (msg(h):a sp* ":" &(":" | ";" | ".") {a} | part(h):a w msg(h | a.pos):m {n(a.pos, :msg, a, *m.args)} | part(h):a {n(a.pos, :msg, a)})
  def _msg(h)

    _save = self.pos
    while true # choice

      _save1 = self.pos
      while true # sequence
        _tmp = apply_with_args(:_msg, h)
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
        _save3 = self.pos

        _save4 = self.pos
        while true # choice
          _tmp = match_string(":")
          break if _tmp
          self.pos = _save4
          _tmp = match_string(";")
          break if _tmp
          self.pos = _save4
          _tmp = match_string(".")
          break if _tmp
          self.pos = _save4
          break
        end # end choice

        self.pos = _save3
        unless _tmp
          self.pos = _save1
          break
        end
        @result = begin; a; end
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
        _tmp = apply_with_args(:_part, h)
        a = @result
        unless _tmp
          self.pos = _save5
          break
        end
        _tmp = apply(:_w)
        unless _tmp
          self.pos = _save5
          break
        end
        _tmp = apply_with_args(:_msg, h | a.pos)
        m = @result
        unless _tmp
          self.pos = _save5
          break
        end
        @result = begin; n(a.pos, :msg, a, *m.args); end
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
        _tmp = apply_with_args(:_part, h)
        a = @result
        unless _tmp
          self.pos = _save6
          break
        end
        @result = begin; n(a.pos, :msg, a); end
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

    set_failed_rule :_msg unless _tmp
    return _tmp
  end

  # part = (part(h):p o w block(h | p.pos):e { p.args.push *Array(e) ; p } | part(h):p part_head(h | p.pos):e { p.args.push *Array(e) ; p } | p:p keyword:k args:a {n(p, k, a.name, *a.args)} | p:p keyword:k {n(p, k, "()")})
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
        _tmp = apply(:_o)
        unless _tmp
          self.pos = _save1
          break
        end
        _tmp = apply(:_w)
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

      _save2 = self.pos
      while true # sequence
        _tmp = apply_with_args(:_part, h)
        p = @result
        unless _tmp
          self.pos = _save2
          break
        end
        _tmp = apply_with_args(:_part_head, h | p.pos)
        e = @result
        unless _tmp
          self.pos = _save2
          break
        end
        @result = begin;  p.args.push *Array(e) ; p ; end
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
        _tmp = apply(:_p)
        p = @result
        unless _tmp
          self.pos = _save3
          break
        end
        _tmp = apply(:_keyword)
        k = @result
        unless _tmp
          self.pos = _save3
          break
        end
        _tmp = apply(:_args)
        a = @result
        unless _tmp
          self.pos = _save3
          break
        end
        @result = begin; n(p, k, a.name, *a.args); end
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
        @result = begin; n(p, k, "()"); end
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

  # ph_comma = (expr(h):a w "," - ph_comma(h):b { b.unshift a ; b } | expr(h):a w "," - expr(h):b { [a,b] })
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
        _tmp = apply(:_w)
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

      _save2 = self.pos
      while true # sequence
        _tmp = apply_with_args(:_expr, h)
        a = @result
        unless _tmp
          self.pos = _save2
          break
        end
        _tmp = apply(:_w)
        unless _tmp
          self.pos = _save2
          break
        end
        _tmp = match_string(",")
        unless _tmp
          self.pos = _save2
          break
        end
        _tmp = apply(:__hyphen_)
        unless _tmp
          self.pos = _save2
          break
        end
        _tmp = apply_with_args(:_expr, h)
        b = @result
        unless _tmp
          self.pos = _save2
          break
        end
        @result = begin;  [a,b] ; end
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

    set_failed_rule :_ph_comma unless _tmp
    return _tmp
  end

  # expr = value(h):e &{ e.pos.column > h.column } {e}
  def _expr(h)

    _save = self.pos
    while true # sequence
      _tmp = apply_with_args(:_value, h)
      e = @result
      unless _tmp
        self.pos = _save
        break
      end
      _save1 = self.pos
      _tmp = begin;  e.pos.column > h.column ; end
      self.pos = _save1
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

    set_failed_rule :_expr unless _tmp
    return _tmp
  end

  # chain = (chain(h):a sp* "." - chain(h)?:b { b && n(a.pos, :chain, a, b) || a } | operator:a !(&brace) o w chain(h):b {n(a.pos, :chain, a, *Array(b.name == :chain && b.args || b))} | chain_cont(h) | expr(h):a sp* chain(a.pos):b {n(a.pos, :chain, a, *Array(b.name == :chain && b.args || b))} | chain_val(h))
  def _chain(h)

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
        _tmp = match_string(".")
        unless _tmp
          self.pos = _save1
          break
        end
        _tmp = apply(:__hyphen_)
        unless _tmp
          self.pos = _save1
          break
        end
        _save3 = self.pos
        _tmp = apply_with_args(:_chain, h)
        @result = nil unless _tmp
        unless _tmp
          _tmp = true
          self.pos = _save3
        end
        b = @result
        unless _tmp
          self.pos = _save1
          break
        end
        @result = begin;  b && n(a.pos, :chain, a, b) || a ; end
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
        _tmp = apply(:_operator)
        a = @result
        unless _tmp
          self.pos = _save4
          break
        end
        _save5 = self.pos
        _save6 = self.pos
        _tmp = apply(:_brace)
        self.pos = _save6
        _tmp = _tmp ? nil : true
        self.pos = _save5
        unless _tmp
          self.pos = _save4
          break
        end
        _tmp = apply(:_o)
        unless _tmp
          self.pos = _save4
          break
        end
        _tmp = apply(:_w)
        unless _tmp
          self.pos = _save4
          break
        end
        _tmp = apply_with_args(:_chain, h)
        b = @result
        unless _tmp
          self.pos = _save4
          break
        end
        @result = begin; n(a.pos, :chain, a, *Array(b.name == :chain && b.args || b)); end
        _tmp = true
        unless _tmp
          self.pos = _save4
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save
      _tmp = apply_with_args(:_chain_cont, h)
      break if _tmp
      self.pos = _save

      _save7 = self.pos
      while true # sequence
        _tmp = apply_with_args(:_expr, h)
        a = @result
        unless _tmp
          self.pos = _save7
          break
        end
        while true
          _tmp = apply(:_sp)
          break unless _tmp
        end
        _tmp = true
        unless _tmp
          self.pos = _save7
          break
        end
        _tmp = apply_with_args(:_chain, a.pos)
        b = @result
        unless _tmp
          self.pos = _save7
          break
        end
        @result = begin; n(a.pos, :chain, a, *Array(b.name == :chain && b.args || b)); end
        _tmp = true
        unless _tmp
          self.pos = _save7
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save
      _tmp = apply_with_args(:_chain_val, h)
      break if _tmp
      self.pos = _save
      break
    end # end choice

    set_failed_rule :_chain unless _tmp
    return _tmp
  end

  # chain_cont = chain_val(h):a {(h | a.pos || h()).incr}:i sp* (comma(h) | (nl | sheebang) - block(i)):c {                 if a.name == :act                    a.args.push *Array(c); a                 else                    n(a.pos, :act, a, "()", *Array(c))                 end               }
  def _chain_cont(h)

    _save = self.pos
    while true # sequence
      _tmp = apply_with_args(:_chain_val, h)
      a = @result
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin; (h | a.pos || h()).incr; end
      _tmp = true
      i = @result
      unless _tmp
        self.pos = _save
        break
      end
      while true
        _tmp = apply(:_sp)
        break unless _tmp
      end
      _tmp = true
      unless _tmp
        self.pos = _save
        break
      end

      _save2 = self.pos
      while true # choice
        _tmp = apply_with_args(:_comma, h)
        break if _tmp
        self.pos = _save2

        _save3 = self.pos
        while true # sequence

          _save4 = self.pos
          while true # choice
            _tmp = apply(:_nl)
            break if _tmp
            self.pos = _save4
            _tmp = apply(:_sheebang)
            break if _tmp
            self.pos = _save4
            break
          end # end choice

          unless _tmp
            self.pos = _save3
            break
          end
          _tmp = apply(:__hyphen_)
          unless _tmp
            self.pos = _save3
            break
          end
          _tmp = apply_with_args(:_block, i)
          unless _tmp
            self.pos = _save3
          end
          break
        end # end sequence

        break if _tmp
        self.pos = _save2
        break
      end # end choice

      c = @result
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin; 
                if a.name == :act
                   a.args.push *Array(c); a
                else
                   n(a.pos, :act, a, "()", *Array(c))
                end
              ; end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    set_failed_rule :_chain_cont unless _tmp
    return _tmp
  end

  # chain_val = (cons(h) | expr(h))
  def _chain_val(h)

    _save = self.pos
    while true # choice
      _tmp = apply_with_args(:_cons, h)
      break if _tmp
      self.pos = _save
      _tmp = apply_with_args(:_expr, h)
      break if _tmp
      self.pos = _save
      break
    end # end choice

    set_failed_rule :_chain_val unless _tmp
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

  # root = - block(h)?:b - eof {b}
  def _root

    _save = self.pos
    while true # sequence
      _tmp = apply(:__hyphen_)
      unless _tmp
        self.pos = _save
        break
      end
      _save1 = self.pos
      _tmp = apply_with_args(:_block, h)
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

  # unit = - chain(h):c {c}
  def _unit

    _save = self.pos
    while true # sequence
      _tmp = apply(:__hyphen_)
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = apply_with_args(:_chain, h)
      c = @result
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin; c; end
      _tmp = true
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
  Rules[:_w] = rule_info("w", "(sp | sheebang | nl)*")
  Rules[:_o] = rule_info("o", "sp* (sheebang | nl)")
  Rules[:_t] = rule_info("t", "(\";\" | sheebang | nl)")
  Rules[:_n] = rule_info("n", "(t | sp | \".\")")
  Rules[:__hyphen_] = rule_info("-", "n*")
  Rules[:_brace] = rule_info("brace", "(< . . > &{ brace(text) } { brace(text) } | < . > &{ brace(text) } { brace(text) })")
  Rules[:_left_brace] = rule_info("left_brace", "< brace:b > &{ text == b.first} { b }")
  Rules[:_right_brace] = rule_info("right_brace", "< brace:b > &{ text == l.last } { l }")
  Rules[:_literal] = rule_info("literal", "(float | fixnum | str | regexp)")
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
  Rules[:_qstr] = rule_info("qstr", "p:p \"'\" < (\"\\\\'\" | !(&\"'\") .)* > \"'\" {n(p, :text, text)}")
  Rules[:_sstr] = rule_info("sstr", "p:p quoted(:text, &\"\\\"\"):b {text_node(p, b)}")
  Rules[:_quoted] = rule_info("quoted", "q quoted_inner(t, q)*:b q {b}")
  Rules[:_quoted_inner] = rule_info("quoted_inner", "(p:p \"\#{\" - block(h)?:b - \"}\" {b} | p:p < (\"\\\\\" q | \"\\\\\#\" | &(!(q | \"\#{\")) .)+ > {n(p, t, text)})")
  Rules[:_mstr] = rule_info("mstr", "p:p \"\\\"\\\"\\\"\" mstr_inner*:b \"\\\"\\\"\\\"\" {text_node(p, b)}")
  Rules[:_mstr_inner] = rule_info("mstr_inner", "(p:p \"\#{\" - block(h)?:b - \"}\" {b} | p:p < (\"\\\\\\\"\\\"\\\"\" | !(&(\"\\\"\\\"\\\"\" | \"\#{\")) . | . &\"\\\"\\\"\\\"\")+ > {n(p, :text, text)})")
  Rules[:_opchr] = rule_info("opchr", "/[\\~\\!@\\\#\\$%\\^\\&\\|\\?\\<\\>*\\/+-]/")
  Rules[:_oper] = rule_info("oper", "< opchr (opchr | /[=]/)* > {text}")
  Rules[:_operator] = rule_info("operator", "p:p oper:o {n(p, :oper, o)}")
  Rules[:_name] = rule_info("name", "p:p < (&(!(sp | nl | brace | opchr | \":\" | \";\" | \",\" | \".\")) .)+ > {n(p, :name, text)}")
  Rules[:_keyword] = rule_info("keyword", "\":\" < (!(&(n | \":\" | brace)) .)+ > !(&(\":\" | \";\" | \".\")) &{text.size > 0} {text}")
  Rules[:_value] = rule_info("value", "(msg(h) | value(h):v args:a {n(v.pos, :act, v, a.name, *a.args)} | args:a {n(a.pos, :act, nil, a.name, *a.args)} | literal | operator | name)")
  Rules[:_comma_left] = rule_info("comma_left", "block(h):a w \",\" {a}")
  Rules[:_comma] = rule_info("comma", "(comma_left(h):a w comma(h):b { b.unshift a ; b } | comma_left(h):a w block(h):b { [a,b] } | comma_left(h):a &(sp* (\".\" | \",\" | t | brace)) {[a]})")
  Rules[:_tuple] = rule_info("tuple", "comma(h):c {n(p, :tuple, *c)}")
  Rules[:_cons_left] = rule_info("cons_left", "expr(h):a sp* \":\" !(&(\":\" | \";\" | \".\")) {a}")
  Rules[:_cons] = rule_info("cons", "(cons_left(h):a - cons(h):b {n(p, :cons, a, b)} | cons_left(h):a - expr(h):b {n(p, :cons, a, b)})")
  Rules[:_args] = rule_info("args", "p:p left_brace:l - (comma(h) | block(h) | {[]}):a - right_brace(l) {n(p, l.join, *Array(a))}")
  Rules[:_msg] = rule_info("msg", "(msg(h):a sp* \":\" &(\":\" | \";\" | \".\") {a} | part(h):a w msg(h | a.pos):m {n(a.pos, :msg, a, *m.args)} | part(h):a {n(a.pos, :msg, a)})")
  Rules[:_part] = rule_info("part", "(part(h):p o w block(h | p.pos):e { p.args.push *Array(e) ; p } | part(h):p part_head(h | p.pos):e { p.args.push *Array(e) ; p } | p:p keyword:k args:a {n(p, k, a.name, *a.args)} | p:p keyword:k {n(p, k, \"()\")})")
  Rules[:_part_head] = rule_info("part_head", "sp+ !(&keyword) (ph_comma(h) | expr(h) | {[]})")
  Rules[:_ph_comma] = rule_info("ph_comma", "(expr(h):a w \",\" - ph_comma(h):b { b.unshift a ; b } | expr(h):a w \",\" - expr(h):b { [a,b] })")
  Rules[:_expr] = rule_info("expr", "value(h):e &{ e.pos.column > h.column } {e}")
  Rules[:_chain] = rule_info("chain", "(chain(h):a sp* \".\" - chain(h)?:b { b && n(a.pos, :chain, a, b) || a } | operator:a !(&brace) o w chain(h):b {n(a.pos, :chain, a, *Array(b.name == :chain && b.args || b))} | chain_cont(h) | expr(h):a sp* chain(a.pos):b {n(a.pos, :chain, a, *Array(b.name == :chain && b.args || b))} | chain_val(h))")
  Rules[:_chain_cont] = rule_info("chain_cont", "chain_val(h):a {(h | a.pos || h()).incr}:i sp* (comma(h) | (nl | sheebang) - block(i)):c {                 if a.name == :act                    a.args.push *Array(c); a                 else                    n(a.pos, :act, a, \"()\", *Array(c))                 end               }")
  Rules[:_chain_val] = rule_info("chain_val", "(cons(h) | expr(h))")
  Rules[:_block] = rule_info("block", "(chain(h):a sp* t - block(h):b {n(a.pos, :block, a, *Array(b.name == :block && b.args || b))} | chain(h))")
  Rules[:_root] = rule_info("root", "- block(h)?:b - eof {b}")
  Rules[:_unit] = rule_info("unit", "- chain(h):c {c}")
  Rules[:_eof] = rule_info("eof", "!.")
end
