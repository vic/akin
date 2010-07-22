Akin Semantic Node = Origin mimic

let(
  Node, Akin Semantic Node,

  Node create:node = method(object,
    object context = Context cell(object kind split last) mimic(object)
    object process = Akin Semantic Node cell(:process)
    object
  )

  
  Node process = method(chain,
    state = list(context, chain, nil)
    while(state && state first && state second,
      ctx = state first
      msg = state second
      receiver = state third
      if(msg terminator?,
        state = list(context, msg fwd, nil),
        if(msg expression?,
          orig = "#{msg type}:#{msg text}"
          if(msg body, orig += msg body brackets join(""))
          name = orig
          if(ctx cell?(name), 
            state = ctx send(name, msg, receiver),
            name = "any:#{msg type}"
            if(msg body, name += msg body brackets join(""))
            if(ctx cell?(name),
              state = ctx send(name, msg, receiver),
              name = "any:missing"
              if(ctx cell?(name),
                state = ctx send(name, msg, receiver),
                error!("Unknown message #{receiver}##{orig}"+
                  " at #{msg position physical} "+
                  " on #{ctx}")
              )
            )
          )
        )
      )
    )
  )
  
)
