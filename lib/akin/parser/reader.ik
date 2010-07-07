
Akin Parser MessageReader = Origin mimic
Akin Parser MessageReader do(

  initialize = method(at, @at = at)

  read = method(
    txt = Akin Parser String txt(at char)
    @at = at next
    txt
  )

  fwd = method(at next)

  newMsg = method(+rest, +:krest,
    krest[:position] = at position
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
    if(at space?, readSpaces)
    if(at rightBracket?, return)
    if(at eof?, read. return)
    if(at terminator?, return newMsg(read))
    if(at decimal?, return readNumber)
    msg = nil
    if(at alpha?, msg = readIdentifier)
    if(at leftBracket?,
      unless(msg, msg = newMsg(""))
      brackets = at brackets assoc(read)
      body = readMessageChain
      readChar(brackets second)
      msg activation = Akin Message Activation mimic(body, brackets))
    unless(msg, error!("Unexpected "+at desc))
    msg
  )

  readChar = method(expected,
    unless(at ?(expected),
      error!("Expected char "+expected inspect+" got "+at desc))
    read
  )

  readIdentifier = method(
    sb = Akin Parser StringBuilder mimic
    while(at identifier?, sb << read)
    newMsg(sb asText)
  )

  readNumber = method(
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

  readHexadecimalNumber = method(
    unless(at hexadecimal?,
      error!("Invalid char in hexadecimal number literal "+
        at position+" got: "+at desc))
    sb = Akin Parser StringBuilder mimic
    while(at hexadecimal? || (at sub? || fwd hexadecimal?),
      if(at sub?, read)
      sb << read)
    lit = Akin Message Literal mimic(:hexNumber, text: sb asText)
    newMsg(literal: lit)
  )

  readOctalNumber = method(
    unless(at octal?,
      error!("Invalid char in octal number literal "+
        at position+" got: "+at desc))
    sb = Akin Parser StringBuilder mimic
    while(at octal? || (at sub? || fwd octal?),
      if(at sub?, read)
      sb << read)
    lit = Akin Message Literal mimic(:octNumber, text: sb asText)
    newMsg(literal: lit)
  )

  readBinaryNumber = method(
    unless(at binary?,
      error!("Invalid char in binary number literal "+
        at position+" got: "+at desc))
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
      error!("Invalid char in decimal number literal "+
        at position+" got: "+at))
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
      error!("Invalid char in decimal exponent literal "+
        at position+" got: "+at desc))
    sign = "+"
    if(at adition?, sign = read)
    exp = readDecimalInteger
    lit = Akin Message Literal mimic(:decExponent, sign: sign,
      exp: exp literal text)
    newMsg(literal: lit)
  )

  readSpaces = method(while(at space?, read))
  readBlank = method(while(at blank?, read))

)

