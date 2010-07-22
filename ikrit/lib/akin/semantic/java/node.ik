
let(
  Java,     Akin Semantic Java,

  java:node = fnx(Origin with(Java: Java))

  Java Script = java:node
  Java Script initialize = method(world, position nil,
    @world = world
    @position = position
    @currentPackage = world packages first
  )

  Java Package = java:node
  Java Package initialize = method(name nil,
    @name = name
    @classes = list
    @interfaces = list
    @enums = list
    @annotations = list
  )

  Java Class = java:node
  Java Class initialize = method(name nil, package nil,
    @name = name
    @package = package
    @inner = Java Package mimic
    @annotations = list
    @parameters = list
  )


  Java Pointer = java:node
  Java Pointer initialize = method(name, position nil, reference nil,
    @name = name
    @position = position
    @reference = reference
  )

  Java Assignment = java:node
  Java Assignment initialize = method(receiver, lhs, rhs,
    @receiver = receiver
    @lhs = lhs
    @rhs = rhs
  )

  Java Assignment atPackage? = method(receiver nil? || receiver is?(Java Package))
  Java Assignment atClass? = method(receiver is?(Java Class))
  Java Assignment class? = method(rhs is?(Java Class))
  

  Java NumericLiteral = java:node
  Java NumericLiteral initialize = method(msg,
    @msg = msg
  )
  

)
