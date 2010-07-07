Akin Message = Origin mimic
Akin Message do(

  initialize = method(name nil, activation nil, literal: nil, position: nil,
    @name = if(name, :(name), nil)
    @activation = activation
    @literal = literal
    @next = nil
    @previous = nil
    @position = position
  )
  
  literal? = method( !literal nil? )
  activation? = method( !activation nil? )
  terminator? = method( name == :(";") || name == :("\n") )

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

Akin Message Activation = Origin mimic
Akin Message Activation do(

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

