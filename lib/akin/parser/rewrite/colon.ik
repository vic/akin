
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
    body = colon
    end = nil
    sb = Akin Tokenizer StringBuilder mimic
    sb << into name
    while(body = body next,
      end = body
      if(body end?, break)
      if((body sameColumn?(first) || body sameColumn?(colon)) &&
        body next && body next colonArgOp?,
        if(body body nil?,
          sb << ":" << body name
          body name = :(",")
          body next detach,

          body previous 
          comma = newMsg(:",")
          comma previous = body previous
          comma next = body
          body previous next = comma
          body next name = :(",")
        )
        continue
      )
      if(body next && body next colonArgOp?,
        process(body next)
        if(body body && body body message,
          rewrite(body body message))
      )
      if(!body white? && body logPos column <= first logPos column,
        end = body firstInLine previous
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

