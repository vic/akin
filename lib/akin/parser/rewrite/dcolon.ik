
Akin Parser Rewrite DColon = Origin mimic
Akin Parser Rewrite DColon do(
  
  rewrite = method(chain,
    m = chain
    while(m,
      if(m next && m next next && m next dcolonArgOp?, 
        m = m next next
        chain = process(m previous) first
      )
      if(m body && m body message, rewrite(m body message))
      m = m next)
    chain
  )

  process = method(dcolon,
    first = dcolon firstInLine findForward(white? not)
    into = dcolon next findForward(white? not)
    upto = dcolon previous

    nl = first previous
    nl next = into
    into previous = nl

    first previous = nil
    upto next = nil

    into appendArgument(first)
    into
  )

)
