
Akin Parser Rewrite Colon = Origin mimic
Akin Parser Rewrite Colon do(

  rewrite = method(chain,
    m = chain
    while(m,
      if(m succ && m succ colonArgOp?, process(m succ))
      if(m body && m body message, rewrite(m body message))
      m = m succ)
    chain
  )

  process = method(colon,
    first = colon firstInLine
    into = colon prec
    sb = Akin Tokenizer StringBuilder mimic
    sb << into name
    end = nil
    msg = colon
    while(msg = msg succ,
      end = msg
      if(msg end?, break)
      if((msg sameColumn?(first, usePosition: nil) ||
          msg sameColumn?(into, usePosition: nil)) &&
        msg succ && msg succ colonArgOp?,
        if(msg body nil?,
          sb << ":" << msg name
          msg name = :(",")
          msg succ detach,

          comma = newMsg(:",")
          comma prec = msg prec
          comma succ = msg
          msg prec succ = comma
          msg succ name = :(",")
        )
        continue
      )
      if(msg succ && msg succ colonArgOp?,
        process(msg succ)
        if(msg body && msg body message,
          rewrite(msg body message))
      )
      if(!msg white? && msg position logical column <= first position logical column,
        end = msg firstInLine prec
        break)
    )
    into succ = end succ
    if(into succ, into succ prec = into)
    body = colon succ
    body prec = nil
    end succ = nil
    into name = :(sb asText)
    into appendArgument(body)
    into
  )

  newMsg = method(+args, +:kargs,
    Akin Tokenizer Message mimic(*args, *kargs)
  )
  
)

