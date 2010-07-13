# Whole line comments

   #  A sharp followed by an space or '!' or another sharp
   #! like this
   ## or this

# Document

   /* like java docs, but are real objects */

# Numbers

### Binary

   0b10101

### Hexadecimal

   0xCAFEBABE

### Octal
 
   0o77665

### Decimal Int

   10
   123_000_000
   10.22e6

### Decimal Float

   123.22e-10

# Range

   22 .. 33
   22 … 33  # Unicode elipsis

# Ratio
  
   3:1      # when using ascii colon, no spaces allowed 
   3 ∶ 1   #  When using unicode U+2236 (∶)  threre can be spaces

# Symbol

   :hello
   :"hello #{who}"

# String

  "hello world"

### Interpolated

  "hello $(who)"

# Regexp

  $/hello (bar|baz)/

## with flags
  
  $/hello/i

## with engine selection

  $/hello/i:re2

# Tuple

  (one)             # tuple1
  (one, two)        # tuple2 aka. pair
  (one, two, three) # tuple3 .. and so forth

# List

  [1, 2, 3, 4]

# Dict (List of tuple2 / Assoc array)

  [1 => 2, 3 => 4]

# Message literal. (parsed code but not evaluated)

  {x, x + 1}

# Set (a collection of unique values)

  #[1, 2, 1]

