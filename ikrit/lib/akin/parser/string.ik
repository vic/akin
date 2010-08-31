

Akin Parser String = Origin mimic
Akin Parser String do(

  chr = method(text,
    java:io:StringReader new(text) read asRational
  )
  
  str = method(char,
    java:lang:Character toString(char)
  )

  txt = method(char,
    str(char) asText
  )

  charMatch? = method(char, thing,
    if(thing is?(Number),
      thing == char,
      if(thing is?(Text),
        chr(thing) == char,
        if(thing is?(Range),
          from = thing from
          to = thing to
          if(from is?(Text), from = chr(from))
          if(to is?(Text), to = chr(to))
          from <= char && char <= to,
          if(thing == true,
            true,
            if(thing == false,
              false,
              error!("Dont know how to match char "+desc(char)+
                " against "+thing inspect)
    )))))
  )

  desc = method(char,
    if(char == -1, "EOF",
      if(char == 9, "TAB",
        if(char == 10 || char == 13, "EOL",
          "'"+txt(char)+"'"
    )))
  )

)

Akin Parser StringBuilder = Origin mimic
Akin Parser StringBuilder do(
  initialize = method(
    @builder = java:lang:StringBuilder new
  )
  
  append = method(str,
    builder append(java:lang:String valueOf(str))
    self
  )

  prepend = method(str,
    builder insert(0, java:lang:String valueOf(str))
    self
  )

  cell("<<") = cell("append")

  cell(">>") = cell("prepend")
  
  asText = method(builder toString asText)
)