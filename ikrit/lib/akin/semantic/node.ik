Akin Semantic Node = Origin mimic

Akin Semantic Node process = method(chain, rec nil,
  state = list(context, chain, rec)
  while(state && state first && state second,
    ctx = state first
    msg = state second
    receiver = state third

    orig = "#{msg type}:#{msg text}"
    if(msg body, orig += msg body brackets join(""))

    cond(
      
      msg terminator?,
      state = list(context, msg fwd, rec),

      !msg expression?,
      state = list(context, msg fwd, receiver),

      ctx cell?(orig), 
      state = ctx send(orig, msg, receiver),

      name = "any:#{msg type}"
      if(msg body, name += msg body brackets join(""))
      ctx cell?(name),
      state = ctx send(name, msg, receiver),

      
      name = "any:missing"
      ctx cell?(name),
      state = ctx send(name, msg, receiver),

      true,
      error!("Unknown message #{receiver}##{orig}"+
        " at #{msg position physical} "+
        " on #{ctx}")
    )
  )
)

