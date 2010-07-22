Akin Parser Rewrite Precedence = Origin mimic
Akin Parser Rewrite Precedence do(

  initialize = method(
  )

  operatorPrecedence = dict(
    "!"      =>  0,
    "?"      =>  0,
    "$"      =>  0,
    "~"      =>  0,
    "#"      =>  0,
    "--"     =>  0,
    "++"     =>  0,
    "**"     =>  1,
    "*"      =>  2,
    "/"      =>  2,
    "%"      =>  2,
    "+"      =>  3,
    "-"      =>  3,
    "∩"      =>  3,
    "∪"      =>  3,
    "<<"     =>  4,
    ">>"     =>  4,
    "<=>"    =>  5,
    ">"      =>  5,
    "<"      =>  5,
    "<="     =>  5,
    "≤"      =>  5,
    ">="     =>  5,
    "≥"      =>  5,
    "<>"     =>  5,
    "<>>"    =>  5,
    "<<>>"   =>  5,
    "⊂"      =>  5,
    "⊃"      =>  5,
    "⊆"      =>  5,
    "⊇"      =>  5,
    "=="     =>  6,
    "!="     =>  6,
    "≠"      =>  6,
    "==="    =>  6,
    "=~"     =>  6,
    "!~"     =>  6,
    "&"      =>  7,
    "^"      =>  8,
    "|"      =>  9,
    "&&"     =>  10,
    "?&"     =>  10,
    "||"     =>  11,
    "?|"     =>  11,
    ".."     =>  12,
    "..."    =>  12,
    "=>"     =>  12,
    "<->"    =>  12,
    "->"     =>  12,
    "∘"      =>  12,
    "+>"     =>  12,
    "!>"     =>  12,
    "&>"     =>  12,
    "%>"     =>  12,
    "#>"     =>  12,
    "@>"     =>  12,
    "/>"     =>  12,
    "*>"     =>  12,
    "?>"     =>  12,
    "|>"     =>  12,
    "^>"     =>  12,
    "~>"     =>  12,
    "->>"    =>  12,
    "+>>"    =>  12,
    "!>>"    =>  12,
    "&>>"    =>  12,
    "%>>"    =>  12,
    "#>>"    =>  12,
    "@>>"    =>  12,
    "/>>"    =>  12,
    "*>>"    =>  12,
    "?>>"    =>  12,
    "|>>"    =>  12,
    "^>>"    =>  12,
    "~>>"    =>  12,
    "=>>"    =>  12,
    "**>"    =>  12,
    "**>>"   =>  12,
    "&&>"    =>  12,
    "&&>>"   =>  12,
    "||>"    =>  12,
    "||>>"   =>  12,
    "$>"     =>  12,
    "$>>"    =>  12,
    "+="     =>  13,
    "-="     =>  13,
    "**="    =>  13,
    "*="     =>  13,
    "/="     =>  13,
    "%="     =>  13,
    "and"    =>  13,
    "nand"   =>  13,
    "&="     =>  13,
    "&&="    =>  13,
    "^="     =>  13,
    "or"     =>  13,
    "xor"    =>  13,
    "nor"    =>  13,
    "|="     =>  13,
    "||="    =>  13,
    "<<="    =>  13,
    ">>="    =>  13,
    "<-"     =>  14,
    "return" =>  14,
    "import" =>  14
  )

  nonAssign = list(
    "<=", ">=", "==", "==="
  )

  rightAssociative = list(
    "**"
  )

  leftUnary = list(
    "--", "++"
  )

  invertedOperator = dict(
    "∈"      =>  12,
    "∉"      =>  12,
    ":::"    =>  12
  )
  
  prefixPrecedence = dict(
    "|" =>  9,
    "^" =>  8,
    "&" =>  7,
    "<" =>  5,
    ">" =>  5,
    "=" =>  6,
    "!" =>  6,
    "?" =>  6,
    "~" =>  6,
    "$" =>  6,
    "+" =>  3,
    "-" =>  3,
    "*" =>  2,
    "/" =>  2,
    "%" =>  2
  )

  precedence = method(msg,
    if(msg nil? || msg text nil?, return)
    name = msg text
    value = operatorPrecedence[name] || invertedOperator[name]
    unless(value,
      if(name length > 0,
        return prefixPrecedence[name[0..0]]
      )
    )
    return value
  )

  rightAssociative? = method(msg, 
    msg && rightAssociative include?(msg text)
  )

  leftUnary? = method(msg,
    msg && leftUnary include?(msg text)
  )

  assignment? = method(msg,
    msg && msg text && !nonAssign include?(msg text) && msg text chars last == "="
  )

)
