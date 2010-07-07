use("akin/message")

Akin Parser = Origin mimic

use("akin/parser/at")
use("akin/parser/reader")
use("akin/parser/string")

Akin Parser do(

  parseText = method(text, filename: "<Text:#{text hash}>" , line: 1, col: 1, pos: 1,
    sr = java:io:StringReader new(text)
    position = Akin Parser Position mimic(filename, line, col, pos)
    at = Akin Parser At mimic(sr, position)
    Akin Parser MessageReader mimic(at) readMessageChain
  )

  parseURI = method(uri,
    sr = java:io:InputStreamReader new(java:net:URL new(uri) openStream)
    pos = Akin Parser Position mimic(uri, 1, 1, 1)
    at = Akin Parser At mimic(sr, pos)
    Akin Parser MessageReader mimic(at) readMessageChain
  )

)

Akin Parser Position = Origin mimic
Akin Parser Position do(
  
  initialize = method(file, line, column, pos,
    @file = file
    @line = line
    @column = column
    @pos = pos
  )
  
  asText = method("#{file} @[ln:#{line},col:#{column},pos:#{pos}]")
  next = method(n 1,Akin Parser Position mimic(file, line, column + n, pos + n))
  nextLine = method(n 1, Akin Parser Position mimic(file, line + n, 1, pos + n))
  asList = method(list(file, line, column, pos))

)
