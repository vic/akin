

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
  
  succ = method(
    newPhy = physical succ
    newLog = if(logical == physical, newPhy, logical succ)
    Akin Tokenizer Position mimic(newLog, newPhy)
  )

  succLine = method(
    newPhy = physical succLine
    newLog = if(logical == physical, newPhy, logical succLine)
    Akin Tokenizer Position mimic(newLog, newPhy)
  )

  succEscaped = method(
    newPhy = physical succ succLine
    newLog = logical succ
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
  
  succ = method(n 1, 
    Akin Tokenizer Position Data mimic(
      source, line, column + n, position + n))

  succLine = method(n 1, 
    Akin Tokenizer Position Data mimic(
      source, line + n, 1, position + n))
  
  asList = method(list(source, line, column, position))

  notice = method(asText)

)
