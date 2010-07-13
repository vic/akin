Akin Tokenizer Message = Origin mimic
Akin Tokenizer Message do(

  initialize = method(name nil, body nil, 
    literal: nil, phyPos: nil, logPos: nil,
    @name = if(name, :(name), nil)
    @body = body
    @literal = literal
    @next = nil
    @previous = nil
    @phyPos = phyPos
    @logPos = logPos || phyPos
  )

  body? = method(body nil? not)
  literal? = method(literal nil? not)

  comment? = method(literal && literal type == :comment)
  
  space? = method(name == :(""))
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
    fwd = index == idx
    msg = self
    while(msg && idx > 0, 
      idx--
      if(fwd, msg = msg next, msg = msg previous)
      if(idx == 0, return msg)
    )
    nil
  )

  arg = method(index,
    unless(body, return)
    body argAt(index)
  )
  
  first = method(
    m = self
    while(m previous, m = m previous)
    m
  )

  last = method(
    m = self
    while(m next, m = m next)
    m
  )

  findForward = dmacro(
    [code]
    m = self
    while(m, 
      if(code evaluateOn(call ground, m), return m)
      m = m next)
    nil,

    [name, code]
    lexicalCode = LexicalBlock createFrom(list(name, code), call ground)
    m = self
    while(m, 
      if(lexicalCode call(m), return m)
      m = m next)
    nil
  )

  findBackward = dmacro(
    [code]
    m = self
    while(m, 
      if(code evaluateOn(call ground, m), return m)
      m = m previous)
    nil,

    [name, code]
    lexicalCode = LexicalBlock createFrom(list(name, code), call ground)
    m = self
    while(m, 
      if(lexicalCode call(m), return m)
      m = m previous)
    nil
  )

  white? = method(space? || comment? || eol?)

  visible? = method((space? || comment? || punctuation?) not)
  visible = method(n 0,
    n = n abs + 1
    m = self
    while(n > 0,
      n--
      m = m find(visible?)
      if(n == 0, return m)
      unless(m, return)
      m = m next
      unless(m, return)
    )
    nil
  )

  enumerated = method(n 0,
    n = n abs + 1
    m = self
    while(m && n > 0,
      n--
      m = m find(visible?)
      if(m && m enumerator?, m = nil)
      if(n == 0, return m)
      if(m, m = m find(enumerator?), return)
      if(m, m = m next, return)
    )
    nil
  )

  firstInLine = method(
    unless(logPos, return self)
    m = self
    while(m && m previous && 
      m previous logPos line == logPos line,
      m = m previous)
    m
  )
  
  indentLevel = method(
    first = firstInLine
    if(self != first && first next space?,
      first next literal text length, 0)
  )

  sameLine? = method(msg, 
    logPos && msg logPos && logPos line == msg logPos line
  )

  sameColumn? = method(msg,
    logPos && msg logPos && logPos column == msg logPos column
  )
 
  attach = method(msg,
    if(body nil? && msg name nil? && msg body && msg literal nil?,
      @body = msg body
      return self)
    
    if(next, next previous = nil)
    msg previous = self
    @next = msg
    msg
  )

  detach = method(newNext: nil, newPrev: nil,
    edges = list(previous, next)
    if(previous, previous next = next)
    if(next, next previous = previous)
    @previous = newNext
    @next = newPrev
    edges
  )

  insert = method(msg,
    old = next
    if(old, old previous = msg)
    msg previous = self
    @next = msg
    msg
  )

  cell("+") = method(msg,
    if(msg previous, msg previous = nil)
    msg previous = self
    if(next && next previous, next previous = nil)
    @next = msg
    msg
  )

  appendArgument = method(arg, 
    if(body, 
      if(body message, 
        last = body message last findBackward(white? not)
        if(last comma?, 
          last + arg,
          last + Akin Tokenizer Message mimic(:",") + arg
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
    if(next, sb << next code)
    sb asText
  )

)

Akin Tokenizer Message mimic!(Mixins Enumerable)
Akin Tokenizer Message each = dmacro(
  [code]
  m = self
  while(m, code evaluateOn(call ground, m). m = m next)
  self,

  [name, code]
  lexicalCode = LexicalBlock createFrom(list(name, code), call ground)
  m = self
  while(m, lexicalCode call(m). m = m next)
  self,

  [index, place, code]
  lexicalCode = LexicalBlock createFrom(list(index,name, code), call ground)
  i = 0
  m = self
  while(m, lexicalCode call(i, m). m = m next. i++)
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

