Akin Parser Rewrite Indent = Origin mimic
Akin Parser Rewrite Indent do(

  initialize = method(
    @stack = list
    @all = list
    @last = nil
    @gotBack = nil
  )

  add = method(msg, level,
    cond(
      
      ;;a message at lower level than current head
      unindentedLessLevel?(msg),
      @last = stack pop!
      last end!(prevEOL(msg))
      @gotBack = msg,

      ;; a message at same level than current head
      unindentedHeadLevel?(msg),
      current end!(prevEOL(msg))
      if(msg end?,
        stack pop!
        @last = nil
        @gotBack = nil
        ,
        @last = stack pop!
        @gotBack = msg

        ),

      ;; eol and have msg before it, add a comma before eol
      msg eol? && needsComma? && current target lineComp(msg) == 0,
      here = msg prec
      comma = Akin Parser Message mimic(:punctuation, ",")
      comma position = here position
      here insert(comma),

      ;; end and dont even have first arg (empty)
      msg end? && awaitingFirstArg? && 
      current target lineComp(msg) == 0,
      current appendArgument(nil) ;; empty body adds braces
      current end!(msg)
      stack pop!
      @last = nil,

      ;; end at the same line than target
      msg end? && appending? && current target lineComp(msg) == 0,
      current end!(msg)
      stack pop!
      @last = nil,

      ;; first argument for current colon
      awaitingFirstArg?, 
      current appendArgument(msg),

      ;; irst argument for current colon continuation
      awaitingMoreArgs?,
      current appendArgument(msg), 

      ;; continuation on same line
      sameLineCont?(msg),
      current continueAt(msg),

      ;; new colon message as argument to current one
      current && colonOp?(msg) && msg lineComp(current head last) == 0,
      colon = Colon mimic(msg, current)
      stack push!(colon)
      all push!(stack last)
      @last = nil,
            
      ;; found a colon operator
      colonOp?(msg),
      stack push!(Colon mimic(msg))
      all push!(current)
      @last = nil,
    )
  )


  current = method(stack last)

  sameLineCont? = method(msg,
    if(colonOp?(msg), 
      colon = Colon mimic(msg)
      if(current,
        colon head lineComp(current head) == 0 &&
        current target body message != msg bwd
      )
    )
  )

  newLineCont? = method(msg,
    if(last && colonOp?(msg),
      colon = Colon mimic(msg)
      colon head columnComp(last head) == 0
    )
  )

  colonOp? = method(msg, 
    msg text == ":" && msg body nil?
  )

  unindentedLessLevel? = method(msg, 
    msg expression? && current &&
    msg lineComp(current head) > 0 &&
    msg columnComp(current head) < 0
  )

  unindentedHeadLevel? = method(msg,
    msg expression? && current &&
    msg lineComp(current head) > 0 &&
    msg columnComp(current head) == 0
  )

  prevEOL = method(msg, msg firstInLine bwd)

  finish = method(level, 

    until(all empty?, 
      colon = all pop!
      finishThis = true

      if(colon previous,

        lnCmp = colon target lineComp(colon previous target)
        if(lnCmp == 0,

          ;; On same line. Obtain the first visible msg on prev
          vsbl = colon previous target body message
          while(vsbl invisible? && vsbl fwd, vsbl = vsbl fwd)
          ;; if first vsbl is not this tag, current is cont of prev
          if(vsbl != colon target, finishThis = false)

          ,
            
          clCmp = colon target columnComp(colon previous target)

          ;; If follow on same col, current is cont of prev
          follow = colon previous target fwd fwd == (
            colon target bwd && colon target bwd bwd
          )
          sameHead = colon head == colon previous head
          if(clCmp == 0 && (sameHead || follow), 
            finishThis = false)

        )
      )
      
      if(finishThis, 
        colon finish(level),
        colon previous parts += colon parts
      )
    )
  )

  awaitingFirstArg? = method(current && current awaitingFirstArg?)
  awaitingMoreArgs? = method(current && current awaitingMoreArgs?)
  appending? = method(current && current appending?)
  needsComma? = method(appending? && current lastIsComma? not)

  Colon = Origin mimic
  Colon do(

    initialize = method(colon, previous nil, head nil,
      @colons = list(colon)
      @previous = previous
      @head = head
      unless(head,
        if(previous && target columnComp(previous target) == 0,
          head = previous head,
          head = colon firstInLine
        )
        if(head invisible?, head = head succ)
        @head = head
      )
      awaitingFirstArg!
    )

    colon = method(colons last)
    target = method(colon bwd)

    appending? = method(state == :append)

    awaitingFirstArg? = method(state == :awaitingFirstArg)
    awaitingMoreArgs? = method(state == :awaitingMoreArgs)

    lastIsComma? = method(
      lst = target body && target body message last
      if(lst,
        unless(lst visible?, lst = lst prec)
        lst comma?
      )
    )

    continueAt  = method(msg,
      colons push!(msg)
      awaitingMoreArgs!
    )

    appendArgument = method(msg, 
      if(msg, msg detachLeft)
      target appendArgument(msg)
      @state = :append
    )

    awaitingFirstArg! = method(@state = :awaitingFirstArg)
    awaitingMoreArgs! = method(@state = :awaitingMoreArgs)

    end! = method(msg,
      colon append(msg)
      if(target body && target body message,
        lst = target body message last
        if(lst comma?, lst detach)
      )
    )

    finish = method(level,
      names = list
      firstColon = colons first
      firstTarget = firstColon bwd

      colons each(i, colon,
        into = colon bwd 
        body = into body && into body message
        if( i == 0 && into type == :activation && into text nil?,
          into text = "\\" 
          into type = :block
        )
        if(i > 0 && body,
          into detach
          colon detach
          firstTarget appendArgument(body)
        )
        if(into type == :space, 
          names push!(""),
          names push!(into text)
        )
      )

      firstColon detach
      firstTarget text = names join(":")
    )

  )

)


