
Akin Parser Rewrite Colon = Origin mimic
Akin Parser Rewrite Colon do(

  rewrite = method(chain,
    m = chain
    while(m,
      if(m fwd && m fwd colonArgOp?, process(m fwd))
      if(m body && m body message, rewrite(m body message))
      m = m fwd)
    chain
  )

  process = method(colon,
    first = colon firstInLine
    into = colon bwd
    sb = Akin Tokenizer StringBuilder mimic
    sb << into name
    end = nil
    msg = colon
    while(msg = msg fwd,
      end = msg
      if(msg end?, break)
      if((msg sameColumn?(first, usePosition: nil) ||
          msg sameColumn?(into, usePosition: nil)) &&
        msg fwd && msg fwd colonArgOp?,
        if(msg body nil?,
          sb << ":" << msg name
          msg name = :(",")
          msg fwd detach,

          comma = newMsg(:",")
          comma bwd = msg bwd
          comma fwd = msg
          msg bwd fwd = comma
          msg fwd name = :(",")
        )
        continue
      )
      if(msg fwd && msg fwd colonArgOp?,
        process(msg fwd)
        if(msg body && msg body message,
          rewrite(msg body message))
      )
      if(!msg white? && msg position logical column <= first position logical column,
        end = msg firstInLine bwd
        break)
    )
    into fwd = end fwd
    if(into fwd, into fwd bwd = into)
    body = colon fwd
    body bwd = nil
    end fwd = nil
    into name = :(sb asText)
    into appendArgument(body)
    into
  )

  newMsg = method(+args, +:kargs,
    Akin Tokenizer Message mimic(*args, *kargs)
  )
  
)

