Akin Tokenizer Message = Origin mimic
Akin Tokenizer Message do(

  initialize = method(name nil, body nil, literal: nil, position: nil,
    @name = if(name, :(name), nil)
    @body = body
    @literal = literal
    @succ = nil
    @prec = nil
    @position = position
  )

  body? = method(body nil? not)
  literal? = method(literal nil? not)

  comment? = method(literal && literal type == :comment)
  
  space? = method(name == :("") && body nil?)
  dot? = method(name == :("."))
  colon? = method(name == :(":"))
  semicolon? = method(name == :(";"))
  dcolon? = method(name == :("::"))

  comma? = method(name == :(","))
  
  end? = method(dot? || semicolon?)
  eol? = method(name == :("\n") || name == :("\r"))
  
  terminator? = method(end? || eol?)
  separator? = method(name == :(";"))
  enumerator? = method(name == :(","))

  punctuation? = method(terminator? || separator? || enumerator?)

  colonArgOp? = method(colon? && body nil?)
  dcolonArgOp? = method(dcolon? && body nil?)

  cell("[]") = method(index, at(index))

  at = method(index,
    if(index == 0, return self)
    idx = index abs
    succ = index == idx
    msg = self
    while(msg && idx > 0, 
      idx--
      if(succ, msg = msg succ, msg = msg prec)
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
  
  first = method(
    m = self
    while(m prec, m = m prec)
    m
  )

  last = method(
    m = self
    while(m succ, m = m succ)
    m
  )

  findForward = dmacro(
    [code]
    m = self
    while(m, 
      if(code evaluateOn(call ground, m), return m)
      m = m succ)
    nil,

    [name, code]
    lexicalCode = LexicalBlock createFrom(list(name, code), call ground)
    m = self
    while(m, 
      if(lexicalCode call(m), return m)
      m = m succ)
    nil
  )

  findBackward = dmacro(
    [code]
    m = self
    while(m, 
      if(code evaluateOn(call ground, m), return m)
      m = m prec)
    nil,

    [name, code]
    lexicalCode = LexicalBlock createFrom(list(name, code), call ground)
    m = self
    while(m, 
      if(lexicalCode call(m), return m)
      m = m prec)
    nil
  )

  prev = method(
    prec && prec findBackward(m, (m space? || m comment?) not)
  )

  next = method(
    succ && succ findForward(m, (m space? || m comment?) not)
  )

  cell("next=") = method(msg,
    n = @next
    if(n, msg replace(n), last append(msg))
    msg
  )

  cell("prev=") = method(msg,
    p = @prev
    if(p, msg replace(p), first prepend(msg))
    msg
  )

  white? = method(space? || comment? || eol?)

  expression? = method((white? || punctuation?) not)

  expression = method(n 0,
    n = n abs + 1
    findForward(m, m expression? && (n-- == 0))
  )

  enumerated = method(n 0,
    n = n abs + 1
    m = self
    while(m && n > 0,
      n--
      m = m findForward(expression?)
      if(m && m enumerator?, m = nil)
      if(n == 0, return m)
      if(m, m = m findForward(enumerator?), return)
      if(m, m = m succ, return)
    )
    nil
  )

  firstInLine = method(usePosition: false,
    if(usePosition nil? && position, usePosition = true)
    if(usePosition, firstInLine:withPosition, firstInLine:noPosition)
  )

  firstInLine:noPosition = method(
    eol = findBackward(eol?)
    if(eol, eol succ, first)
  )

  firstInLine:withPosition = method(
    unless(position, return self)
    m = self
    while(m && m prec && 
      m prec position logical line == position logical line,
      m = m prec)
    m
  )
  
  lineIndentLevel = method(usePosition: false,
    if(usePosition nil? && position, usePosition = true)
    first = firstInLine(usePosition: usePosition)
    if(self != first && first space?,
      first literal text length, 0)
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
    msg prec = self
    if(succ, succ pevious = nil)
    @succ = msg
    msg
  )

  prepend = method(msg,
    msg succ = self
    if(prec, prec succ = nil)
    @prec = msg
    msg
  )

  attach = method(msg,
    if(body nil? && msg name nil? && msg body && msg literal nil?,
      @body = msg body
      return self)
    append(msg)
  )

  detach = method(newNext: nil, newPrev: nil,
    edges = list(prec, succ)
    if(prec, prec succ = succ)
    if(succ, succ prec = prec)
    @prec = newNext
    @succ = newPrev
    edges
  )

  insert = method(msg,
    old = succ
    if(old, old prec = msg)
    msg prec = self
    @succ = msg
    msg
  )

  replace = method(other, upto nil,
    if(upto nil?,
      other insert(self)
      other detach,

      @prec = other prec
      if(prec, prec succ = self)

      last = @last
      last succ = upto succ
      if(last succ, last succ prec = last)

      other prec = nil
      upto succ = nil

    )
    self
  )

  appendArgument = method(arg, 
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
      @body = Akin Tokenizer Message Body mimic(arg, list("(", ")"))
    )
    self
  )

  notice = method(super + "["+name+"]")

  code = method(
    sb = Akin Tokenizer StringBuilder mimic
    cond(
      literal && literal type == :space,
      sb << literal text,

      literal && literal type == :symbolIdentifier,
      sb << ":" << literal text,

      if(name, sb << name asText)
      if(body, 
        sb << body brackets first
        if(body message, sb << body message code)
        sb << body brackets last
      )
    )
    if(succ, sb << succ code)
    sb asText
  )

)

Akin Tokenizer Message mimic!(Mixins Enumerable)
Akin Tokenizer Message each = dmacro(
  [code]
  m = self
  while(m, code evaluateOn(call ground, m). m = m succ)
  self,

  [name, code]
  lexicalCode = LexicalBlock createFrom(list(name, code), call ground)
  m = self
  while(m, lexicalCode call(m). m = m succ)
  self,

  [index, place, code]
  lexicalCode = LexicalBlock createFrom(list(index,name, code), call ground)
  i = 0
  m = self
  while(m, lexicalCode call(i, m). m = m succ. i++)
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

Akin Tokenizer Message Literal = Origin mimic
Akin Tokenizer Message Literal do(
  initialize = method(type, +:kdata,
    @type = type
    kdata keys each(k, @cell(k) = kdata[k])
  )
)

