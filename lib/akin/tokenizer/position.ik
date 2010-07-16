

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
  
  fwd = method(
    newPhy = physical fwd
    newLog = if(logical == physical, newPhy, logical fwd)
    Akin Tokenizer Position mimic(newLog, newPhy)
  )

  fwdLine = method(
    newPhy = physical fwdLine
    newLog = if(logical == physical, newPhy, logical fwdLine)
    Akin Tokenizer Position mimic(newLog, newPhy)
  )

  fwdEscaped = method(
    newPhy = physical fwd fwdLine
    newLog = logical fwd
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
  
  fwd = method(n 1, 
    Akin Tokenizer Position Data mimic(
      source, line, column + n, position + n))

  fwdLine = method(n 1, 
    Akin Tokenizer Position Data mimic(
      source, line + n, 1, position + n))
  
  asList = method(list(source, line, column, position))

  notice = method(asText)

)
