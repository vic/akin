
let(
  Java,     Akin Semantic Java,

  java:node = fnx(Origin with(Java: Java))

  Java Script = java:node
  Java Script initialize = method(world, position nil,
    @world = world
    @position = position
    @currentPackage = world packages first
    @imports = list
  )

  Java Package = java:node
  Java Package initialize = method(name nil,
    @name = name
    @classes = list
    @interfaces = list
    @enums = list
    @annotations = list
  )

  Java Import = java:node
  Java Import initialize = method(names, script,
    @names = names
    @script = script
  )
  Java Import packageName = method(names butLast)
  Java Import package = method(
    name = packageName
    script world packages find(p, p name == name)
  )

  Java Class = java:node
  Java Class initialize = method(name nil, package nil,
    @name = name
    @package = package
    @inner = Java Package mimic
    @annotations = list
    @parameters = list
    @members = list
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
  
  Java Value = Origin mimic

  Java NumericLiteral = java:node mimic!(Java Value)
  Java NumericLiteral initialize = method(msg,
    @msg = msg
  )
  
  Java Member = java:node
  Java Member initialize = method(field, value nil, meta nil,
    @field = field
    @value = value
    @meta = meta
  )
  Java Member name = method(field name)
  Java Member method? = method(value is?(Java Method))
  Java Member value? = method(value is?(Java Value))
  
  Java MemberMeta = java:node
  Java MemberMeta initialize = method(owner,
    @owner = owner
    @modifiers = list
    @annotations = list
  )
  Java MemberMeta private? = method(modifiers include?("private"))
  Java MemberMeta public? = method(modifiers include?("public"))
  Java MemberMeta static? = method(modifiers include?("static"))
  Java MemberMeta nonStatic? = method(!modifiers include?("static"))
  Java MemberMeta protected? = method(modifiers include?("protected"))
  Java MemberMeta final? = method(modifiers include?("final"))


  Java Method = java:node

)
