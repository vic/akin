
Akin Parser MessageReader = Origin mimic
Akin Parser MessageReader do(

  initialize = method(at, rw,
    @rw = rw
    @at = at
  )

  read = method(
    txt = Akin Parser String txt(at char)
    @at = at fwd
    txt
  )

  fwd = method(at fwd)

  newMsg = method(+rest, +:krest,
    krest[:position] = at position
    Akin Parser Message mimic(*rest, *krest)
  )

  newSb = method(Akin Parser StringBuilder mimic)

  readMessageChain = method(
    head = nil
    last = nil
    level = rw level
    while(current = readMessage,
      if(head nil?,
        head = current,
        last append(current))
      last = current
      level add(last)
    )
    level head = head
    level finish
    level head && level head first
  )

  readMessage = method(
    msg = readSingle
    if(msg && msg type != :activation && msg expression? && at leftBracket?,
      act = readActivation
      msg body = act body
    )
    msg
  )

  readSingle = method(
    if(at eof?, return)
    if(at rightBracket?, return)
    if(at punctuation?, return readPunctuation)
    if(at space?, return readSpace)
    if(at leftBracket?, return readActivation)
    if(at blockStart?, return readBlock)
    if(at lineComment?, return readLineComment)
    if(at docStart?, return readDocument)
    if(at symbolStart?, return readSymbol)
    if(at textStart?, return readText)
    if(at regexpStart?, return readRegexp)
    if(at decimal?, return readNumber)
    if(at operator?, return readOperator)

    readIdentifier
  )

  readPunctuation = method(
    msg = newMsg(:punctuation)
    msg text = if(at eol?, read. "\n", read)
    msg
  )

  readIdentifier = method(
    msg = newMsg(:identifier)
    sb = newSb
    loop(
      if(at identifierInner?, 
        if(fwd identifier?, 
          sb << read << read,
          break))
      if(at identifier?,
        sb << read,
        break)
    )
    msg text = sb asText
    msg
  )

  readOperator = method(
    msg = newMsg(:operator)
    sb = newSb
    while(at operator?,
      opBr = !(fwd fwd operator? || fwd fwd leftBracket?)
      if(!at dot? && fwd dot? && opBr, sb << read. break)
      if(!at colon? && fwd colon? && opBr, sb << read. break)
      sb << read
    )
    msg text = sb asText
    msg
  )

  readLineComment = method(
    unless(at lineComment?, error!("Expected start of line comment -  "+at))
    msg = newMsg(:comment)
    sb = newSb
    until(at eol? || at eof?, sb << read)
    msg text = sb asText
    msg
  )

  readBlock = method(
    here = at
    text = read
    act = readActivation
    act text = text
    act position = here position
    act type = :block
    act
  )

  readActivation = method(
    open = at
    brackets = Akin Parser Message Body brackets assoc(read)
    unless(brackets, error!("Unknown left bracket -  "+open))
    msg = newMsg(:activation)
    msg appendArgument(readMessageChain, brackets)
    readChar(brackets last, open)
    msg
  )

  readSymbol = method(
    unless(at colonSingle?, 
      error!("Expected colon at start of symbol literal- got "+at))
    msg = newMsg(nil)
    read
    if(at quote?,
      txt = readText
      msg literal = txt literal
      msg type = :symbolText
      ,
      identifier = readIdentifier
      msg text = identifier text
      msg type = :symbolIdentifier
    )
    msg
  )

  readChar = method(expected, open nil,
    unless(at ?(expected),
      msg = "Expected char #{expected inspect}"
      if(open, msg += " because seen #{open}")
      msg += " but got #{at}"
      error!(msg))
    read
  )

  readText = method(left nil, right left, escapes: nil,
    msg = newMsg(:text)

    if(left nil?,
      if(at textStartLit?,
        left = read + read
        right = at textEnd,
        left = read
        right = left
        ),
      read)
    
    interpolate? = left != "'"
    parts = list
    sb = nil
    loop(
      if(at eof?,
        error!("Expected end of text, found "+at)
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
            if(fwd ?(at textEscapes, right),
              sb << read << read,
              if(escapes && fwd?(escapes, right),
                sb << read << read,
                error!("Undefined text escape "+at))
      ))))
      if(interpolate? && at interpolateStart?,
        parts << sb asText
        body = newMsg(:operator, "$")
        body position = at position
        sb = nil
        read
        open = at
        read
        body appendArgument(readMessageChain)
        parts << body
        readChar(at interpolateEnd, open)
      )
      if(at ?(right),
        read.
        if(sb, parts << sb asText)
        break
      )
      unless(sb, sb = newSb)
      sb << read
    )

    msg literal = dict(parts: parts, left: left, right: right)
    msg
  )

  readRegexp = method(
    unless(at regexpStart?,
      error!("Expected char "+expected inspect+" got "+at))
    read
    msg = readText("$/", "/", escapes: true)
    flags = nil
    while(at regexpFlags?, 
      unless(flags, flags = newSb)
      flags << read)
    if(flags, flags = flags asText)
    engine = nil
    if(at colonSingle?,
      read
      engine = readIdentifier text)
    msg type = :regexp
    msg literal[:flags] = flags
    msg literal[:engine] = engine
    msg
  )

  readNumber = method(
    pos = at position
    msg = nil
    if(at ?("0"),
      if(fwd ?("x", "X"),
        read.read.
        msg = readHexadecimalNumber,
        if(fwd ?("b", "B"),
          read. read.
          msg = readBinaryNumber,
          if(fwd ?("o", "O"),
            read. read.
            msg = readOctalNumber,
            if(fwd octal?,
              read.
              msg = readOctalNumber,
              msg = readDecimalNumber,
              )))),
      msg = readDecimalNumber)
    msg position = pos
    msg
  )

  readHexadecimalNumber = method(howManyChars nil,
    msg = newMsg(:hexNumber)
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
    msg text = sb asText
    msg
  )

  readOctalNumber = method(
    msg = newMsg(:octNumber)
    unless(at octal?,
      error!("Invalid char in octal number literal - got "+at))
    sb = newSb
    while(at octal? || (at sub? || fwd octal?),
      if(at sub?, read)
      sb << read)
    msg text = sb asText
    msg
  )

  readBinaryNumber = method(
    msg = newMsg(:binNumber)
    unless(at binary?,
      error!("Invalid char in binary number literal - got "+at))
    sb = newSb
    while(at binary? || (at sub? || fwd binary?),
      if(at sub?, read)
      sb << read)
    msg text = sb asText
    msg
  )

  readDecimalNumber = method(
    msg = newMsg(:decNumber)
    integer = readDecimalInteger
    fraction = nil
    exponent = nil
    
    if(at ?(".") && fwd decimal?,
      read
      fraction = readDecimalInteger)
      
    if(at ?("e", "E") && (fwd adition? || fwd decimal?),
      read
      exponent = readDecimalExponent)
      
    msg literal = dict(
      integer: integer text,
      fraction: if(fraction, fraction text, nil),
      exponent: if(exponent, exponent text, nil)
    )

    msg
  )

  readDecimalInteger = method(
    msg = newMsg(:decInteger)
    unless(at decimal?,
      error!("Invalid char in decimal number literal - got "+at))
    sb = newSb
    sb << read
    while(at decimal? || (at sub? && fwd decimal?),
      if(at sub?, read)
      sb << read)
    msg text = sb asText
    msg
  )

  readDecimalExponent = method(
    msg = newMsg(:decExponent)
    unless(at decimal? || at adition?,
      error!("Invalid char in decimal exponent literal - got "+at))
    sign = "+"
    if(at adition?, sign = read)
    exp = readDecimalInteger
    msg text = sign + exp text
    msg
  )

  readSpace = method(
    msg = newMsg(:space)
    sb = newSb
    while(at space? || at escapedEol?,
      if(at escapedEol?,
        read
        sb << " ",
        if(at lineComment?,
          until(at eol?, read),
          sb << read)))
    msg text = sb asText
    msg
  )

  readDocument = method(
    msg = newMsg(:document)
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
    msg text = sb asText
    msg
  )

)

