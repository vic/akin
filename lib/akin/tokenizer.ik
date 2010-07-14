Akin Tokenizer = Origin mimic

use("akin/tokenizer/at")
use("akin/tokenizer/message")
use("akin/tokenizer/reader")
use("akin/tokenizer/string")
use("akin/tokenizer/position")

Akin Tokenizer do(

  parseText = method(text, filename: "<Text:#{text hash}>" , line: 1, col: 1, pos: 1,
    sr = java:io:StringReader new(text)
    position = Akin Tokenizer position(
      source: filename, line: line, column: col, position: pos)
    at = Akin Tokenizer At mimic(sr, position)
    Akin Tokenizer MessageReader mimic(at) readMessageChain
  )

  parseURI = method(uri,
    sr = java:io:InputStreamReader new(java:net:URL new(uri) openStream)
    pos = Akin Tokenizer Position position(
      source: uri, line: 1, column: 1, position: 1)
    at = Akin Tokenizer At mimic(sr, pos)
    Akin Tokenizer MessageReader mimic(at) readMessageChain
  )

)

