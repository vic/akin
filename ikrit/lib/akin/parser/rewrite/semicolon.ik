Akin Parser Rewrite Semicolon = Origin mimic
Akin Parser Rewrite Semicolon do(
   
  initialize = method(
    @stack = list
  )

  add = method(msg, level,
    if(msg semicolon? && msg body nil?, stack unshift!(msg))
  )

  finish = method(level,
    until(stack empty?,
      msg = stack shift!
      if(msg semicolon? && msg body nil?, replace(msg))
    )
  )

  replace = method(msg,
    bwd = msg bwd
    fwd = msg fwd
    while(bwd && bwd invisible?, bwd = bwd detach first)
    while(fwd && fwd invisible?, fwd = fwd detach last)
    msg text = " "
    msg type = :space
  )

)
