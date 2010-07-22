use("ispec")
use("akin")
use("akin/parser")
use("akin/semantic/java")

describe("Akin Java Semantic Analizer",

  parse = fn(txt, Akin Parser parseText(txt))
  context = fnx(Akin Semantic Java Context mimic)
  sa = fn(txt, context analyze(parse(txt)))

  it("should return a context object",
    w = sa(".")
    w kind should == "Akin Semantic Java Context"
  )

  it("should have a default package",
    w = sa(".")
    w packages size should == 1
  )

  it("should have a default package with no name",
    w = sa(".")
    w packages size should == 1
    w packages first name should be nil
  )

  it("should have a default package with no classes",
    w = sa(".")
    w packages size should == 1
    w packages first classes should be empty
  )

  it("should have a default package with no interfaces",
    w = sa(".")
    w packages size should == 1
    w packages first interfaces should be empty
  )

  it("should have a default package with no enums",
    w = sa(".")
    w packages size should == 1
    w packages first enums should be empty
  )

  it("should have a default package with no annotations",
    w = sa(".")
    w packages size should == 1
    w packages first enums should be empty
  )

  it("should parse package definition",
    w = sa("package(foo bar)")
    w packages size should == 2
    w packages last name should == "foo.bar"
  )

  it("should parse emtpy class definition",
    w = sa("Foo = class")
    w classes size should == 1
    w classes last name should == "Foo"
    w classes last package should == w packages first
  )

  it("should parse emtpy class definition",
    w = sa("Foo = class()")
    w classes size should == 1
    w classes last name should == "Foo"
    w classes last package should == w packages first
  )

  it("should parse class definition with field assignment",
    w = sa("Foo = class( a = 1 )")
    foo = w classes last
    foo name should == "Foo"
  )

  it("should evalute curly code blocks on current context",
    w = sa(" \#{ world foo = 22 } ")
    w foo should == 22
  )

)
