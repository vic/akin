
Akin Parser At = Origin mimic
Akin Parser At do(

  initialize = method(reader, position, char nil,
    @reader = reader. @position = position
    if(char, @char = char)
  )

  asText = method("character "+ Akin Parser String desc(char) + " at " +position)

  char = method(@char = reader read asRational)

  next = method(
    nextChar = reader read asRational
    nextPosition = position next
    if(match?(nextChar, eol), nextPosition = nextLine)
    @next = Akin Parser At mimic(reader, nextPosition, nextChar)
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

  eol? = method(?(eol_chars))
  eol = list("\n", "\r")

  eof? = method(?(-1))

  space? = method(?(" ","\u0009","\u000b","\u000c"))

  blank? = method(space? || eol?)

  terminator? = method(?(".", ",", ";", "\n", "\r"))

  alpha? = method(?("a".."z", "A".."Z"))

  identifier? = method(alpha? || decimal? || sub? || ?(":", "$"))

  leftBracket? = method(?(brackets map(first)))

  rightBracket? = method(?(brackets map(second)))

  brackets = list(
    list("(", ")"),
    list("[", "]"),
    list("{", "}"),
    list("⟨", "⟩")
  )
  
)
