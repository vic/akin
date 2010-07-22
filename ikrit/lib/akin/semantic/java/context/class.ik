let(
  Java, Akin Semantic Java,
  Context, Akin Semantic Java Context,
  

  Context Class = Java create:ctx
  Context Class cell("identifier:private") = method(msg, receiver,
    mod = if(receiver is?(Java MemberMeta), receiver, Java MemberMeta mimic(receiver))
    mod modifiers << msg text
    list(self, msg fwd, mod)
  )
  Context Class cell("identifier:public") = Context Class cell("identifier:private")
  Context Class cell("identifier:static") = Context Class cell("identifier:private")
  Context Class cell("identifier:protected") = Context Class cell("identifier:private")
  Context Class cell("identifier:final") = Context Class cell("identifier:private")

  Context Class cell("identifier:method") = method(msg, receiver,
    meth = Java Method mimic
    list(self, msg fwd, meth)
  )

  Context Class cell("identifier:method()") = method(msg, receiver,
    meth = Java Method mimic
    
    list(self, msg fwd, meth)
  )


  Context Class cell("operator:=()") = method(msg, receiver, 
    lhs = node process(msg body arg(0)) last
    rhs = node process(msg body arg(1)) last

    cls = if(receiver is?(Java MemberMeta), receiver owner, receiver)
    mod = if(receiver is?(Java MemberMeta), receiver, Java MemberMeta mimic(cls))
    
    asg = Java Assignment mimic(receiver, lhs, rhs)

    cls members << Java Member mimic(lhs, rhs, mod)
    
    list(self, msg fwd, asg)
  )

)
