Akin Tokenizer Message = Origin mimic
Akin Tokenizer Message do(

  initialize = method(type nil, text nil, body: nil, literal: nil, position: nil,
    @type = type
    @text = text
    @body = body
    @literal = literal
    @fwd = nil
    @bwd = nil
    @position = position
  )

  
  identifier? = method(type == :identifier)
  comment? = method(type == :comment)
  space? = method(type == :space)
  document? = method(type == :document)
  operator? = method(type == :operator)
  

  call? = method(body nil? not)
  hasArgs? = method(argCount == 0)

  argCount = method(
    if(body nil? || body message nil?, return 0)
    n = -1
    c = body message findForward(comma?)
    while(c,
      n++
      c = c next && c next findForward(comma?)
    )
    n + 1
  )


  dot? = method(text == ".")
  colon? = method(text == ":")
  semicolon? = method(text == ";")
  dcolon? = method(text == "::")

  comma? = method(text == ",")
  
  end? = method(dot? || semicolon?)
  eol? = method(text == "\n")
  
  terminator? = method(end? || eol?)
  separator? = method(text == ";")
  enumerator? = method(text == ",")

  punctuation? = method(terminator? || separator? || enumerator?)

  colonArgOp? = method(colon? && body nil?)
  dcolonArgOp? = method(dcolon? && body nil?)

  cell("[]") = method(index, at(index))

  at = method(index,
    if(index == 0, return self)
    idx = index abs
    fwd = index == idx
    msg = self
    while(msg && idx > 0, 
      idx--
      if(fwd, msg = msg fwd, msg = msg bwd)
      if(idx == 0, return msg)
    )
    nil
  )

  arg = method(index,
    unless(body, return)
    body argAt(index)
  )
  
  cell("arg=") = method(index, msg, 
    arg = @arg(index)
    unless(arg, error!("No argument found at index #{index}"))
    comma = arg findForward(enumerator?)
    upto = if(comma, comma prev, 
      lst = arg last
      if(lst space?, lst prev, lst)
    )
    msg replace(arg, upto)
    msg
  )
  
  first = method(findBackward(bwd nil?))

  last = method(findForward(fwd nil?))

  findForward = dmacro(
    [code]
    m = self
    while(m, 
      if(code evaluateOn(call ground, m), return m)
      m = m fwd)
    nil,

    [name, code]
    lexicalCode = LexicalBlock createFrom(list(name, code), call ground)
    m = self
    while(m, 
      if(lexicalCode call(m), return m)
      m = m fwd)
    nil
  )

  findBackward = dmacro(
    [code]
    m = self
    while(m, 
      if(code evaluateOn(call ground, m), return m)
      m = m bwd)
    nil,

    [name, code]
    lexicalCode = LexicalBlock createFrom(list(name, code), call ground)
    m = self
    while(m, 
      if(lexicalCode call(m), return m)
      m = m bwd)
    nil
  )

  next = method(
    ;; find next until punctuation
    fwd && fwd findForward(m,
      if(m punctuation?, return)
      (m space? || m comment?) not
    )
  )

  prev = method(
    ;; find prev until punctuation
    bwd && bwd findBackward(m,
      if(m punctuation?, return)
      (m space? || m comment?) not
    )
  )

  cell("next=") = method(msg, 
    ;; Set next until punctuation,
    p = fwd && fwd findForward(punctuation?)
    here = findForward(m, (m space? || m comment?)) || self
    here append(msg)
    if(p, msg last append(p))
    msg
  )

  cell("prev=") = method(msg, 
    ;; Set prev until punctuation,
    p = bwd && bwd findBackward(punctuation?)
    here = findBackward(m, (m space? || m comment?)) || self
    msg last append(here)
    if(p, p append(msg))
    msg
  )

  prec = method(
    bwd && bwd findBackward(m, (m space? || m comment?) not)
  )

  succ = method(
    fwd && fwd findForward(m, (m space? || m comment?) not)
  )

  cell("succ=") = method(msg,
    n = @succ
    if(n, msg replace(n), last append(msg))
    msg
  )

  cell("prec=") = method(msg,
    p = @prec
    if(p, msg replace(p), first prepend(msg))
    msg
  )

  white? = method(space? || comment? || eol?)

  expression? = method((white? || punctuation?) not)

  expression = method(n 0,
    n = n abs + 1
    findForward(m, m expression? && (n-- == 0))
  )

  firstExpr = method(
    if(p = findBackward(punctuation?),
      p expression,
      first expression)
  )

  firstExpr? = method(firstExpr == self)

  nextExpr? = method(next && next expression?)

  firstExprInLine = method(firstInLine expression)

  firstExprInLine? = method(firstInLine == self)

  enumerated = method(n 0,
    n = n abs + 1
    m = self
    while(m && n > 0,
      n--
      m = m findForward(expression?)
      if(m && m enumerator?, m = nil)
      if(n == 0, return m)
      if(m, m = m findForward(enumerator?), return)
      if(m, m = m fwd, return)
    )
    nil
  )

  firstInLine = method(usePosition: false,
    if(usePosition nil? && position, usePosition = true)
    if(usePosition, firstInLine:withPosition, firstInLine:noPosition)
  )

  firstInLine:noPosition = method(
    eol = findBackward(eol?)
    if(eol, eol fwd, first)
  )

  firstInLine:withPosition = method(
    unless(position, return self)
    m = self
    while(m && m bwd && 
      m bwd position logical line == position logical line,
      m = m bwd)
    m
  )
  
  lineIndentLevel = method(usePosition: false,
    if(usePosition nil? && position, usePosition = true)
    first = firstInLine(usePosition: usePosition)
    if(self != first && first space?,
      first text length, 0)
  )

  sameLineIndent? = method(m, usePosition: false,
    if(usePosition nil? && position && m position, usePosition = true)
    lineIndentLevel(usePosition: usePosition) ==  m lineIndentLevel(usePosition: usePosition)
  )

  sameLine? = method(m, usePosition: false,
    if(usePosition nil? && position && m position, usePosition = true)
    if(usePosition, sameLine:withPosition(m), sameLine:noPosition(m))
  )

  sameLine:noPosition? = method(msg, 
    findBackward(eol?) == msg findBackward(eol?)
  )

  sameLine:withPosition? = method(msg, 
    (position && msg position &&
      position logical line == msg position logical line)
  )

  sameColumn? = method(m, usePosition: false,
    if(usePosition nil? && position && m position, usePosition = true)
    if(usePosition, sameColumn:withPosition?(m), 
      sameColumn:noPosition?(m))
  )

  sameColumn:noPosition? = method(msg, 
    indentLevel == msg indentLevel
  )

  sameColumn:withPosition? = method(msg,
    (position && msg position && 
      position logical column == msg position logical column)
  )

  append = method(msg, 
    if(msg bwd, msg bwd fwd = nil)
    msg bwd = self
    if(fwd, fwd bwd = nil)
    @fwd = msg
    msg
  )

  prepend = method(msg,
    if(msg fwd, msg fwd bwd = nil)
    msg fwd = self
    if(bwd, bwd fwd = nil)
    @bwd = msg
    msg
  )

  chain! = method(msg,
    if(msg type == :activation && expression? && body nil?,
      @body = msg body
      return self)
    append(msg)
  )

  detachLeft = method(newFwd: nil,
    old = bwd
    if(old, old fwd = newFwd)
    @bwd = nil
    old
  )

  detachRight = method(newBwd: nil,
    old = fwd
    if(old, old bwd = newBwd)
    @fwd = nil
    old
  )

  detach = method(newFwd: nil, newBwd: nil,
    edges = list(bwd, fwd)
    if(bwd, bwd fwd = fwd)
    if(fwd, fwd bwd = bwd)
    @bwd = newFwd
    @fwd = newBwd
    edges
  )

  insert = method(msg,
    msg last append(fwd)
    append(msg)
    msg
  )

  replace = method(other, upto nil,
    if(upto nil?,
      other insert(self)
      other detach,

      @bwd = other bwd
      if(bwd, bwd fwd = self)

      last = @last
      last fwd = upto fwd
      if(last fwd, last fwd bwd = last)

      other bwd = nil
      upto fwd = nil

    )
    self
  )

  appendArgument = method(arg, brackets  list("(", ")"),
    if(body, 
      if(body message, 
        last = body message last findBackward(white? not)
        if(last comma?, 
          last append(arg),
          last append(Akin Tokenizer Message mimic(:",")) append(arg)
          if(arg findForward(white? not) comma?,
            arg findForward(white? not) detach
          )
        ),
        body message = arg),
      @body = Akin Tokenizer Message Body mimic(arg, brackets)
    )
    self
  )

  notice = method(super + "["+text+"]")

  code = method(
    sb = Akin Tokenizer StringBuilder mimic
    Akin Tokenizer Message Code send(type, self, sb)
    sb asText
  )

)

