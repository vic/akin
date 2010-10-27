use("akin")
use("akin/parser")

Akin Parser Message toJSON = method(
  sb = Akin Parser StrinBuilder mimic
  Akin Parser Message JSON send(type, self, sb)
  sb asText
)
Akin Parser Message JSON = Origin mimic
Akin Parser Message JSON do(

  rest = method(m, sb,
    if(m body,
      m << "body:{"
      if(m body brackets, sb << "left:" << m body brackets first inspect << ",")
      if(m body message, sb << "message:" << m body message toJSON << ",")
      if(m body brackets, sb << "right:" << m body brackets last inspect)
      m << "},"
    )
    if(m fwd, sb << "fwd:" << m fwd toJSON)
  )

  message = dmacro([>m, >sb]
   sb << "{"  
   if(m type, m << "type" inspect << ":" << m type inspect << ",")
   if(m position, 
     m << "position" inspect << ":" << "{"
     m << "physical" inspect << ":" << "{"
     m << "source" inspect << ":" << m position physical source inspect << ","
     m << "line" inspect << ":" << m position physical line inspect << ","
     m << "column" inspect << ":" << m position physical column inspect
     m << "}"
     m << "},"
   )
   if(m text, sb << "text:" << m text inspect << ",")
   rest(m, sb)
   sb << "}"
  )

  activation = method(:message)
  code = cell(:message)
  space = cell(:message)
  identifier = cell(:message)
  punctuation = cell(:message)
  operator = cell(:message)
  comment = cell(:message)
  document = cell(:message)
  symbolIdentifier = method(m, sb,
    sb << ":". activation(m, sb)
  )
  symbolText = method(m, sb,
    sb << ":". text(m, sb)
  )
  text = method(m, sb, rest: true,
    sb << m literal[:left]
    m literal[:parts] each(i, part, 
      if(i % 2 == 0, 
        sb << m literal[:parts][i],
        sb << m literal[:parts][i] code
      )
    )
    sb << m literal[:right]
    if(rest, @rest(m, sb))
  )
  regexp = method(m, sb,
    text(m, sb, rest: false)
    if(m literal[:flags], sb << m literal flags)
    if(m literal[:engine], sb << ":" << m literal engine)
    rest(m, sb)
  )
  hexNumber = method(m, sb,
    sb << "0x". code(m, sb)
  )
  octNumber = method(m, sb,
    sb << "0o". code(m, sb)
  )
  binNumber = method(m, sb,
    sb << "0b". code(m, sb)
  )
  decNumber = method(m, sb,
    sb << m literal[:integer]
    if(m literal[:fraction],
      sb << "." << m literal[:fraction])
    if(m literal[:exponent],
      sb << "e" << m literal[:exponent])
    rest(m, sb)
  )

)
