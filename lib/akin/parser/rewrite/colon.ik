
Akin Parser Rewrite Colon = Origin mimic
Akin Parser Rewrite Colon do(

  rewrite = method(chain,
    m = chain
    while(m,
      if(m next && m next colonArgOp?, process(m next))
      if(m body && m body message, rewrite(m body message))
      m = m next)
    chain
  )

  process = method(colon,
    first = colon firstInLine
    into = colon previous
    sb = Akin Tokenizer StringBuilder mimic
    sb << into name
    end = nil
    msg = colon
    while(msg = msg next,
      end = msg
      if(msg end?, break)
      if((msg sameColumn?(first, usePosition: nil) ||
          msg sameColumn?(into, usePosition: nil)) &&
        msg next && msg next colonArgOp?,
        if(msg body nil?,
          sb << ":" << msg name
          msg name = :(",")
          msg next detach,

          comma = newMsg(:",")
          comma previous = msg previous
          comma next = msg
          msg previous next = comma
          msg next name = :(",")
        )
        continue
      )
      if(msg next && msg next colonArgOp?,
        process(msg next)
        if(msg body && msg body message,
          rewrite(msg body message))
      )
      if(!msg white? && msg position logical column <= first position logical column,
        end = msg firstInLine previous
        break)
    )
    into next = end next
    if(into next, into next previous = into)
    body = colon next
    body previous = nil
    end next = nil
    into name = :(sb asText)
    into appendArgument(body)
    into
  )

  newMsg = method(+args, +:kargs,
    Akin Tokenizer Message mimic(*args, *kargs)
  )
  
)

