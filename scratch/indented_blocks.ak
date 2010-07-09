#!/usr/bin/env akin
# 
#  Akin messages preserve position information, thus they know
#  at runtime at which line they were declared, and since 
#  spaces are also Akin messages, we can know the indentation
#  level of any message. This can be helpful to emulate 
#  intentation sentive statements like in python.

5 times(i):
  lang = if i % 2 == 0:
            "akin"
         else:
            "python"
  lang println
  
# will print:
#
# python
# akin
# python
# akin
# python
