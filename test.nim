include std/[re, math, typeinfo]

proc main =
  echo """[ ](?=(?:[^"]*"[^"]*")*[^"]*$)"""
  let str = """test test "test test" test a \"b\" "." test"""
  var test = str.split(re"""[ ](?=(?:[^"]*"[^"]*")*[^"]*$)""")
  echo test
  echo test[2].strip(chars = {'"'})
  echo test[6].strip(chars = {'"'})
  echo """\s+(?=(?:[^\'"]*[\'"][^\'"]*[\'"])*[^\'"]*$)"""
  test = str.split(re"""\s+(?=(?:[^\'"]*[\'"][^\'"]*[\'"])*[^\'"]*$)""")
  echo test
  echo test[2].strip(chars = {'"'})
  echo test[6].strip(chars = {'"'})
  echo divmod(5, 2)[0].kind

when isMainModule:
  main()
