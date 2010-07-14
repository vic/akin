
Akin Parser Rewrite DColon = Origin mimic
Akin Parser Rewrite DColon do(
  
  rewrite = method(chain,
    m = chain
    while(m,
      if(m succ && m succ succ && m succ dcolonArgOp?, 
        m = m succ succ
        chain = process(m prec) first
      )
      if(m body && m body message, rewrite(m body message))
      m = m succ)
    chain
  )

  process = method(dcolon,
    first = dcolon firstInLine findForward(white? not)
    into = dcolon succ findForward(white? not)
    upto = dcolon prec

    nl = first prec
    nl succ = into
    into prec = nl

    first prec = nil
    upto succ = nil

    into appendArgument(first)
    into
  )

)
