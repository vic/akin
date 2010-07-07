
Akin Parser MessageReader = Origin mimic
Akin Parser MessageReader do(

  initialize = method(at, @savedPosition = nil. @at = at)

  read = method(
    txt = Akin Parser String txt(at char)
    @at = at next
    txt
  )

  fwd = method(at next)

  savePosition! = method(
    @savedPosition = at position
  )

  newMsg = method(+rest, +:krest,
    pos = at position
    if(savedPosition, pos = savedPosition)
    @savedPosition = nil
    krest[:position] = pos
    Akin Message mimic(*rest, *krest)
  )

  readMessageChain = method(
    head = nil
    last = nil
    while(current = readMessage,
      if(head nil?,
        head = current
        last = current,
        last attach(current)
        last = current
      )
    )
    head
  )

  readMessage = method(
    msg = nil    

    if(at rightBracket?, return)
    if(at eof?, read. return)

    if(at enumerator?,
      savePosition!
      name = at text
      read. readBlank.
      return newMsg(name))

    if(at terminator?, 
      return newMsg(read))

    if(at ?("\""), return readText)

    if(at decimal?, return readNumber)

    if(msg nil? && at ?(":"),
      msg = newMsg(read)
      if(at space?,
        readSpaces
        return msg,
        if(at ?("\""),
          txt = readText
          msg name = :(":")
          msg literal = txt literal
          msg literal type = :symbolText
          return msg,
        if(at identifier?,
          id = readIdentifier
          text = id name asText
          msg name = :(":"+text)
          msg literal = Akin Message Literal mimic(:symbolIdentifier, text: text)
          return msg,
        error!("Unexpected char while parsing text symbol - "+at)
      )))
    )

    if(msg nil? && at operator?, msg = readOperator)
    if(msg nil? && at alpha?, msg = readIdentifier)
    if(msg nil? && at space?, msg = readSpaceMessage)

    readSpaces

    if(at leftBracket?,
      unless(msg, msg = newMsg(""))
      brackets = at brackets assoc(read)
      body = readMessageChain
      readChar(brackets second)
      readSpaces
      msg activation = Akin Message Activation mimic(body, brackets))
    
    unless(msg, error!("Unexpected char while parsing message - got "+at))

    msg
  )

  readChar = method(expected,
    unless(at ?(expected),
      error!("Expected char "+expected inspect+" got "+at))
    read
  )

  readOperator = method(
    savePosition!
    sb = Akin Parser StringBuilder mimic
    while(at operator?, sb << read)
    newMsg(sb asText)
  )

  readIdentifier = method(
    savePosition!
    sb = Akin Parser StringBuilder mimic
    while(at identifier?, sb << read)
    newMsg(sb asText)
  )

  readText = method(left "\"", right left,
    savePosition!
    readChar(left)
    parts = list
    sb = nil
    loop(
      if(at eof?,
        error!("Expected end of text, found EOF")
        break)
      if(at ?("\\"),
        unless(sb, sb = Akin Parser StringBuilder mimic)
        if(fwd eol?,
          read. read,
        if(fwd ?("u", "U"),
          read. read.
          hex = readHexadecimalNumber(4) literal text
          sb << "\\u" << hex,
        if(fwd octal?,
          sb << read << fwd char
          if(at ?("0".."3"),
            if(fwd octal?,
              sb << read
              if(fwd octal?,
                sb << read
            )),
            if(fwd octal?,
              sb << read
            )
          )),
        if(fwd ?("b", "t", "n", "f", "r", "\\", "\n", "#", "e", right),
          sb << read << read,
        error!("Undefined text escape "+at)
      ))))
      if(at ?("#") && fwd ?("{"),
        parts << sb asText
        sb = nil
        read. read. readSpaces.
        body = readMessageChain
        parts << body
        readSpaces
        readChar("}")
      )      
      if(at ?(right),
        read. readSpaces.
        if(sb, parts << sb asText)
        break
      )
      unless(sb, sb = Akin Parser StringBuilder mimic)
      sb << read
    )
    lit = Akin Message Literal mimic(:text, parts: parts)
    msg = newMsg(left, literal: lit)
  )

  readNumber = method(
    savePosition!
    if(at ?("0"),
      if(fwd ?("x", "X"),
        read.read.
        return readHexadecimalNumber,
        if(fwd ?("b", "B"),
          read. read.
          return readBinaryNumber,
          if(fwd ?("o", "O"),
            read. read.
            return readOctalNumber,
            read.
            return readOctalNumber))))
    readDecimalNumber
  )

  readHexadecimalNumber = method(howManyChars nil,
    unless(at hexadecimal?,
      error!("Invalid char in hexadecimal number literal - got "+at))
    sb = Akin Parser StringBuilder mimic
    many = howManyChars
    seek = unless(many, true)
    while(seek && (at hexadecimal? || (at sub? || fwd hexadecimal?)),
      if(many, seek = (many--) > 0)
      if(at sub?, read)
      sb << read)
    if(howManyChars && many > 0, 
      error!("Expected #{many} more hexadecimal character(s)"))
    lit = Akin Message Literal mimic(:hexNumber, text: sb asText)
    newMsg(literal: lit)
  )

  readOctalNumber = method(
    unless(at octal?,
      error!("Invalid char in octal number literal - got "+at))
    sb = Akin Parser StringBuilder mimic
    while(at octal? || (at sub? || fwd octal?),
      if(at sub?, read)
      sb << read)
    lit = Akin Message Literal mimic(:octNumber, text: sb asText)
    newMsg(literal: lit)
  )

  readBinaryNumber = method(
    unless(at binary?,
      error!("Invalid char in binary number literal - got "+at))
    sb = Akin Parser StringBuilder mimic
    while(at binary? || (at sub? || fwd binary?),
      if(at sub?, read)
      sb << read)
    lit = Akin Message Literal mimic(:binNumber, text: sb asText)
    newMsg(literal: lit)
  )

  readDecimalNumber = method(
    integer = readDecimalInteger
    fraction = nil
    exponent = nil
    
    if(at ?(".") && fwd decimal?,
      read
      fraction = readDecimalInteger)
      
    if(at ?("e", "E") && (fwd adition? || fwd decimal?),
      read
      exponent = readDecimalExponent)
      
    lit = Akin Message Literal mimic(:decNumber,
      integer: integer literal text,
      fraction: if(fraction, fraction literal text, nil),
      expsign: if(exponent, exponent literal sign, nil),
      exponent: if(exponent, exponent literal exp, nil))

    newMsg(literal: lit)
  )

  readDecimalInteger = method(
    unless(at decimal?,
      error!("Invalid char in decimal number literal - got "+at))
    sb = Akin Parser StringBuilder mimic
    sb << read
    while(at decimal? || (at sub? && fwd decimal?),
      if(at sub?, read)
      sb << read)
    lit = Akin Message Literal mimic(:decInteger, text: sb asText)
    newMsg(literal: lit)
  )

  readDecimalExponent = method(
    unless(at decimal? || at adition?,
      error!("Invalid char in decimal exponent literal - got "+at))
    sign = "+"
    if(at adition?, sign = read)
    exp = readDecimalInteger
    lit = Akin Message Literal mimic(:decExponent, sign: sign,
      exp: exp literal text)
    newMsg(literal: lit)
  )

  readSpaceMessage = method(
    savePosition!
    sb = Akin Parser StringBuilder mimic
    while(at space?, sb << read)
    msg = newMsg("")
    lit = Akin Message Literal mimic(:space, text: sb asText)
    msg
  )

  readSpaces = method(while(at space?, read))

  readBlank = method(while(at blank?, read))

)

