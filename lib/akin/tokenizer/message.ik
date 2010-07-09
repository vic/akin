Akin Tokenizer Message = Origin mimic
Akin Tokenizer Message do(

  initialize = method(name nil, body nil, literal: nil, position: nil,
    @name = if(name, :(name), nil)
    @body = body
    @literal = literal
    @next = nil
    @previous = nil
    @position = position
  )

  body? = method(body nil? not)
  literal? = method(literal nil? not)

  comment? = method(literal && literal type == :comment)
  
  space? = method(name == :(""))
  terminator? = method(name == :(".") || name == :("\n") || name == :("\r"))
  separator? = method(name == :(","))
  enumerator? = method(name == :(","))

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
  
  head = method(
    m = self
    while(m previous, m = m previous)
    m
  )

  tail = method(
    m = self
    while(m next, m = m next)
    m
  )

  visible? = method((space? || terminator?) not)
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
 
  attach = method(msg,
    if(body nil? && msg name nil? && msg body && msg literal nil?,
      @body = msg body
      return self)
    
    if(next, next previous = nil)
    msg previous = self
    @next = msg
    msg
  )

  insert = method(msg,
    old = next
    if(old, old previous = msg)
    msg previous = self
    @next = msg
    msg
  )

  notice = method(super + "["+name+"]")

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

