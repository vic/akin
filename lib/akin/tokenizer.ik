Akin Tokenizer = Origin mimic

use("akin/tokenizer/at")
use("akin/tokenizer/message")
use("akin/tokenizer/reader")
use("akin/tokenizer/string")

Akin Tokenizer do(

  parseText = method(text, filename: "<Text:#{text hash}>" , line: 1, col: 1, pos: 1,
    sr = java:io:StringReader new(text)
    position = Akin Tokenizer Position mimic(filename, line, col, pos)
    at = Akin Tokenizer At mimic(sr, position)
    Akin Tokenizer MessageReader mimic(at) readMessageChain
  )

  parseURI = method(uri,
    sr = java:io:InputStreamReader new(java:net:URL new(uri) openStream)
    pos = Akin Tokenizer Position mimic(uri, 1, 1, 1)
    at = Akin Tokenizer At mimic(sr, pos)
    Akin Tokenizer MessageReader mimic(at) readMessageChain
  )

)

Akin Tokenizer Position = Origin mimic
Akin Tokenizer Position do(
  
  initialize = method(file, line, column, pos,
    @file = file
    @line = line
    @column = column
    @pos = pos
  )
  
  asText = method("#{file} @[ln:#{line},col:#{column},pos:#{pos}]")
  next = method(n 1, Akin Tokenizer Position mimic(file, line, column + n, pos + n))
  nextLine = method(n 1, Akin Tokenizer Position mimic(file, line + n, 1, pos + n))
  asList = method(list(file, line, column, pos))

)
