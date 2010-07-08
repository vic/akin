#!/usr/bin/env akin

#! Whole line comments like this
#! are ignored by the parser.
#! Use them to ignore lines of code at parsing phase

/*** Akin documentation literals
 
   Did you know that in Akin all documentation texts are 
   actually literals?

   They can be used for generating API docs, giving interactive
   help on a REPL or generating manual pages.

   Documents start with /* and end with */ just like in java. 
   Unlike in java, Akin documents can be nested.

   Akin documents are quine literals, that means that its text
   representation is the same as the literal that created it.

       d = /* "hello" #{world} */
       d text should == "/* \"hello\" \#{world} */"

   You can use this fact to create large texts without having
   to escape quote characters or code interpolation.

   You can always ask a document for the inner text, ignoring
   all those stars:

       d = /*** 
            * Documenting something:
            * 
            * Akin docs
            */
            
       d content should == "Documenting something:\n\nAkin docs\n"

   Akin promotes some conventions for communicating information
   according to the intended audience:

   Internal Developers (dev): /* start with a single star */
     
     This kind of document is the one you write for 
     sharing knowledge with your co-workers about
     application internal implementation and things like 
     algorigthm details, protocol comments, etc.

   External Developers (api): /** start with two stars */

     This kind of document is helpful to outsiders
     willing to use your application API. Any object
     or method having this kind of documentation will
     be exposed when generating API docs.

   Application Users (man): /*** start with three stars */

     This kind of document is inteded to help users
     of your application. For example, if you write a 
     unix utility in Akin, this kind of document would
     help you generate user manual pages to be read with
     man(1), html manuals, pdf or the like.

*/ println
