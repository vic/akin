
Akin Parser Rewrite DColon = Origin mimic
Akin Parser Rewrite DColon do(
  
  apply? = method(msg, rewrite,
    msg text == "::" && msg body nil?
  )

  initialize = method(dcolon, rw,
    @dcolon = dcolon
    @rw = rw
  )

  rewrite! = method(
    first = dcolon findBackward(eol?) || dcolon first
    last = dcolon findForward(eol?) || dcolon last
    dlimit = nil
    if(first literal == :delimit,
      dlimit = first
    )
    if(first white?, first = first succ)
    if(last white?, last = last prec)

    left =  dcolon prec
    right = dcolon succ

    prev = left findPrev(m, apply?(m, rw))

    if(first bwd,
      first bwd append(right), 
      right detachLeft)
    left detachRight

    if(prev,
      prev = Akin Parser Message mimic(:punctuation, "\n")
      prev literal = :delimit
      prev append(first)
      first = prev
    )
    last appendArgument(first)
    if(dlimit,
      dlimit detach
      nil
      ,
      right first
    )
  )

)
