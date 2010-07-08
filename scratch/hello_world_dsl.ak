/*
  This example creates a `hello' macro that will
  take its name and name of subsequent messages,
  join them with spaces and print to stdout
*/

hello = call message map(name) join(" ") println

hello akin world
