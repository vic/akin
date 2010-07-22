let(
  Java, Akin Semantic Java,
  Context, Akin Semantic Java Context,
  

  Context Script = Java create:ctx
  Context Script cell("identifier:package()") = method(msg, receiver,
    name = msg body message select(visible?) map(text)
    pkg = node world packages find(p, p name == name)
    unless(pkg,
      pkg = Java Package mimic(name)
      node world packages << pkg
    )
    list(self, msg afterPunctuation)
  )

  Context Script cell("identifier:import()") = method(msg, receiver,
    imports = msg body args map(select(visible?) map(text))
    imports each(imp,
      imp = Java Import mimic(imp, node)
      node imports << imp
      pkg = imp package
      unless(pkg,
        pkg = Java Package mimic(imp packageName)
        node world packages << pkg
      )
    )
    list(self, msg fwd, receiver)
  )

  Context Script cell("identifier:class") = method(msg, receiver,
    cls = Java Class mimic
    list(self, msg fwd, cls)
  )

  Context Script cell("identifier:class()") = method(msg, receiver,
    cls = Java Class mimic
    if(msg body message,
      clsNode = Java create:node(cls)
      clsNode process(msg body message, cls)
    )
    list(self, msg fwd, cls)
  )


  Context Script cell("operator:=()") = method(msg, receiver,
    lhs = node process(msg body arg(0)) last
    rhs = node process(msg body arg(1)) last

    asg = Java Assignment mimic(receiver, lhs, rhs)
    
    cond(
      asg atPackage? && asg class?,
      asg rhs name = lhs name
      lhs reference  = rhs
      rhs package = node currentPackage
      node currentPackage classes << rhs,

      true,
      error!("ASIGN?")
    )
    
    list(self, msg fwd, asg)
  )

)
