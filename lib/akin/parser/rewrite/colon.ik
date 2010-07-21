
Akin Parser Rewrite Colon = Origin mimic
Akin Parser Rewrite Colon do(
  
  apply? = method(msg, rw,
    msg && msg text == ":"  && msg body nil?
  )

  initialize = method(colon, rw,
    @colon = colon
    @rw = rw
  )

  rewrite! = method(
    unless(apply?(colon, rw) && colon fwd && colon bwd, return)
    head = colon firstInLine
    if(head invisible?, head = head succ)
    into = colon prev
    end = findEnd(colon, into)
    into = findStart(head, into)

    colon = into succ

    body = colon fwd
    while(body white?, body = body detach last)
    body detachLeft
    into appendArgument(body)
    if(end terminator?,
      while(end bwd && end bwd white?, end bwd detach)
      into append(end)
      if(end semicolon?, end detach)
    )

    colon detach
    
    nil
  )

  findStart = method(head, into,
    if(head != into, return into)
    last = into
    msg = into
    names = list()
    while(msg = msg bwd,
      pos = msg position logical
      if(msg white? not && pos column < into position logical column,
        break)
      if(apply?(msg succ, rw) && 
        pos column == into position logical column,
        last succ text = ","
        last succ type = :punctuation
        if(last body,
          last bwd insert(buildComma(last bwd)),
          if(last text && last text length > 0 && 
            !names include?(last text),
            names unshift!(last text))
          last detach)
        last = msg
      )
    )
    if(last text && last text length > 0 &&
      !names include?(last text),
      names unshift!(last text)
    )
    if(names empty?,
      last literal = :code,
      last text = names join(":")
    )
    last
  )

  buildComma = method(msg nil,
    comma = Akin Parser Message mimic(:punctuation, ",")
    comma position = msg && msg position
    comma
  )

  findEnd = method(msg, into,
    end = nil
    intoPos = into position logical
    while(end nil? && msg && msg = msg fwd,
      pos = msg position logical
      if(pos line == intoPos line && msg end?,
        end = msg
        break
      )
      if(msg end? && pos column <= intoPos column,
        end = msg
        break
      )
      if(msg visible? && pos column <= intoPos column,
        end = msg findBackward(eol?)
        break
      )
      if(msg fwd nil?,
        end = msg
        break
      )
    )
    end
  )


)
