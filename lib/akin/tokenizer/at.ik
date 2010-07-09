
Akin Tokenizer At = Origin mimic
Akin Tokenizer At do(

  initialize = method(reader, position, char nil,
    @reader = reader. @position = position.
    if(char, @char = char)
  )

  asText = method("character "+ Akin Tokenizer String desc(char) + " at " +position)

  char = method(@char = reader read asRational)
  text = method(Akin Tokenizer String txt(char))

  next = method(
    nextPosition = position next
    if(match?(char, eol), nextPosition = position nextLine)
    @next = Akin Tokenizer At mimic(reader, nextPosition)
  )
  
  ? = method(+items, 
    items flatten any?(i, Akin Tokenizer String charMatch?(char, i)))

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
  eol? = method(?(eol))
  eol = list("\n", "\r")

  lineComment? = method( ?("#") && next ?("!") )

  docStart? = method( ?("/") && next ?("*"))
  docStart2? = method( ?("/") && next ?("*") && next next ?("*"))
  docStart3? = method( ?("/") && next ?("*") && next next ?("*") && next next next ?("*"))
  docEnd? = method(?("*") && next ?("/"))
  docStar? = method(?("*") && next ?("/") not)
  docBlank? = method(blank? || docStar?)

  space? = method(?(" ", "\t", "\u0009","\u000b","\u000c"))
  blank? = method(space? || lineComment?)

  terminator? = method(eol? || (?(".") && next ?(".") not))
  enumerator? = method(?(",") && next ?(",") not)
  separator? = method(?(";") && next ?(";") not)
  colon? = method(?(":") && next ?(":") not)

  single? = method(terminator? || enumerator? || separator?)

  symbolStart? = method(colon? && !next blank?)
  
  symbol? = method(identifier?)

  backslash? = method(?("\\"))

  alpha? = method(?("a".."z", "A".."Z"))

  quote? = method(doubleQuote? || singleQuote?)
  doubleQuote? = method(?("\""))
  singleQuote? = method(?("'"))

  textStart? = method(doubleQuote?)

  identifier? = method(alpha? || decimal? || sub?)

  operator? = method(?(
      "°","!","\"","#","$",
      "%","&","/","<", ">",
      "=","?","¡","@","ł",
      "€","¶","ŧ","↓","→",
      "ø","þ","æ","ß","ð",
      "đ","ŋ","ħ","j","ĸ",
      "ł","~","«","»","¢",
      "“","”","n","µ","¬",
      "|","·","½","\\","¿",
      "'","+","*","^","`",
      "̣̣¸","_","-", ":", 
      ",", "."))

  bracket? = method(leftBracket? || rightBracket?)

  leftBracket? = method(?(Akin Tokenizer Message Body brackets map(first)))

  rightBracket? = method(?(Akin Tokenizer Message Body brackets map(second)))

)
