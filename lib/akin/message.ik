Akin Message = Origin mimic
Akin Message do(

  initialize = method(name nil, body nil, literal: nil, position: nil,
    @name = if(name, :(name), nil)
    @body = body
    @literal = literal
    @next = nil
    @previous = nil
    @position = position
  )
  
  space? = method(name == :(""))
  literal? = method(literal nil? not)
  body? = method(body nil? not)
  terminator? = method(name == :(".") || name == :("\n") || name == :("\r"))

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

  attach = method(msg,
    oldNext = next
    if(oldNext, oldNext previous = nil)
    msg previous = self
    @next = msg
    oldNext
  )

  insert = method(msg,
    old = next
    if(old, old previous = msg)
    msg previous = self
    @next = msg
  )

  notice = method(super + "["+name+"]")

)

Akin Message Body = Origin mimic
Akin Message Body do(

  initialize = method(body, brackets nil,
    @body = body
    @brackets = brackets
  )

  round? = method( bracketed?("(", brackets) )
  square? = method( bracketed?("[", brackets) )
  curly? = method( bracketed?("{", brackets) )
  chevron? = method( bracketed?("⟨", brackets) )
 
  bracketed? = method(left, both,
    both && both == Akin Parser At brackets assoc(left)
  )

)

Akin Message Literal = Origin mimic
Akin Message Literal do(
  initialize = method(type, +:kdata,
    @type = type
    kdata keys each(k, @cell(k) = kdata[k])
  )
)

