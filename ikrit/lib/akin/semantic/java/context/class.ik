let(
  Java, Akin Semantic Java,
  Context, Akin Semantic Java Context,
  

  Context Class = Java create:ctx
  Context Class cell("operator:=()") = method(msg, receiver, 
    lhs = node process(msg body arg(0)) last
    rhs = node process(msg body arg(1)) last

    asg = Java Assignment mimic(receiver, lhs, rhs)
    
    list(self, msg fwd, asg)
  )

)
