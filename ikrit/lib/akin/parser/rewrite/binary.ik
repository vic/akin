
Akin Parser Rewrite Binary = Origin mimic
Akin Parser Rewrite Binary do(

  initialize = method(
    @stack = list
  )

  add = method(msg, level,
    if(apply?(msg, level), stack unshift!(msg))
  )

  finish = method(level,
    stack each(msg, rewrite!(msg, level, level precedence(msg)))
  )
  
  apply? = method(msg, level,
    (msg type == :operator || msg type == :identifier) && 
      msg body nil? && level precedence(msg)
  )

  rewrite! = method(op, rw, precedence,
    unless(apply?(op, rw), return)
    if(rw leftUnary?(op),
      arg = op prec
      while(arg fwd space?, arg fwd detach)
      arg detach
      op appendArgument(arg)
      if(rw head == arg, rw head = op)
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
      if(rw head == lhs, rw head = op)
      op appendArgument(lhs)
    )
    op appendArgument(arg)

  )
  
)


