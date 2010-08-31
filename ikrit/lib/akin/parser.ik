Akin Parser = Origin mimic

use("akin/parser/at")
use("akin/parser/message")
use("akin/parser/reader")
use("akin/parser/string")
use("akin/parser/position")
use("akin/parser/rewrite")

Akin Parser do(

  parseText = method(text, filename: "<Text:#{text hash}>" , line: 1, col: 1, pos: 1,
    sr = java:io:StringReader new(text)
    position = Akin Parser position(
      source: filename, line: line, column: col, position: pos)
    at = Akin Parser At mimic(sr, position)
    rw = Akin Parser Rewrite mimic
    Akin Parser MessageReader mimic(at, rw) readMessageChain
  )

  parseURL = method(url, filename: url toString , line: 1, col: 1, pos: 1,
    parseInputStream(url openStream, filename: filename , line: line, col: col, pos: pos)
  )

  parseInputStream = method(is, filename: "<InputStream:#{text hash}>" , line: 1, col: 1, pos: 1,
    sr = java:io:InputStreamReader new(is)
    pos = Akin Parser position(
      source: filename, line: line, column: col, position: pos)
    at = Akin Parser At mimic(sr, pos)
    rw = Akin Parser Rewrite mimic
    Akin Parser MessageReader mimic(at, rw) readMessageChain
  )

)