Akin Tokenizer Message Code = Origin mimic
Akin Tokenizer Message Code do(

  rest = method(m, sb,
    if(m body,
      if(m body brackets, sb << m body brackets first)
      sb << m body message code
      if(m body brackets, sb << m body brackets last)
    )
    if(m fwd, sb << m fwd code)
  )

  activation = method(m, sb, 
    if(m text, sb << m text)
    rest(m, sb)
  )
  space = cell(:activation)
  identifier = cell(:activation)
  punctuation = cell(:activation)
  operator = cell(:activation)
  comment = cell(:activation)
  document = cell(:activation)
  symbolIdentifier = method(m, sb,
    sb << ":". activation(m, sb)
  )
  symbolText = method(m, sb,
    sb << ":". text(m, sb)
  )
  text = method(m, sb, rest: true,
    sb << m literal[:left]
    m literal[:parts] each(i, part, 
      if(i % 2 == 0, 
        sb << m literal[:parts][i],
        sb << "$(" << m literal[:parts][i] code << ")"
      )
    )
    sb << m literal[:right]
    if(rest, @rest(m, sb))
  )
  regexp = method(m, sb,
    text(m, sb, rest: false)
    if(m literal[:flags], sb << m literal flags)
    if(m literal[:engine], sb << ":" << m literal engine)
    rest(m, sb)
  )
  hexNumber = method(m, sb,
    sb << "0x". activation(m, sb)
  )
  octNumber = method(m, sb,
    sb << "0o". activation(m, sb)
  )
  binNumber = method(m, sb,
    sb << "0b". activation(m, sb)
  )
  decNumber = method(m, sb,
    sb << m literal[:integer]
    if(m literal[:fraction],
      sb << "." << m literal[:fraction])
    if(m literal[:exponent],
      sb << "e" << m literal[:exponent])
    rest(m, sb)
  )
  
)

