
Akin Tokenizer MessageReader = Origin mimic
Akin Tokenizer MessageReader do(

  initialize = method(at, @at = at)

  read = method(
    txt = Akin Tokenizer String txt(at char)
    @at = at succ
    txt
  )

  succ = method(at succ)

  newMsg = method(+rest, +:krest,
    krest[:position] = at position
    Akin Tokenizer Message mimic(*rest, *krest)
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
    if(at punctuation?, return readPunctuation)
    if(at space?, return readSpace)
    if(at leftBracket?, return readActivation)
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
      if(at ?(":"), 
        if(succ identifier?, 
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
    while(at operator?, sb << read)
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

  readActivation = method(
    brackets = Akin Tokenizer Message Body brackets assoc(read)
    unless(brackets, error!("Unknown left bracket -  "+at))
    msg = newMsg(:activation)
    msg appendArgument(readMessageChain, brackets)
    readChar(brackets last)
    msg
  )

  readSymbol = method(
    unless(at colon?, 
      error!("Expected colon at start of symbol literal- got "+at))
    msg = newMsg(:symbol)
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

  readChar = method(expected,
    unless(at ?(expected),
      error!("Expected char "+expected inspect+" got "+at))
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
        if(succ eol?,
          read. read,
          if(succ ?("u", "U"),
            read. read.
            hex = readHexadecimalNumber(4) literal text
            sb << "\\u" << hex,
            if(succ octal?,
              sb << read << succ char
              if(at ?("0".."3"),
                if(succ octal?,
                  sb << read
                  if(succ octal?,
                    sb << read
                    )),
                if(succ octal?,
                  sb << read
                )
                )),
            if(succ ?(at textEscapes, right),
              sb << read << read,
              if(escapes && succ?(escapes, right),
                sb << read << read,
                error!("Undefined text escape "+at))
      ))))
      if(interpolate? && at interpolateStart?,
        parts << sb asText
        sb = nil
        read. read.
        body = readMessageChain
        parts << body
        readChar(at interpolateEnd)
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
    if(at colon?,
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
      if(succ ?("x", "X"),
        read.read.
        msg = readHexadecimalNumber,
        if(succ ?("b", "B"),
          read. read.
          msg = readBinaryNumber,
          if(succ ?("o", "O"),
            read. read.
            msg = readOctalNumber,
            read.
            msg = readOctalNumber))),
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
    while(seek && (at hexadecimal? || (at sub? || succ hexadecimal?)),
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
    while(at octal? || (at sub? || succ octal?),
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
    while(at binary? || (at sub? || succ binary?),
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
    
    if(at ?(".") && succ decimal?,
      read
      fraction = readDecimalInteger)
      
    if(at ?("e", "E") && (succ adition? || succ decimal?),
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
    while(at decimal? || (at sub? && succ decimal?),
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

