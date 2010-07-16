

; Based on IoMessage_opShuffle.c from Io
; Based on Levels.java from ioke

Akin Parser Rewrite Levels = Origin mimic
Akin Parser Rewrite Levels do(

  initialize = method(
    @operators = Akin Parser Operators mimic
    @stack = list
    reset
  )

  rewrite = method(chain,
    expressions = list(chain)
    while(expressions size > 0,
      n = expressions shift!
      
      while(n,
        n = process(n, expressions)
        if(n body && n body message, 
          expressions unshift!(n body message)
        )
        n = n next
      )
      nextMessage(expressions)
    )
    chain
  )


  process = method(msg, expressions,

    final = msg

    name = msg name asText
    bwdedence = operators bwdedence(msg)
    arity = operators arity(msg)
    argsn = msg argCount
    inverted = operators inverted?(msg)

    ;; -foo bar 
    ;; becomes 
    ;; -(foo) bar
    if(argsn == 0 && name == "-" && 
      msg firstVisibleInExpr? && msg hasNextVisibleInExpr?,
      bwdedence = -1
      arg = msg next visible
      arg detach
      msg appendArgument(arg)
      argsn ++
    ) 
  
    ;;  foo :: bar
    ;;  becomes 
    ;;  bar ::(foo)
    ;;
    ;;  foo :: bar :: baz
    ;;  becomes
    ;;  bar ::(foo) :: baz
    ;;  baz ::(bar ::(foo))
    if(inverted && argsn == 0 && !msg firstVisibleInExpr?,
      
      head = msg firstInExpr visible
      beforeHead = head previous
      head previous = nil
      
      msg previous next = nil
      msg previous = nil
      
      next = msg next
      msg next = nil
      next previous = nil

      last = next
      while(last next && last next terminator? not && 
            !(operators inverted?(last next) && 
              0 == last next argCount),
        last = last next
      )
      
      cont = last next
      last next = nil
      if(cont, cont previous = nil)

      msg next = cont
      if(cont, cont previous = msg)

      msg appendArgument(head)
      argsn ++
      
      last next = msg
      msg previous = last
      
      if(beforeHead, 
        beforeHead next = next
        next previous = beforeHead
      )
      
      final = beforeHead || next
        
      currentLevel message = last
    ) 
    

    ;; o a = b c . d
    ;; becomes
    ;; o =(a, b c) . d
    if(arity != -1 && argsn == 0 && 
      !(msg next && msg next name == :"="),

      currentLevel = @currentLevel
      attaching = currentLevel message
      
      if(attaching nil?, 
        error!("Cant create trinary expression without lvalue")
      )

      ;; a = b.
      cellName = attaching name
      copyOfMessage = attaching deepCopy
      
      copyOfMessage previous = nil
      copyOfMessage next = nil
      
      attaching
    )
      
        

  )

  currentLevel = method(
    stack[0]
  )

  OP_LEVEL_MAX = 32

  reset = method(
    currentLevel = 1
    OP_LEVEL_MAX times(i, 
      pool[i] = Akin Parser Rewrite Levels Level mimic(:unused))
    level = pool[0]
    level message = nil
    level type = :new
    level bwdedence = OP_LEVEL_MAX

    stack clear!
    stack unshift!(pool[0])
  )

) 

Akin Parser Rewrite Levels Level = Origin mimic
Akin Parser Rewrite Levels Level do(

  initialize = method(type, 
    @type = type
    @message = nil)

  attach = method(msg, 
    cond(
      type == :attach,
      message next = msg,
      
      type == :arg,
      message appendArgument(msg),

      type == :new,
      @message = msg
    )
  )

  setAwaitingFirstArg = method(msg, bwdedence,
    @type = :arg
    @message = msg
    @bwdedence = bwdedence
  )

  setAlreadyHasArgs = method(msg, 
    @type = :attach
    @message = msg
  )

  finish = method(expressions, 
    @type = :unused
    if(message nil?, return)
    message next = nil
    if(message argCount == 1,
      arg0 = message arg(0)
      error!("WTF?? ")
    )
  )
  
)
