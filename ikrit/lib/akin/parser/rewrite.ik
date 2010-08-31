
Akin Parser Rewrite = Origin mimic
use("akin/parser/rewrite/indent")
use("akin/parser/rewrite/semicolon")
use("akin/parser/rewrite/precedence")
use("akin/parser/rewrite/binary")

Akin Parser Rewrite do(

  initialize = method(
    @operators = Akin Parser Rewrite Precedence mimic
    @levels = list
  )

  level = method(
    level = Akin Parser Rewrite Level mimic(operators, rewriters map(mimic))
    levels unshift!(level)
    level
  )
  
  currentLevel = method(levels first)

  rewriters = list(
    Akin Parser Rewrite Indent,
    Akin Parser Rewrite Binary,
    Akin Parser Rewrite Semicolon
  )

)

Akin Parser Rewrite Level = Origin mimic
Akin Parser Rewrite Level do(

  initialize = method(operators, rewriters,
    @operators = operators
    @rewriters = rewriters
  )

  add = method(msg, rewriters map(add(msg, self)))

  finish = method(rewriters each(finish(self)))

  precedence = method(msg, operators precedence(msg))

  rightAssociative? = method(msg, operators rightAssociative?(msg))

  leftUnary? = method(msg, operators leftUnary?(msg))

  assign? = method(msg, operators assignment?(msg))

)
