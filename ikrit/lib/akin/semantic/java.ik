use("akin/semantic")

Akin Semantic Java = Origin mimic

let(
  Semantic, Akin Semantic,
  Node,     Akin Semantic Node,
  Java,     Akin Semantic Java,


  Java Context = Semantic Context with(Java: Java, Node: Java)
  Java Context Context = Java Context
  Context = Java Context

  Context create:node = Node cell("create:node")
  Context create:ctx = fnx(
    ctx = Origin with(Java: Java, Context: Context)
    ctx initialize = method(node, @node = node)
    ctx
  )
)

use("akin/semantic/java/node")
use("akin/semantic/java/context")
