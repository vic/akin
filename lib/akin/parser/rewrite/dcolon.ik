
Akin Parser Rewrite DColon = Origin mimic
Akin Parser Rewrite DColon do(
  
  rewrite = method(chain,
    m = chain
    while(m,
      if(m fwd && m fwd fwd && m fwd dcolonArgOp?, 
        m = m fwd fwd
        chain = process(m bwd) first
      )
      if(m body && m body message, rewrite(m body message))
      m = m fwd)
    chain
  )

  process = method(dcolon,
    first = dcolon firstInLine findForward(white? not)
    into = dcolon fwd findForward(white? not)
    upto = dcolon bwd

    nl = first bwd
    nl fwd = into
    into bwd = nl

    first bwd = nil
    upto fwd = nil

    into appendArgument(first)
    into
  )

)
