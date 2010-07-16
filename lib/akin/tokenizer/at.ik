
Akin Tokenizer At = Origin mimic
Akin Tokenizer At do(

  initialize = method(reader, position, char nil,
    @reader = reader
    @position = position
    @cached:n = nil
    if(char, @char = char)
  )

  reader:read = method(reader read asRational)

  char = method(@char = reader:read)
  text = method(Akin Tokenizer String txt(char))

  asText = method("character "+ Akin Tokenizer String desc(char) + " at " +phyPos)

  eol? = method(
    if(match?(char, "\n", "\u000C", "\u0085", "\u2028", "\u2029"),
      return true)
    if(match?(char, "\r"),
      @cached:n = cached:n || reader:read
      if(match?(cached:n, "\n"), @cached:n = reader:read)
      return true)
    false
  )

  escapedEol? = method(
    if(match?(char, "\\"),
      @cached:n = cached:n || reader:read
      if(match?(cached:n, "\n", "\u000C", "\u0085", "\u2028", "\u2029"),
        return true)
      if(match?(cached:n, "\r"),
        @cached:n = reader:read
        if(match?(cached:n, "\n"), @cached:n = reader:read)
        return true)
    )
    false
  )

  fwd = method(
    pos = position fwd
    if(escapedEol?,
      @cached:n = reader:read
      pos = position fwdEscaped,
      if(eol?, pos = position fwdLine)
    )
    @fwd = Akin Tokenizer At mimic(reader, pos, cached:n)
  )
  
  ? = method(+items, 
    items flatten any?(i, 
      if(i is?(Text) && i length > 1,
        m = self
        i chars all?(c,
          if(Akin Tokenizer String charMatch?(m char, c),
            m = m fwd
            true,
            false
          )
        )
        ,
        Akin Tokenizer String charMatch?(char, i)
    ))
  )

  match? = method(char, +items, 
    items flatten any?(i, Akin Tokenizer String charMatch?(char, i)))

  adition? = method(?("+", "-"))

  sub? = method(?("_"))

  binary? = method(?("0", "1"))
  
  decimal? = method(?("0".."9"))

  octal? = method(?("0".."7"))
  
  hexadecimal? = method(?("0".."9", "a".."f", "A".."F"))

  eof? = method(?(-1))
  tab? = method(?("\t"))

  lineComment? = method( ?("#") && (fwd ?("!", "#") || fwd space?) )

  docStart? = method( ?("/") && fwd ?("*"))
  docStart2? = method( ?("/") && fwd ?("*") && fwd fwd ?("*"))
  docStart3? = method( ?("/") && fwd ?("*") && fwd fwd ?("*") && fwd fwd fwd ?("*"))
  docEnd? = method(?("*") && fwd ?("/"))
  docStar? = method(?("*") && fwd ?("/") not)
  docBlank? = method(blank? || docStar?)

  space? = method(?(" ", "\t", "\u0009","\u000b","\u000c") || escapedEol?)
  blank? = method(space? || lineComment?)

  terminator? = method(eol? || (?(".") && fwd ?(".") not))
  enumerator? = method(?(",") && fwd ?(",") not)
  separator? = method(?(";") && fwd ?(";") not)
  colon? = method(?(":") && fwd ?(":") not)

  punctuation? = method(terminator? || enumerator? || separator?)

  symbolStart? = method(colon? && (fwd ?("\"") || fwd symbol?))
  symbol? = method(alpha? || decimal? || sub? || ?("?", "$"))

  backslash? = method(?("\\"))

  alpha? = method(?("a".."z", "A".."Z"))

  quote? = method(doubleQuote? || singleQuote?)
  doubleQuote? = method(?("\""))
  singleQuote? = method(?("'"))

  textStart? = method(doubleQuote? || textStartLit?)
  textStartLit? = method(?(textStartLit))
  textStartLit = "$["
  textEnd = "]"
  textEscapes = list("b", "t", "n", "f", "r", "\\", "\n", "#", "e")

  interpolateStart? = method(?(interpolateStart))
  interpolateStart = "$("
  interpolateEnd = ")"

  regexpStart? = method(?(regexpStart))
  regexpStart = "$/"
  regexpEnd = "/"
  regexpFlags? = method(?(regexpFlags))
  regexpFlags = list("u", "m", "i", "x", "s")

  identifier? = method(alpha? || decimal? || sub? || ?(":", "?", "$"))

  operator? = method(?(
      "°","!","\"","#","$",
      "%","&","/","<", ">",
      "=","?","¡","@","ł",
      "€","¶","ŧ","↓","→",
      "ø","þ","æ","ß","ð",
      "đ","ŋ","ħ","j","ĸ",
      "ł","~","«","»","¢",
      "“","”","µ","¬",
      "|","·","½","\\","¿",
      "'","+","*","^","`",
      "̣̣¸","_","-", ":",";",
      ",", "."))

  bracket? = method(leftBracket? || rightBracket?)

  leftBracket? = method(?(Akin Tokenizer Message Body brackets map(first)))

  rightBracket? = method(?(Akin Tokenizer Message Body brackets map(second)))

)
