
Akin Parser Rewrite Binary = Origin mimic
Akin Parser Rewrite Binary do(
  
  apply? = method(msg, rw,
    (msg type == :operator || msg type == :identifier) && 
      msg body nil? && rw precedence(msg)
  )

  initialize = method(op, rw,
    @op = op
    @rw = rw
    @precedence = rw precedence(op)
  )

  rewrite! = method(
    unless(apply?(op, rw), return)
    if(rw leftUnary?(op),
      arg = op prec
      while(arg fwd space?, arg fwd detach)
      arg detach
      op appendArgument(arg)
      return op
    )
    while(op fwd && op fwd white?, op fwd detach)
    arg = op fwd
    unless(arg, return)
    arg detachLeft
    nextPr = nil
    nextOp = arg findNext(m, nextPr = rw precedence(m))
    end = nil
    cond(
      nextPr && nextPr < precedence,
      if(nextOp next,
        end = nextOp next,
        end = nextOp findForward(punctuation?)
      ),

      nextPr == precedence && rw rightAssociative?(nextOp),
      if(nextOp next,
        end = nextOp next,
        end = nextOp findForward(punctuation?)
      ),

      nextPr, 
      end = nextOp,

      true,
      end = arg findForward(punctuation?)
    )
    if(end, 
      while(end bwd space?, end = end bwd)
      op append(end))

    asgn = rw assign?(op)
    if(asgn,
      lhs = op prec
      while(lhs fwd space?, lhs fwd detach)
      lhs detach
      op appendArgument(lhs)
    )
    op appendArgument(arg)

    op
  )
  
)


