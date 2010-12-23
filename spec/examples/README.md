This directoy contains small sample output (.out) files to test files inside the
examples/ directoy.

By convention each file is named after the corresponding .ak file in the examples/
directory being tested. Though this is not mandatory.

The first line should start with a comment like

    #! akin examples/hello.py

Indicating the current file is the stdout output as expected from running
`akin examples/hello.ak` command. Everything after `#! akin` is
given as arguments to the bin/akin program.
And the whole line will be removed from expected output.

For example, to test the output of running the examples/foo/bar.ak file
with two command line arguments, you should have the first line in the
.out file set to:

    #! akin examples/foo/bar.ak firstArg secondArg

Files not having that comment as first line will just be ignored.

Also, some examples output memory locations like 0x0AF30 in that cases
.out files can use ruby regexes like: #{/0x\w+/}.
