
Akin Parser At = Origin mimic
Akin Parser At do(

  initialize = method(reader, position, char nil,
    @reader = reader. @position = position.
    if(char, @char = char)
  )

  asText = method("character "+ Akin Parser String desc(char) + " at " +position)

  char = method(@char = reader read asRational)
  text = method(Akin Parser String txt(char))

  next = method(
    nextPosition = position next
    if(match?(char, eol), nextPosition = position nextLine)
    @next = Akin Parser At mimic(reader, nextPosition)
  )
  
  ? = method(+items, 
    items flatten any?(i, Akin Parser String charMatch?(char, i)))

  match? = method(char, +items, 
    items flatten any?(i, Akin Parser String charMatch?(char, i)))

  adition? = method(?("+", "-"))

  sub? = method(?("_"))

  binary? = method(?("0", "1"))

  decimal? = method(?("0".."9"))

  octal? = method(?("0".."7"))
  
  hexadecimal? = method(?("0".."9", "a".."f", "A".."F"))

  eol? = method(eof? || ?(eol))
  eol = list("\n", "\r")

  eof? = method(?(-1))

  space? = method(white? || lineComment?)
  lineComment? = method( ?("#") && next ?("!") )

  docStart? = method( ?("/") && next ?("*"))
  docStart2? = method( ?("/") && next ?("*") && next next ?("*"))
  docStart3? = method( ?("/") && next ?("*") && next next ?("*") && next next next ?("*"))
  docEnd? = method(?("*") && next ?("/"))
  docStar? = method(?("*") && next ?("/") not)
  docBlank? = method(blank? || docStar?)

  white? = method(?(" ", "\t", "\u0009","\u000b","\u000c"))
  blank? = method(white? || eol?)

  terminator? = method(?(".", "\n", "\r"))
  enumerator? = method(?(","))
  separator? = method(?(";"))
  colon? = method(?(":"))

  backslash? = method(?("\\"))

  alpha? = method(?("a".."z", "A".."Z"))

  dblquote? = method(?("\""))
  quote? = method(?("'"))

  identifier? = method(alpha? || decimal? || sub? || ?("_", ":", "?", "!", "$", "="))

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
      "̣̣¸","_","-"))

  leftBracket? = method(?(brackets map(first)))

  rightBracket? = method(?(brackets map(second)))

  brackets = list(
    list("(", ")"),
    list("[", "]"),
    list("{", "}"),
    list("⟨", "⟩")
  )
  
)
