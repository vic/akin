puse("ispec")
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
    w packages last name should == list("foo", "bar")
  )

  it("should import simple class",
    w = sa("import(moo bat Man)")
    w packages size should == 2
    w packages find(p, p name == list("moo", "bat")) should not be nil
  )


  it("should evalute curly code blocks on current context",
    w = sa(" \#{ world foo = 22 } ")
    w foo should == 22
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
    foo members first name should == "a"
  )

  it("should parse class definition with private field assignment",
    w = sa("Foo = class( private a = 1 )")
    foo = w classes last
    foo name should == "Foo"
    a = foo members find(m, m meta nonStatic? && m name == "a")
    a meta should be private
  )

  it("should parse class definition with protected field assignment",
    w = sa("Foo = class( protected a = 1 )")
    foo = w classes last
    foo name should == "Foo"
    a = foo members find(m, m meta nonStatic? && m name == "a")
    a meta should be protected
  )

  it("should parse class definition with static field assignment",
    w = sa("Foo = class( static a = 1 )")
    foo = w classes last
    foo name should == "Foo"
    a = foo members find(m, m meta static? && m name == "a")
    a meta should be static
  )

  it("should parse class definition with public field assignment",
    w = sa("Foo = class( public a = 1 )")
    foo = w classes last
    foo name should == "Foo"
    a = foo members find(m, m meta nonStatic? && m name == "a")
    a meta should be public
  )

  it("should parse class definition with final field assignment",
    w = sa("Foo = class( final a = 1 )")
    foo = w classes last
    foo name should == "Foo"
    a = foo members find(m, m meta nonStatic? && m name == "a")
    a meta should be final
  )

  it("should parse class definition with final field assignment",
    w = sa("Foo = class( final a = 1 )")
    foo = w classes last
    foo name should == "Foo"
    a = foo members find(m, m meta nonStatic? && m name == "a")
    a meta should be final
  )

  it("should parse class definition with empty void method",
    w = sa("Foo = class( hello = method )")
    foo = w classes last
    foo name should == "Foo"
    hello = foo members first
    hello method? should be true
  )

  it("should parse class definition with empty void method",
    w = sa("Foo = class( hello = method() )")
    foo = w classes last
    foo name should == "Foo"
    hello = foo members first
    hello method? should be true
  )

  it("should parse class definition with empty void method",
    w = sa("Foo = class( hello = method() )")
    foo = w classes last
    foo name should == "Foo"
    hello = foo members first
    hello method? should be true
  )


)
