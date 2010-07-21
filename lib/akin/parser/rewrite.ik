
Akin Parser Rewrite = Origin mimic
use("akin/parser/rewrite/colon")
use("akin/parser/rewrite/dcolon")
use("akin/parser/rewrite/precedence")
use("akin/parser/rewrite/binary")

Akin Parser Rewrite do(

  initialize = method(
    @operators = Akin Parser Rewrite Precedence mimic
    @levels = list
  )

  level = method(
    levels unshift!(Akin Parser Rewrite Level mimic(self))
    currentLevel
  )
  
  currentLevel = method(levels first)

  rewriters = list(
    Akin Parser Rewrite Colon,
    Akin Parser Rewrite DColon,
    Akin Parser Rewrite Binary
  )

)

Akin Parser Rewrite Level = Origin mimic
Akin Parser Rewrite Level do(

  initialize = method(rw,
    @rw = rw
    @stack = list
  )

  add = method(msg,
    direction = nil
    match = rw rewriters find(r, direction = r apply?(msg, self))
    if(match,
      rewriter = match mimic(msg, self)
      if(direction == :fwd,
        stack push!(rewriter),
        stack unshift!(rewriter)
      )
    )
  )

  finish = method(
    msg = nil
    until(stack empty?, 
      m = stack shift! rewrite!
      if(m, msg = m)
    )
    msg && msg first
  )

  precedence = method(msg, rw operators precedence(msg))

  rightAssociative? = method(msg,
    rw operators rightAssociative?(msg))

  leftUnary? = method(msg,
    rw operators leftUnary?(msg))

  assign? = method(msg, rw operators assignment?(msg))

)
