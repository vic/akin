
Akin Tokenizer MessageReader = Origin mimic
Akin Tokenizer MessageReader do(

  initialize = method(at, @savedPosition = nil. @at = at)

  read = method(
    txt = Akin Tokenizer String txt(at char)
    @at = at next
    txt
  )

  fwd = method(at next)

  savePosition = macro(
    old = savedPosition
    ensure(
      @savedPosition = at position
      call arguments first evaluateOn(call ground, self),
      @savedPosition = old
    )
  )

  newMsg = method(+rest, +:krest,
    pos = at position
    if(savedPosition, pos = savedPosition)
    @savedPosition = nil
    krest[:position] = pos
    Akin Tokenizer Message mimic(*rest, *krest)
  )
  newLit = method(+rest, +:krest,
    Akin Tokenizer Message Literal mimic(*rest, *krest)
  )

  newSb = method(Akin Tokenizer StringBuilder mimic)

  readMessageChain = method(
    head = nil
    last = nil
    while(current = readMessage,
      if(head nil?,
        head = current
        last = current,
        last = last attach(current)
      )
    )
    head
  )

  readMessage = method(
    if(at eof?, read. return)
    if(at rightBracket?, return)
    if(at leftBracket?, return readBrackets)
    if(at single?, return newMsg(read))
    if(at space?, return readSpace)
    if(at lineComment?, return readLineComment)
    if(at docStart?, return readDocument)
    if(at symbolStart?, return readSymbol)
    if(at textStart?, return readText)
    if(at decimal?, return readNumber)
    if(at operator?, return readOperator)
    readIdentifier
  )

  readIdentifier = method(
    savePosition(
      sb = newSb
      loop(
        if(at eof? || 
          at blank? ||
          at terminator? ||
          at enumerator? ||
          at separator?  ||
          at bracket?,
          break)
        
        if(at identifier?,
          sb << read,
          if(at ?(":", "$", "?"),
            if(fwd identifier? || fwd ?(":", "$", "?"),
              sb << read
              sb << read
              ,
              sb << read
              break)
            ,
            break)
        )
      )
      newMsg(sb asText))
  )

  readOperator = method(
    savePosition(
      sb = newSb
      while(at operator?, sb << read)
      newMsg(sb asText))
  )

  readLineComment = method(
    unless(at lineComment?, error!("Expected start of line comment -  "+at))
    msg = newMsg
    sb = newSb
    until(at eol? || at eof?, sb << read)
    msg literal = newLit(:comment, text: sb asText)
    msg
  )

  readBrackets = method(
    brackets = Akin Tokenizer Message Body brackets assoc(read)
    unless(brackets, error!("Unknown left bracket -  "+at))
    msg = newMsg(nil, Akin Tokenizer Message Body mimic(readMessageChain, brackets))
    readChar(brackets last)
    msg
  )

  readSymbol = method(
    unless(at colon?, 
      error!("Expected colon at start of symbol literal- got "+at))
    msg = newMsg
    read
    if(at quote?,
      txt = readText
      msg literal = txt literal
      msg literal type = :symbolText
      ,
      identifier = readIdentifier
      text = identifier name asText
      msg literal = newLit(:symbolIdentifier, text: text)
    )
    msg
  )

  readChar = method(expected,
    unless(at ?(expected),
      error!("Expected char "+expected inspect+" got "+at))
    read
  )

  readText = method(left nil, right left,
    savePosition(
      unless(left, 
        left = read
        right = left,
        read)
      interpolate? = left != "'"
      parts = list
      sb = nil
      loop(
        if(at eof?,
          error!("Expected end of text, found EOF")
          break)
        if(at backslash?,
          unless(sb, sb = newSb)
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
        if(interpolate? && at ?("#") && fwd ?("{"),
          parts << sb asText
          sb = nil
          read. read. readBlank.
          body = readMessageChain
          parts << body
          readBlank
          readChar("}")
        )
        if(at ?(right),
          read.
          if(sb, parts << sb asText)
          break
        )
        unless(sb, sb = newSb)
        sb << read
      )
      lit = newLit(:text, parts: parts)
      msg = newMsg(literal: lit)
    )
  )

  readNumber = method(
    savePosition(
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
  )

  readHexadecimalNumber = method(howManyChars nil,
    unless(at hexadecimal?,
      error!("Invalid char in hexadecimal number literal - got "+at))
    sb = newSb
    many = howManyChars
    seek = unless(many, true)
    while(seek && (at hexadecimal? || (at sub? || fwd hexadecimal?)),
      if(many, seek = (many--) > 0)
      if(at sub?, read)
      sb << read)
    if(howManyChars && many > 0, 
      error!("Expected #{many} more hexadecimal character(s)"))
    lit = newLit(:hexNumber, text: sb asText)
    newMsg(literal: lit)
  )

  readOctalNumber = method(
    unless(at octal?,
      error!("Invalid char in octal number literal - got "+at))
    sb = newSb
    while(at octal? || (at sub? || fwd octal?),
      if(at sub?, read)
      sb << read)
    lit = newLit(:octNumber, text: sb asText)
    newMsg(literal: lit)
  )

  readBinaryNumber = method(
    unless(at binary?,
      error!("Invalid char in binary number literal - got "+at))
    sb = newSb
    while(at binary? || (at sub? || fwd binary?),
      if(at sub?, read)
      sb << read)
    lit = newLit(:binNumber, text: sb asText)
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
      
    lit = newLit(:decNumber,
      integer: integer literal text,
      fraction: if(fraction, fraction literal text, nil),
      expsign: if(exponent, exponent literal sign, nil),
      exponent: if(exponent, exponent literal exp, nil))

    newMsg(literal: lit)
  )

  readDecimalInteger = method(
    unless(at decimal?,
      error!("Invalid char in decimal number literal - got "+at))
    sb = newSb
    sb << read
    while(at decimal? || (at sub? && fwd decimal?),
      if(at sub?, read)
      sb << read)
    lit = newLit(:decInteger, text: sb asText)
    newMsg(literal: lit)
  )

  readDecimalExponent = method(
    unless(at decimal? || at adition?,
      error!("Invalid char in decimal exponent literal - got "+at))
    sign = "+"
    if(at adition?, sign = read)
    exp = readDecimalInteger
    lit = newLit(:decExponent, sign: sign,
      exp: exp literal text)
    newMsg(literal: lit)
  )

  readSpace = method(
    msg = newMsg(:(""))
    sb = newSb
    while(at space?,
      if(at lineComment?,
        until(at eol?, read),
        sb << read))
    msg literal = newLit(:space, text: sb asText)
    msg
  )

  readDocument = method(
    sb = newSb
    docs = 0
    loop(
      if(at eof?, error!("Expected end of document - got "+at). break)
      if(at docStart?, 
        sb << read << read
        docs++)
      if(at docEnd?,
        sb << read << read
        docs--)
      if(docs == 0, break)
      sb << read
    )
    txt = sb asText
    newMsg(literal: newLit(:document, text: txt))
  )

  readBlank = method(
    while(at blank?,
      if(at lineComment?, 
        until(at eol?, read),
        read))
  )

)
