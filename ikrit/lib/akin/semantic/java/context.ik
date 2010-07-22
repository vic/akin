
use("akin/semantic/java/context/script")
use("akin/semantic/java/context/class")

let(
  Semantic, Akin Semantic,
  Node,     Akin Semantic Node,
  Java,     Akin Semantic Java,
  Context,  Akin Semantic Java Context,

  Context initialize = method(
    @packages = list(Java Package mimic)
  )
  Context classes = method(packages map(classes) flatten)

)
