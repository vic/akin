

Akin Tokenizer position = method(source:, line:, column:, position:,
  data = Akin Tokenizer Position Data mimic(
    source, line, column, position)
  Akin Tokenizer Position mimic(data)
)

Akin Tokenizer Position = Origin mimic
Akin Tokenizer Position do(
  
  initialize = method(logical, physical logical,
    @logical = logical
    @physical = physical
  )
  
  next = method(
    newPhy = physical next
    newLog = if(logical == physical, newPhy, logical next)
    Akin Tokenizer Position mimic(newLog, newPhy)
  )

  nextLine = method(
    newPhy = physical nextLine
    newLog = if(logical == physical, newPhy, logical nextLine)
    Akin Tokenizer Position mimic(newLog, newPhy)
  )

  nextEscaped = method(
    newPhy = physical next nextLine
    newLog = logical next
    Akin Tokenizer Position mimic(newLog, newPhy)
  )

)

Akin Tokenizer Position Data = Origin mimic
Akin Tokenizer Position Data do(

  initialize = method(source, line, column, position,
    @source = source
    @line = line
    @column = column
    @position = position
  )

  asText = method(
    "#{source} @[ln:#{line},col:#{column},position:#{position}]")
  
  next = method(n 1, 
    Akin Tokenizer Position Data mimic(
      source, line, column + n, position + n))

  nextLine = method(n 1, 
    Akin Tokenizer Position Data mimic(
      source, line + n, 1, position + n))
  
  asList = method(list(source, line, column, position))

  notice = method(asText)

)
