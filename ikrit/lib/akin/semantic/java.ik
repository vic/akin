use("akin/semantic")

Akin Semantic Java = Origin mimic

let(
  Semantic, Akin Semantic,
  Node,     Akin Semantic Node,
  Java,     Akin Semantic Java,



  Java Context = Semantic Context with(Java: Java, Node: Java)
  Java Context Context = Java Context

  Java create:node = fnx(object,
    object context = Java Context cell(object kind split last) mimic(object)
    object process = Akin Semantic Node cell(:process)
    object
  )

  BaseContext = Origin mimic
  BaseContext cell("code:\#{}") = dmacro(
    [>msg, >receiver]
    m = ''(let(msg, `(msg), 
               receiver, `(receiver), 
            `(Message fromText(msg body message code))))
    val = m evaluateOn(call ground, self)
    list(self, msg fwd, val)
  )
  
  BaseContext cell("any:identifier") = method(msg, receiver,
    pointer = Java Pointer mimic(msg text, msg position physical)
    list(self, msg fwd, pointer)
  )

  BaseContext cell("any:decNumber") = method(msg, receiver,
    literal = Java NumericLiteral mimic(msg)
    list(self, msg fwd, literal)
  )


  Java create:ctx = fnx(
    ctx = BaseContext with(Java: Java, Context: Java Context)
    ctx initialize = method(node, @node = node)
    ctx
  )

  Java Context create:node = Java cell("create:node")
  Java Context create:ctx = Java cell("create:ctx")
)

use("akin/semantic/java/node")
use("akin/semantic/java/context")
