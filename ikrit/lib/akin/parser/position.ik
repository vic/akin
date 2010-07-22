

Akin Parser position = method(source:, line:, column:, position:,
  data = Akin Parser Position Data mimic(
    source, line, column, position)
  Akin Parser Position mimic(data)
)

Akin Parser Position = Origin mimic
Akin Parser Position do(
  
  initialize = method(logical, physical logical,
    @logical = logical
    @physical = physical
  )
  
  fwd = method(
    newPhy = physical fwd
    newLog = if(logical == physical, newPhy, logical fwd)
    Akin Parser Position mimic(newLog, newPhy)
  )

  fwdLine = method(
    newPhy = physical fwdLine
    newLog = if(logical == physical, newPhy, logical fwdLine)
    Akin Parser Position mimic(newLog, newPhy)
  )

  fwdEscaped = method(
    newPhy = physical fwd fwdLine
    newLog = logical fwd
    Akin Parser Position mimic(newLog, newPhy)
  )

)

Akin Parser Position Data = Origin mimic
Akin Parser Position Data do(

  initialize = method(source, line, column, position,
    @source = source
    @line = line
    @column = column
    @position = position
  )

  asText = method(
    "#{source} @[ln:#{line},col:#{column},position:#{position}]")
  
  fwd = method(n 1, 
    Akin Parser Position Data mimic(
      source, line, column + n, position + n))

  fwdLine = method(n 1, 
    Akin Parser Position Data mimic(
      source, line + n, 1, position + n))
  
  asList = method(list(source, line, column, position))

  notice = method(asText)

)