Akin Tokenizer Message mimic!(Mixins Enumerable)
Akin Tokenizer Message each = dmacro(
  [code]
  m = self
  while(m, code evaluateOn(call ground, m). m = m fwd)
  self,

  [name, code]
  lexicalCode = LexicalBlock createFrom(list(name, code), call ground)
  m = self
  while(m, lexicalCode call(m). m = m fwd)
  self,

  [index, place, code]
  lexicalCode = LexicalBlock createFrom(list(index,name, code), call ground)
  i = 0
  m = self
  while(m, lexicalCode call(i, m). m = m fwd. i++)
  self,
)

Akin Tokenizer Message Body = Origin mimic
Akin Tokenizer Message Body do(

  initialize = method(message, brackets nil,
    @message = message
    @brackets = brackets
  )

  at = method(index, message at(index))
  cell("[]") = method(index, message at(index))
  
  argAt = method(index, message enumerated(index))
  
  round? = method( bracketed?("(", ")") )
  square? = method( bracketed?("[", "]") )
  curly? = method( bracketed?("{", "}") )
  chevron? = method( bracketed?("⟨", "⟩") )
 
  bracketed? = method(left "(", right ")",
    brackets && brackets == list(left, right)
  )

  brackets = list(
    list("(", ")"),
    list("[", "]"),
    list("{", "}"),
    list("⟨", "⟩")
  )

)


