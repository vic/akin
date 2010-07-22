Akin Parser Message = Origin mimic
Akin Parser Message do(

  initialize = method(type nil, text nil, body: nil, literal: nil, position: nil,
    @type = type
    @text = text
    @body = body
    @literal = literal
    @fwd = nil
    @bwd = nil
    @position = position
  )

  copy = method(
    msg = Akin Parser Message mimic(
      type, text, body: body, literal: literal, position: position
    )
    msg fwd = fwd
    msg bwd = bwd
    msg
  )

  copyExpr = method(copyUntil(punctuation?))

  copyUntil = dmacro(
    [code]
    here = ''(findForward(`code)) evaluateOn(call ground, self)
    deepCopy(here),

    [name, code]
    here = ''(findForward(`name, `code)) evaluateOn(call ground, self)
    deepCopy(here)
  )

  deepCopy = method(limit nil,
    msg = Akin Parser Message mimic(type, text)
    if(body, 
      msg body = Akin Parser Message Body mimic(
        if(body message, body message deepCopy, nil),
        if(body brackets, body brackets mimic, nil)
      )
    )
    if(literal, msg literal = literal mimic)
    if(position, msg position = position)
    if(fwd && fwd != limit, 
      msg fwd = fwd deepCopy, 
      msg fwd = nil)
    if(bwd, msg bwd = bwd)
    msg
  )

  
  identifier? = method(type == :identifier)
  comment? = method(type == :comment)
  space? = method(type == :space)
  document? = method(type == :document)
  operator? = method(type == :operator)
  

  call? = method(body nil? not)
  hasArgs? = method(argCount > 0)

  argCount = method(if(body nil? || body message nil?, return 0, body argCount))

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
  
  first = method(findBackward(bwd nil?) || self)

  last = method(findForward(fwd nil?) || self)

  afterPunctuation = method(
    punc = findForward(punctuation?)
    punc && punc fwd
  )

  next = method(
    ;; find next until punctuation
    findForward(m,
      if(m punctuation?, return)
      m visible?
    )
  )

  prev = method(
    ;; find prev until punctuation
    findBackward(m,
      if(m punctuation?, return)
      m visible?
    )
  )

  cell("next=") = method(msg, 
    if(msg && msg == @next, return msg)
    ;; Set next until punctuation,
    p = findForward(punctuation?)
    here = (msg && findForward(invisible?)) || self
    if(msg, 
      here append(msg),
      here detachRight)
    if(p, 
      if(msg, 
        p = p findBackward(invisible?) || p
        msg last append(p),
        here append(p)
      )
    )
    msg
  )

  cell("prev=") = method(msg, 
    if(msg && msg == @prev, return msg)
    ;; Set prev until punctuation,
    p = findBackward(punctuation?)
    here = (msg && findBackward(invisible?)) || self
    if(msg, 
      msg last append(here),
      here detachLeft)
    if(p, 
      p = p findForward(invisible?) || p
      if(msg, 
        p append(msg),
        p append(here)
      )
    )
    msg
  )

  prec = method(
    findBackward(visible?)
  )

  succ = method(
    findForward(visible?)
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

  invisible? = method(space? || comment?)
  visible? = method(invisible? not)

  white? = method(space? || comment? || eol?)

  expression? = method((white? || punctuation?) not)

  expression = method(n 0,
    n = n abs + 1
    findForward(m, m expression? && (n-- == 0))
  )

  lastExpr = method(
    if(p = findForward(punctuation?),
      p findBackward(expression),
      last findBackward(expression)
    )
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
    m = if(expression?, self, next)
    while(m && n > 0,
      n--
      if(n == 0, return m)
      m = m findForward(enumerator?)
      if(m, m = m next)
    )
    nil
  )

  firstInNextLine = method(
    eol = findForward(eol?)
    if(eol, eol fwd, nil)
  )

  firstInLine = method(usePosition false,
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

  previousLine = method(
    eol = findBackward(eol?)
    eol && eol bwd && eol bwd firstInLine
  )
  
  lineIndentLevel = method(usePosition false,
    if(usePosition nil? && position, usePosition = true)
    first = firstInLine(usePosition)
    if(self != first && first space?,
      first text length, 0)
  )

  sameLineIndent? = method(m, usePosition false,
    if(usePosition nil? && position && m position, usePosition = true)
    lineIndentLevel(usePosition) ==  m lineIndentLevel(usePosition)
  )

  sameLine? = method(m, usePosition false,
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

  sameColumn? = method(m, usePosition false,
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
    if(msg colonArgOp? && operator? && body nil?,
      space = Akin Parser Message mimic(:activation)
      space position = msg position
      space append(msg)
      append(space)
      return msg)
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
        last = body message last 
        if(last white?, last = last prec)
        if(last comma?, 
          last append(arg),
          fst = if(arg comma?, arg, arg next)
          if(fst && fst comma?,
            last append(arg),
            comma = Akin Parser Message mimic(:punctuation, ",")
            comma position = arg position
            last append(comma) append(arg)
          )
        ),
        body message = arg),
      @body = Akin Parser Message Body mimic(arg, brackets)
    )
    self
  )

  notice = method(super + "["+text+"]")

  code = method(
    sb = Akin Parser StringBuilder mimic
    Akin Parser Message Code send(type, self, sb)
    sb asText
  )

)

let(finderMethod, 
  dsyntax(
    [direction]
    ''(
      dmacro(
        [code]
        m = 'direction
        while(m, 
          if(code evaluateOn(call ground, m), return m)
          m = m 'direction)
        nil,
        
        [name, code]
        lexicalCode = LexicalBlock createFrom(list(name, code),
          call ground)
        m = 'direction
        while(m,
          if(lexicalCode call(m), return m)
          m = m 'direction)
        nil
      )
    )
  ),
  
  Akin Parser Message findForward = finderMethod(fwd)
  Akin Parser Message findBackward = finderMethod(bwd)
  Akin Parser Message findNext = finderMethod(next)
  Akin Parser Message findPrev = finderMethod(prev)
  Akin Parser Message findSucc = finderMethod(succ)
  Akin Parser Message findPrec = finderMethod(prec)
)


Akin Parser Message Code = Origin mimic
Akin Parser Message Code do(

  rest = method(m, sb,
    if(m body,
      if(m body brackets, sb << m body brackets first)
      if(m body message, sb << m body message code)
      if(m body brackets, sb << m body brackets last)
    )
    if(m fwd, sb << m fwd code)
  )

  activation = method(m, sb, 
    if(m text, sb << m text)
    rest(m, sb)
  )
  
  code = cell(:activation)
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
        sb << m literal[:parts][i] code
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
    sb << "0x". code(m, sb)
  )
  octNumber = method(m, sb,
    sb << "0o". code(m, sb)
  )
  binNumber = method(m, sb,
    sb << "0b". code(m, sb)
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

Akin Parser Message mimic!(Mixins Enumerable)
Akin Parser Message each = dmacro(
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
  lexicalCode = LexicalBlock createFrom(list(index,place,code), call ground)
  i = 0
  m = self
  while(m, lexicalCode call(i, m). m = m fwd. i++)
  self,
)

Akin Parser Message Body = Origin mimic
Akin Parser Message Body do(

  initialize = method(message, brackets nil,
    @message = message
    @brackets = brackets
  )

  at = method(index, message at(index))
  cell("[]") = method(index, message at(index))

  argCount = method(
    if(message nil?, return 0)
    commas = 0
    c = message findForward(enumerator?)
    while(c, commas++. c = c findForward(enumerator?))
    if(message expression, commas++)
    commas
  )

  
  argAt = method(index, message enumerated(index))

  arg = method(index, m = argAt(index). m && m copyExpr)
  args = method(
    unless(message, return list)
    result = list
    argCount times(i, result append!(arg(i)))
    result
  )
  
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
    list("⟨", "⟩"),
    list("¿", "?")
  )

)


