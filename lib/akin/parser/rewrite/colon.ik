
Akin Parser Rewrite Colon = Origin mimic
Akin Parser Rewrite Colon do(

  rewrite = method(chain,
    colon = chain find(m, m name == :(":") && m body nil?)
    while(colon,
      nil
    )
    chain
  )
  
)
