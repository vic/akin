Akin Semantic Context = Origin mimic

Akin Semantic do(

  Context initialize = method(@scripts = list)
  
  Context currentScript = method(scripts last)

  Context analyze = method(chain,
    script = create:node(Node Script mimic(self, chain position physical))
    scripts append!(script)
    script process(chain)
    self
  )

)
