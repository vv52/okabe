import std/[strutils, strscans, strformat, strtabs]
import std/[algorithm, math, sequtils, tables, re]
import std/[cmdline, rdstdin, terminal, osproc, streams]
import stacks

# TODO: STRING OPS, ITERATORS, ENUM
# 
#       b>@ would take 1001 and make [ 1 0 0 1 ]
#       add !0 or !empty or something to check if stack is empty
#       then like !$ or !$empty etc
# 
      # "$_" possible alias for "fwriteln"
      # ".$" possible alias for "to$ $"

type
  OkAnyType = object
    s : string
    n : float
    a : seq[OkAnyType]
  MemoryState = object
    # returnPtr : int
    # bufferSwap : seq[string]
    stackSwap : Stack[float]
    rstackSwap : Stack[float]
    sstackSwap : Stack[string]
    qstackSwap : Stack[string]
    dregSwap : string

var docs = newStringTable()

proc dump() : void
docs["."] = "( a -- ) echo a"
proc sdump() : void
docs["$"] = "$( s -- ) echo s"
proc top() : void
docs["top"] = "( a -- a ) echo a"
proc stop() : void
docs["$top"] = "$( s -- s ) echo s"
proc add() : void
docs["+"] = "( a b -- c ) a + b"
proc sub() : void
docs["-"] = "( a b -- c ) a - b"
proc mul() : void
docs["*"] = "( a b -- c ) a * b"
proc divide() : void
docs["/"] = "( a b -- c ) a / b, arbitrary decimal number"
proc divrem() : void
docs["/%"] = "( a b -- c d ) a / b, int and remainder"
proc modulus() : void
docs["%"] = "( a b -- c ) a / b, remainder"
proc divint() : void
docs["//"] = "( a b -- c ) a / b, floored int"
proc okSqrt() : void
docs["sqrt"] = "( a -- √a )"
proc inc() : void
docs["++"] = "( a -- b ) b is a + 1"
proc dec() : void
docs["--"] = "( a -- b ) b is a - 1"
proc bsl() : void
docs["<<"] = "( a b -- c ) c is a bitshifted left b times"
proc bsr() : void
docs[">>"] = "( a b -- c ) c is a bitshifted right b times"
proc trunc() : void
docs["trunc"] = "( d -- i ) truncate top of stack to int"
proc floor() : void
docs["floor"] = "( d -- i ) floor top of stack to int"
proc ceil() : void
docs["ceil"] = "( d -- i ) ceil top of stack to int"
proc dup() : void
docs["dup"] = "( a -- a a )"
proc sdup() : void
docs["$dup"] = "$( s -- s s )"
proc drop() : void
docs["drop"] = "( a -- )"
proc sdrop() : void
docs["$drop"] = "$( s -- )"
proc rot() : void
docs["rot"] = "( a b c -- b c a )"
proc unrot() : void
docs["-rot"] = "( b c a -- a b c )"
proc swap() : void
docs["swap"] = "( a b -- b a )"
proc sswap() : void
docs["$swap"] = "$( s t -- t s )"
proc over() : void
docs["over"] = "( a b -- a b a )"
proc pick() : void
docs["pick"] = "( a b c 2 -- a b c a )"
proc tuck() : void
docs["tuck"] = "( a b -- b a b )"
proc roll() : void
docs["roll"] = "( a b c 2 -- b c a )"
proc rpush() : void
docs[">r"] = "( a -- ) r( -- a )"
proc rpop() : void
docs["r>"] = "( -- a ) r( a -- )"
proc rcmp : void
docs["rcmp"] = "( a -- a t ) r( a -- a ) checks if top of stack and rstack are the same, returns 1 if true and 0 if false"
proc qpush() : void
docs[">q"] = "$( s -- ) q( -- q ) pop $stack and push to qstack"
proc qpop() : void
docs["q>"] = "q( q -- ) $( -- s ) pop qstack and push to $stack"
proc quote() : void
docs["("] = "begin storing code for later execution; terminates at matched ')'"
proc nested() : string
proc exqtop() : void
docs["'"] = ("q( q -- q ) peek qstack and execute quote")
proc exqpop() : void
docs["'."] = ("q( q -- ) pop qstack and execute quote")
proc exc() : void
docs["'x"] = ("q( q -- ) drop qstack and discard quote")
proc deferex() : void
docs["defer"] = ("q( q -- ) dreg[q] pop qstack and push to dreg")
proc dex() : void
docs["dex"] = ("execute quote in dreg")
proc question() : void
docs["?"] = ("( b -- ) q( q -- ) pop stack, pop qstack; if greater than 0, execute quote, otherwise discard")
proc questionElse() : void
docs["?:"] = ("( b -- ) q( q q -- ) pop stack; if greater than 0, qswap qpop execute qdrop, otherwise qpop execute qdrop")
proc gt() : void
docs[">"] = ("( a b -- a t ) if a is greater than b, t is 1, otherwise t is 0")
proc gteq() : void
docs[">="] = ("( a b -- a t ) if a is greater than or equal to b, t is 1, otherwise t is 0")
proc gt0() : void
docs[">0"] = ("( a -- a b ) if a is greater than 0, b is 1, otherwise b is 0")
proc lt() : void
docs["<"] = ("( a b -- a t ) if a is less than b, t is 1, otherwise t is 0")
proc lteq() : void
docs["<="] = ("( a b -- a t ) if a is less than or equal to b, t is 1, otherwise t is 0")
proc lt0() : void
docs["<0"] = ("( a -- a b ) if a is less than 0, b is 1, otherwise b is 0")
proc eq0() : void
docs["=0"] = ("( a -- a b ) if a is equal to 0, b is 1, otherwise b is 0")
proc land() : void
docs["&&"] = ("( t f -- f ) logical and, only returns 1 if both are also 1, otherwise returns 0")
proc lor() : void
docs["|"] = ("( t f -- t ) logical or, returns 1 if either is 1, only returns 0 if both are 0")
proc lxor() : void
docs["x|"] = ("( t f -- t ) logical xor, returns 0 unless top stack contains a 1 and a 0, in which case return 1")
proc eq() : void
docs["="] = ("( a b -- a c ) if a is equal to b, c is 1, otherwise c is 0")
proc linv() : void
docs["!"] = ("( a -- b ) if a is 1, b is 0; if a is 0, b is 1")
proc map1() : void
docs["map"] = ("[ a b c -- d e f ] d, e, and f are a, b, and c after top of quote stack is applied to each individually")
proc mapn() : void
docs["mapn"] = ("( n -- ) [ a ... -- A ... ] apply top of quote stack to n number of items in array together until array empty, array len must be divisible by n")
proc array() : void
docs["["] = "[ a b c ] creates an anonymous array in memory"
proc array2d() : void
docs["@new"] = ""
proc atArrayIndex() : void
docs["@"] = "[ a ... z ] ( i -- n ) pops the stack and pushes the element at that index from focused array to stack"
proc atArray2dIndex() : void
docs["@2d"] = "( i j -- n ) $( name -- name ) pop stack twice, peek $stack, push element at name[j][i] to stack"
proc array2dFill() : void
docs["@2dFill"] = "( v -- ) $( k -- ) pop stack, peek $stack, fill k[0..n][0..n] with v"
proc toArray() : void
docs[">@"] = ("( a b c d -- ) [ -- a b c d ]")
proc fromArray() : void
docs["@>"] = ("( -- a b c d ) [ a b c d -- ]")
proc arrayCmp() : void
docs["@cmp"] = ("compare 2 arrays in memory at the top of the internal array stack, returns 1 to stack if equal, 0 if not")
proc arrayClear() : void
docs["@clear"] = ("empties the internal array stack")
proc aswap() : void
docs["@swap"] = "@( a1 a2 -- a2 a1 )"
proc store() : void
docs["store"] = "$( s -- ) pop string stack, pop internal array stack, store array in memory at string"
proc store2d : void
docs["store2d"] = ""
proc variable : void
docs["var"] = "$( k -- ) ( v -- ) stores v at k"
proc word() : void
docs["proc"] = "$( s -- ) ()( q -- ) make new word from top of string stack that does top of qstack"
proc safeWord() : void
docs["safeproc"] = "$( s -- ) ()( q -- ) make new Word from top of string stack that freezes memory, does top of qstack, and unfreezes memory, essentially creating a containerized procedure"
proc cmd() : void
docs["cmd"] = "$( s -- ) ( -- e ) pop string stack and exec in shell, push exit code to stack and echo output"
proc openFile() : void
docs["file"] = "$( filename -- ) open file for reading or writing"
proc closeFile : void
docs["close"] = "close current output file"
proc fWriteLn() : void
docs["fwriteln"] = "write line to current output file"
proc toString() : void
docs["to$"] = "( n -- ) $( -- s ) pops stack and pushes string representation to string stack"
proc concatenate() : void
docs["&"] = "$( s1 s2 -- s1&s2 ) concatenates top two strings on string stack in reverse pop order"
proc clearStack : void
docs["clear"] = "( a .. n -- ) empties stack"
proc stringToDReg() : void
docs["$>d"] = "$( s -- ) d[ -- s ] pops string stack and stores in d reg"
proc dRegToString() : void
docs["d>$"] = "$d[ s -- ] $( -- s ) pushes dreg to $stack snd clears dreg"
proc stringLength() : void
docs["$len"] = "$( s -- s ) ( -- s.len)"
proc stackDump(s : Stack) : void
proc freeze() : void
proc unfreeze() : void
proc memDump() : void
proc memClear() : void
proc popInt() : int
proc executeQuote(q : string) : void
proc parseToken(token : string) : void
proc repl() : void
proc incl() : void
proc preprocess(file : string) : string
proc interpret(file : string) : void
proc error(text : string) : void
proc warning(text : string) : void
proc usage(text : string) : void
proc info(text : string) : void
proc todo(text : string) : void
proc pass(text : string) : void
proc fail(text : string) : void

var debug = false
var noLog = false
var helpMode = false
var interpreting = false
var including = false
var executingQuote = false
var stopQuote : int = -1

var stack = newStack[float](capacity = 64)     # THE stack
var rstack = newStack[float](capacity = 64)    # rstack for forth algs
var sstack = newStack[string](capacity = 64) # stack for string literals
var qstack = newStack[string](capacity = 64) # stack for quoted code in conditionals and procedures
var astack = newStack[seq[float]](capacity = 16)

var dreg : string
var buffer : seq[string]
var ifbuffer : string
var iftokens : seq[string]
# var ofbuffer : string

var memoryStateSwap : MemoryState

var procs = newStringTable()
var vars = initTable[string, float]()
var namedArrays = initTable[string, seq[float]]()
var named2dArrays = initTable[string, seq[seq[float]]]()
var outputFile : FileStream

var tokenPtr : int = 0

let parseRule = re"""\s+(?=(?:[^\"]*[\"][^\"]*[\"])*[^\"]*$)"""

proc help =
  helpMode = true

proc dump =
  try:
    let n = stack.pop
    if almostEqual(n, n.trunc):
      echo n.toInt
    else: echo n
  except:
    error("nothing on stack to pop")
    memDump()

proc sdump =
  try:
    echo sstack.pop
  except:
    error("nothing on $stack to pop")
    memDump()

proc top =
  try:
    echo stack.peek
  except:
    error("nothing on stack to peek")
    memDump()

proc add =
  try:
    let a = stack.pop
    let b = stack.pop
    stack.push(a + b)
  except:
    error("less than two numbers on stack")
    memDump()
  
proc sub =
  try:
    let a = stack.pop
    let b = stack.pop
    stack.push(b - a)
  except:
    error("less than two numbers on stack")
    memDump()
  
proc mul =
  try:
    let a = stack.pop
    let b = stack.pop
    stack.push(a * b)
  except:
    error("less than two numbers on stack")
    memDump()

proc divint = 
  try:
    let a = stack.pop.trunc.int
    let b = stack.pop.trunc.int
    let x = divmod(b, a)
    stack.push(x[0].toFloat)
  except DivByZeroDefect:
    error("division by zero")
    memDump()
  except:
    error("less than two numbers on stack")
    memDump()
  
proc divrem = 
  try:
    let a = stack.pop.trunc.int
    let b = stack.pop.trunc.int
    let x = divmod(b, a)
    stack.push(x[1].toFloat)
    stack.push(x[0].toFloat)
  except DivByZeroDefect:
    error("division by zero")
    memDump()
  except:
    error("less than two numbers on stack")
    memDump()
  
proc divide =
  try:
    let a = stack.pop
    let b = stack.pop
    stack.push(b / a)
  except DivByZeroDefect:
    error("division by zero")
    memDump()
  except:
    error("less than two numbers on stack")
    memDump()

proc modulus = 
  try:
    let a = stack.pop.trunc.int
    let b = stack.pop.trunc.int
    let x = divmod(b, a)
    stack.push(x[1].toFloat)
  except DivByZeroDefect:
    error("division by zero")
  except:
    error("less than two numbers on stack")
    memDump()

proc okSqrt =
  try:
    stack.push(sqrt(stack.pop))
  except:
    error("nothing on stack")
    memDump()

proc inc =
  try:
    stack.push(stack.pop + 1)
  except:
    error("nothing on stack to increment")
    memDump()

proc dec =
  try:
    stack.push(stack.pop - 1)
  except:
    error("nothing on stack to decrement")
    memDump()

proc bsl =
  try:
    let times = stack.pop
    let x = stack.pop
    stack.push((x.trunc.int shl times.trunc.int).toFloat)
  except:
    error("less than two numbers on stack")
    memDump()

proc bsr =
  try:
    let times = stack.pop
    let x = stack.pop
    stack.push((x.trunc.int shr times.trunc.int).toFloat)
  except:
    error("less than two numbers on stack")
    memDump()

proc trunc =
  try:
    stack.push(trunc(stack.pop))
  except:
    error("nothing on stack to truncate")

proc floor =
  try:
    stack.push(floor(stack.pop))
  except:
    error("nothing on stack to floor")

proc ceil =
  try:
    stack.push(ceil(stack.pop))
  except:
    error("nothing on stack to ceil")

proc dup =
  try:
    stack.push(stack.peek)
  except:
    error("nothing on stack to duplicate")
    memDump()
  
proc drop =
  try:
    discard stack.pop
  except:
    warning("nothing on stack to drop")
    memDump()

proc rot =
  try:
    let c = stack.pop
    let b = stack.pop
    let a = stack.pop
    stack.push(b)
    stack.push(c)
    stack.push(a)
  except:
    error("less than three numbers on stack")
    memDump()

proc unrot =
  try:
    let a = stack.pop
    let c = stack.pop
    let b = stack.pop
    stack.push(a)
    stack.push(b)
    stack.push(c)
  except:
    error("less than three numbers on stack")
    memDump()

proc swap =
  try:
    let a = stack.pop
    let b = stack.pop
    stack.push(a)
    stack.push(b)
  except:
    error("less than two numbers on stack")
    memDump()

proc over =
  try:
    let a = stack.pop
    let b = stack.pop
    stack.push(b)
    stack.push(a)
    stack.push(b)
  except:
    error("less than two numbers on stack")
    memDump()

proc pick =
  try:
    let i = popInt()
    let temp = stack.toSeq.reversed
    stack.push(temp[i])
  except:
    error("nothing on stack")
    memDump()
  
proc tuck =
  try:
    let top = stack.peek
    swap()
    stack.push(top)
  except:
    error("less than two numbers on stack")
    memDump()
  
proc roll =
  try:
    let i = popInt()
    case i:
    of 0: discard
    of 1: swap()
    of 2: rot()
    else:
      var temp = stack.toSeq.reversed
      var newTop = temp[i]
      temp.delete(i..i)
      temp = temp.reversed
      stack.clear()
      for item in temp.items:
        stack.push(item)
      stack.push(newTop)
  except:
    error("nothing on stack")
    memDump()

proc sdup =
  try:
    sstack.push(sstack.peek)
  except:
    error("nothing on $stack")
    memDump()
  
proc sdrop =
  try:
    discard sstack.pop
  except:
    warning("nothing on $stack to drop")
    memDump()

proc sswap =
  try:
    let s1 = sstack.pop
    let s2 = sstack.pop
    sstack.push(s1)
    sstack.push(s2)
  except:
    error("less than two strings on $stack")
    memDump()

proc stop =
  try:
    echo sstack.peek
  except:
    error("nothing on $stack to peek")
    memDump()

proc rpush =
  try:
    rstack.push(stack.pop)
  except:
    error("nothing on stack to pop")
    memDump()
  
proc rpop =
  try:
    stack.push(rstack.pop)
  except:
    error("nothing on rstack to pop")
    memDump()

proc rcmp =
  try:
    if almostEqual(stack.peek, rstack.peek):
      stack.push(1.0)
    else: stack.push(0.0)
  except:
    error("cannot compare stack and rstack if either is empty")
    memDump()
  
proc quote =
  try:
    tokenPtr += 1
    if buffer[tokenPtr] == ")":
      return
    var depth = 0
    var quoted = """"""
    var endQuote = false
    while not endQuote:
      if buffer[tokenPtr].len > 0:
        if buffer[tokenPtr] == "(":
          quoted = fmt"""{quoted}( {nested()}) """
        else: quoted = fmt"""{quoted}{buffer[tokenPtr]} """
      tokenPtr += 1
      if buffer[tokenPtr] == ")":
        if depth == 0:
          endQuote = true
    qstack.push(quoted)
  except CatchableError as e:
    error(e.msg)

proc nested : string =
  try:
    tokenPtr += 1
    if buffer[tokenPtr] == ")":
      return
    var depth = 0
    var quoted = """"""
    var endQuote = false
    while not endQuote:
      if buffer[tokenPtr].len > 0:
        if buffer[tokenPtr] == "(":
          quoted = fmt"""{quoted}( {nested()}) """
        else: quoted = fmt"""{quoted}{buffer[tokenPtr]} """
      tokenPtr += 1
      if buffer[tokenPtr] == ")":
        if depth == 0:
          endQuote = true
    return quoted  
  except CatchableError as e:
    error(e.msg)
    memDump()
    return ""

proc qpush() =
  if not sstack.isEmpty:
    qstack.push(sstack.pop)
  else:
    error("nothing on $stack to pop")
    memDump()

proc qpop() =
  if not qstack.isEmpty:
    sstack.push(qstack.pop)
  else:
    error("nothing on qstack to pop")
    memDump()

proc exqtop =
  if not qstack.isEmpty:
    executeQuote(qstack.peek)
  else:
    error("nothing on qstack to peek")
    memDump()

proc exqpop =
  if not qstack.isEmpty:
    executeQuote(qstack.pop)
  else:
    error("nothing on qstack to pop")
    memDump()

proc exc =
  if not qstack.isEmpty:
    discard qstack.pop
  else:
    warning("nothing on qstack to drop")
    memDump()

proc deferex =
  if not qstack.isEmpty:
    dreg = qstack.pop
  else:
    error("nothing on qstack to pop")
    memDump()

proc dex =
  if dreg.len > 0:
    executeQuote(dreg)
  else:
    warning("no deferred quote in dreg, nothing executed")

proc question =
  try:
    discard stack.peek
  except:
    error("no condition result on stack to pop")
    memDump()
  try:
    discard qstack.peek
  except:
    error("no branch on qstack to pop")
    memDump()
  try:
    if stack.pop > 0:
      executeQuote(qstack.pop)
    else:
      discard qstack.pop
  except:
    error("syntax")
    usage("cond_result_int ( branch_quote ) ?")

proc questionElse =
  try:
    discard stack.peek
  except:
    error("no condition result on stack to pop")
    memDump()
  if qstack.len < 2:
    error("less than two quotes on qstack")
    memDump()
  try:
    if stack.pop > 0.3:
      discard qstack.pop
      executeQuote(qstack.pop)
    else:
      let q = qstack.pop
      discard qstack.pop
      executeQuote(q)
  except:
    error("syntax")
    usage("cond_result_int ( 1+_branch ) ( 0-_branch ) ?:")

proc gt =
  try:
    let lower = stack.pop
    if stack.peek > lower:
      stack.push(1.0)
    else: stack.push(0.0)
  except:
    error("nothing on stack to compare")
    memDump()

proc gteq =
  try:
    let lower = stack.pop
    if stack.peek >= lower:
      stack.push(1.0)
    else: stack.push(0.0)
  except:
    error("nothing on stack to compare")
    memDump()

proc gt0 =
  try:
    if stack.peek > 0.0:
      stack.push(1.0)
    else: stack.push(0.0)
  except:
    error("nothing on stack to compare")
    memDump()

proc lt =
  try:
    let higher = stack.pop
    if stack.peek < higher:
      stack.push(1.0)
    else: stack.push(0.0)
  except:
    error("nothing on stack to compare")
    memDump()

proc lteq =
  try:
    let higher = stack.pop
    if stack.peek < higher or almostEqual(stack.peek, higher):
      stack.push(1.0)
    else: stack.push(0.0)
  except:
    error("nothing on stack to compare")
    memDump()

proc lt0 =
  try:
    if stack.peek < 0.0:
      stack.push(1.0)
    else: stack.push(0.0)
  except:
    error("nothing on stack to compare")
    memDump()

proc eq =
  try:
    if almostEqual(stack.pop - stack.peek, 0):
      stack.push(1.0)
    else: stack.push(0.0)
  except:
    error("less than two values on stack")
    memDump()

proc eq0 =
  try:
    if almostEqual(stack.peek, 0):
      stack.push(1.0)
    else: stack.push(0.0)
  except:
    error("nothing on stack to compare")
    memDump()

proc land() =
  try:
    if almostEqual(stack.pop + stack.pop, 2):
      stack.push(1)
    else: stack.push(0)
  except:
    error("less than two values on stack")
    memDump()
  
proc lor() =
  try:
    let t = stack.pop + stack.pop
    if almostEqual(t, 1) or almostEqual(t, 2):
      stack.push(1.0)
    else: stack.push(0.0)
  except:
    error("less than two values on stack")
    memDump()
  
proc lxor() =
  try:
    if almostEqual(stack.pop + stack.pop, 1):
      stack.push(1.0)
    else: stack.push(0.0)
  except:
    error("less than two values on stack")
    memDump()

proc linv =
  try:
    if almostEqual(stack.pop, 0):
      stack.push(1.0)
    else: stack.push(0.0)
  except:
    error("nothing on stack")
    memDump()

proc map1 =
  var a = astack.pop
  var i : int = 0
  while i < a.len:
    stack.push(a[i])
    executeQuote(qstack.peek)
    i += 1
  discard qstack.pop

proc mapn =
  let freq : int = popInt()
  var a = astack.pop
  if floorMod(a.len, freq) != 0:
    astack.push(a)
    error("array length must be divisible by n")
    warning("mapn not performed, n consumed, array remains in memory")
    memDump()
  else: 
    var i : int = 0
    while i < a.len: 
      stack.push(a[i])
      i += 1
      while floorMod(i, freq) != 0:
        stack.push(a[i])
        i += 1
      executeQuote(qstack.peek)
    discard qstack.pop

proc array =
  let bufferBackup = buffer
  tokenPtr += 1
  try:
    if buffer[tokenPtr] == "]":
      return
    var f : float
    var arrayContents : seq[float]
    var endArray = false
    while not endArray:
      if buffer[tokenPtr].len > 0:
        if scanf(buffer[tokenPtr], "$f", f):
          arrayContents.add(parseFloat(buffer[tokenPtr]))
        else:
          raise newException(ArithmeticDefect, "arithmetic error")
      tokenPtr += 1
      if buffer[tokenPtr] == "]":
        endArray = true
    if arrayContents.len > 0:
      astack.push(arrayContents)
  except:
    error("invalid array")
    warning(fmt"""problem at [{tokenPtr}]: "{buffer[token_ptr]}"""")
    while buffer[tokenPtr] != "]":
      tokenPtr += 1
  buffer = bufferBackup

proc array2d =
  let width = popInt()
  let height = popInt()
  let name = sstack.pop.strip
  named2dArrays[name] = newSeqWith(height, newSeq[0.0](width))
  if not noLog:
    info(fmt"""2d array of size {width}, {height} created at "{name}"""")

proc atArrayIndex =
  try:
    let index = popInt()
    if index >= astack.peek.len or index < 0:
      error("specified index outside bounds of array")
      warning(fmt"{index} not in 0..{astack.peek.len - 1}")
    else:
      let item = astack.peek[index]
      stack.push(item)
  except:
    error("requires an int index on top stack and an active array")
    usage("2 @   would push 7 to stack with array [ 5 6 7 8 ]")
    memDump()

proc atArray2dIndex =
  var i, j : int
  var name : string
  try:
    j = popInt()
    i = popInt()
    name = sstack.peek
    if j < named2dArrays[name].len and j >= 0:
      if i < named2dArrays[name][j].len and j >= 0:
        stack.push(named2dArrays[name][j][i])
      else:
        error(fmt"""index {i} not in {name}[{j}]""")
        info(fmt"""token index: {tokenPtr}""")
        memDump()
    else:
      error(fmt"""index {j} not in {name}""")
      info(fmt"""token index: {tokenPtr}""")
      memDump()
  except:
    error(fmt"""cannot retrieve value at {name}[{j}][{i}]""")
    info(fmt"""token index: {tokenPtr}""")
    memDump()

proc toArray =
  try:
    let stackContents = stack.toSeq
    stack.clear
    astack.push(stackContents)
  except:
    error("cannot declare empty array, nothing on stack")
    memDump()

proc fromArray =
  try:
    let arrayContents = astack.pop
    for number in arrayContents:
      stack.push(number)
  except:
    error("nothing to push to stack, no array in memory")
    memDump()

proc arrayCmp =
  try:
    var xyEqual = true
    let x = astack.pop.toSeq
    let y = astack.pop.toSeq
    if x.len != y.len:
      xyEqual = false
    else:
      var i = 0
      while i < x.len:
        if not almostEqual(x[i], y[i]):
          xyEqual = false
        i += 1
    if xyEqual:
      stack.push(1.0)
    else:
      stack.push(0.0)
    astack.push(y)
  except:
    error("cannot compare arrays, must have at least two arrays loaded onto array stack")
    memDump()

proc arrayClear =
  astack.clear

proc array2dFill =
  let value = stack.pop
  let name = sstack.pop
  var j = named2dArrays[name].len - 1
  var i = named2dArrays[name][0].len - 1
  let iMax = i
  while j >= 0:
    while i >= 0:
      named2dArrays[name][j][i] = value
      i += 1
    i = iMax
    j += 1
    
proc aswap =
  try:
    let a1 = astack.pop
    let a2 = astack.pop
    astack.push(a1)
    astack.push(a2)
  except:
    error("less than two arrays on @stack")
    memDump()

proc store =
  var name = sstack.pop
  namedArrays[name] = astack.pop
  if not noLog:
    info(fmt"""{namedArrays[name]} stored at "{name}"""")

proc store2d =
  let j = popInt()
  let i = popInt()
  let name = sstack.pop
  named2dArrays[name][j][i] = stack.pop
  if not noLog:
    info(fmt"""{named2dArrays[name]} stored at "{name}[{j}][{i}]"""")

proc variable =
  let v = stack.pop
  let k = sstack.pop.strip
  vars[k] = v

proc word =
  try:
    discard sstack.peek
  except:
    error("no proc name provided; nothing on $stack")
    memDump()
  try:
    discard qstack.peek
  except:
    error("cannot declare proc without quote body; nothing on qstack")
    memDump()
  try:
    let name = sstack.pop.strip
    procs[name] = qstack.pop
    if not noLog:
      info(fmt"""{name} created""")
  except:
    error("could not create proc")
    memDump()

proc safeWord =
  try:
    discard sstack.peek
  except:
    error("no proc name provided; nothing on $stack")
    memDump()
  try:
    discard qstack.peek
  except:
    error("cannot declare proc without quote body; nothing on qstack")
    memDump()
  try:
    let name = sstack.pop.strip
    procs[name] = fmt"freeze {qstack.pop} unfreeze"
    if not noLog:
      info(fmt"""{name} created""")
  except:
    error("could not create proc")
    memDump()

proc cmd =
  try:
    var result = execCmdEx(sstack.pop)
    stack.push(toFloat(result[1]))
    echo result[0]
    info(fmt"Exit code: {result[1]}")
  except:
    warning("could not execute command or nothing on string stack")

proc openFile =
  outputFile = newFileStream(sstack.pop, fmWrite)

proc closeFile =
  outputFile.close

proc fWriteLn =
  outputFile.writeLine(sstack.pop)

proc toString =
  let n = stack.pop
  if almostEqual(n, n.trunc):
    sstack.push($(n.toInt))
  else: sstack.push($n)

proc concatenate =
  let s2 = sstack.pop
  let s1 = sstack.pop
  sstack.push(s1 & s2)

proc clearStack =
  stack.clear

proc stringToDReg =
  dreg = sstack.pop

proc dRegToString =
  sstack.push(dreg)
  dreg = ""

proc stringLength =
  stack.push(sstack.peek.len.toFloat)

proc stackDump(s : Stack) =
  var i : int = 0
  let stackContents = s.toSeq.reversed
  echo "cell | value"
  for item in stackContents:
    echo fmt"  {i}  |   {$item}"
    i += 1

proc freeze =
  memoryStateSwap = MemoryState(
    # returnPtr : tokenPtr,
    # bufferSwap : buffer,
    stackSwap : stack,
    rstackSwap : rstack,
    sstackSwap : sstack,
    qstackSwap : qstack,
    dregSwap : dreg
  )
  memClear()

proc unfreeze =
    memClear()
    # tokenPtr = memoryStateSwap.returnPtr
    # buffer = memoryStateSwap.bufferSwap
    stack = memoryStateSwap.stackSwap
    rstack = memoryStateSwap.rstackSwap
    sstack = memoryStateSwap.sstackSwap
    qstack = memoryStateSwap.qstackSwap
    dreg = memoryStateSwap.dregSwap

proc memDump =  
  if not stack.isEmpty:
    echo "\nSTACK"
    stackDump(stack)
  if not rstack.isEmpty:
    echo "\nRSTACK"
    stackDump(rstack)
  if not sstack.isEmpty:
    echo "\n$STACK"
    stackDump(sstack)
  if not qstack.isEmpty:
    echo "\nQSTACK"
    stackDump(qstack)
  if dreg != "":
    echo "DREG"
    echo dreg
  if not astack.isEmpty:
    echo "\nARRAYS"
    stackDump(astack)
  echo ""

proc memClear =
  stack.clear()
  rstack.clear()
  sstack.clear()
  qstack.clear()
  dreg = """"""
  astack.clear()
  
proc popInt : int =
  return stack.pop.toInt
  
proc executeQuote(q : string) =
  let tokens : seq[string] = q.split(parseRule)
  if not executingQuote:
    stopQuote = tokens.len
    executingQuote = true
    let returnPtr = tokenPtr
    let bufferBackup = buffer
    buffer = tokens
    tokenPtr = 0
    while tokenPtr < stopQuote:
      let token = buffer[tokenPtr]
      if token.len > 0:
        if debug:
          echo fmt"""({tokenPtr}) {token}"""
        parseToken(token)
      tokenPtr += 1
    tokenPtr = returnPtr
    if interpreting:
      buffer = iftokens
    buffer = bufferBackup
    executingQuote = false
  else:
    buffer.insert(tokens, tokenPtr + 1)
    stopQuote = buffer.len

proc parseToken(token : string) =
  var x : int
  if scanf(token, "$i", x):
    let d = parseFloat(token)
    stack.push(d)
  else:
    if token.len > 0:
      if token[0] == '"':
        sstack.push(token.strip(chars = {'"'}))
      else:
        case token.toLowerAscii:
        of ".": dump()
        of "$": sdump()
        of "+": add()
        of "-": sub()
        of "*": mul()
        of "/": divide()
        of "/%": divrem()
        of "%": modulus()
        of "//": divint()
        of "sqrt": okSqrt()
        of "++": inc()
        of "--": dec()
        of "<<": bsl()
        of ">>": bsr()
        of "trunc": trunc()
        of "floor": floor()        
        of "ceil": ceil()
        of "dup": dup()
        of "drop": drop()
        of "rot": rot()
        of "-rot": unrot()
        of "swap": swap()
        of "over": over()
        of "pick": pick()
        of "tuck": tuck()
        of "roll": roll()
        of "top": top()
        of "$dup": sdup()
        of "$drop": sdrop()
        of "$swap": sswap()
        of "$top": stop()
        of ">r": rpush()
        of "r>": rpop()
        of "rcmp": rcmp()
        of ">q": qpush()
        of "q>": qpop()
        of "(": quote()
        of "'": exqtop()
        of "ex1": exqpop()
        of "exc": exc()
        of "defer": deferex()
        of "dex": dex()
        of "?": question()
        of "?:": questionElse()
        of ">": gt()
        of ">=": gteq()
        of ">0": gt0()
        of "<": lt()
        of "<=": lteq()
        of "<0": lt0()
        of "=": eq()
        of "=0": eq0()
        of "&&": land()
        of "|": lor()
        of "x|": lxor()
        of "!": linv()
        of "map": map1()
        of "mapn": mapn()
        of "[": array()
        of "@new": array2d()
        of "@": atArrayIndex()
        of "@2d": atArray2dIndex()
        of "@2dFill": array2dFill()
        of ">@": toArray()
        of "@>": fromArray()
        of "@cmp": arrayCmp()
        of "@clear": arrayClear()
        of "@swap": aswap()
        of "store": store()
        of "store2d": store2d()
        of "var": variable()
        of "proc": word()
        of "safeproc": safeWord()
        of "cmd": cmd()
        of "file": openFile()
        of "close": closeFile()
        of "fwriteln": fWriteLn()
        of "to$": toString()
        of "&": concatenate()
        of "clear": clearStack()
        of "$>d": stringToDReg()
        of "d>$": dRegToString()
        of "$len": stringLength()
        of "freeze": freeze()
        of "unfreeze": unfreeze()        
        of "memclear": memClear()
        of "memdump": memDump()
        of "include": incl()
        of "help": help()
        of "private": discard
        of "apd": todo("swap to standard arbitrary precision decimal context")
        of "int": todo("swap to integer context")
        of "float": todo("swap to floating point context")
        else:
          if token in vars:
            stack.push(vars[token])
          elif token in procs:
            executeQuote(procs[token])
          elif token in namedArrays:
            astack.push(namedArrays[token])            
            if not noLog:
              info(fmt"""{namedArrays[token]} loaded from "{token}"""")
          else: error(fmt""" unknown word "{token}"""")

proc repl =
  var shouldEnd : bool = false
  while not shouldEnd:
    let prompt : string = "> " 
    let input : string = readLineFromStdin(prompt)
    if input != "quit":
      let tokens : seq[string] = input.split(parseRule)
      buffer = tokens
      tokenPtr = 0
      while tokenPtr < tokens.len:
        let token = tokens[tokenPtr]
        if token.len > 0:
          if helpMode:
            if docs[token] == "":
              echo fmt"""No help available for "{token}""""
            else: echo docs[token]
            helpMode = false
          else: 
            if debug:
              echo fmt"""[{tokenPtr}] {token}"""
            parseToken(token)
        tokenPtr += 1
      echo "ok"
      if debug:
        memDump()
    else:
      shouldEnd = true

proc incl() =
  var file : string
  try:
    including = true
    file = sstack.pop.strip
    let returnPtr = tokenPtr
    let bufferSwap = buffer
    let stackSwap = stack
    let rstackSwap = rstack
    let sstackSwap = sstack
    let qstackSwap = qstack
    let dregSwap = dreg
    buffer.setLen(0)
    memClear()
    interpret(file)
    memClear()
    tokenPtr = returnPtr
    buffer = bufferSwap
    stack = stackSwap
    rstack = rstackSwap
    sstack = sstackSwap
    qstack = qstackSwap
    dreg = dregSwap
  except:
    error(fmt"""cannot read file "{file}"""")
    memDump()
  including = false

proc preprocess(file : string) : string = 
  var processed = """"""
  var line = """"""
  try:
    let raw = open(file)
    while readLine(raw, line):
      var i = 0
      while i < line.len:
        if line[i] == '#':
          i = line.len
        else:
          processed.add(line[i])
          i += 1
      processed.add(' ')
  except:
    error(fmt"""cannot read file "{file}"""")
  return processed

proc interpret(file : string) =
  interpreting = true
  ifbuffer = preprocess(file)
  iftokens = ifbuffer.split(parseRule)
  let tokens : seq[string] = iftokens
  buffer = iftokens
  tokenPtr = 0
  while tokenPtr < buffer.len:
    let token = buffer[tokenPtr]
    if token.len > 0:
      if helpMode:
        helpMode = false
      elif including:
        if token == "private":
          break
        else:
          parseToken(token)
      else: 
        parseToken(token)
        if debug:
          memDump()
    tokenPtr += 1

proc error(text : string) =
  styledEcho styleBright, fgRed, "ERROR:", resetStyle, fmt" {text}"
  
proc warning(text : string) =
  styledEcho styleBright, fgYellow, "WARNING:", resetStyle, fmt" {text}"

proc usage(text : string) =
  styledEcho styleBright, fgCyan, "USAGE:", resetStyle, fmt" {text}"

proc info(text : string) =
  styledEcho styleDim, fgBlue, fmt"{text}"
  
proc todo(text : string) =
  styledEcho styleBright, fgYellow, "TODO:", resetStyle, fmt" {text}"

proc pass(text : string) =
  styledEcho styleBright, fgGreen, "[PASS]", resetStyle, fmt" {text}"

proc fail(text : string) =
  styledEcho styleBright, fgRed, "[FAIL]", resetStyle, fmt" {text}"
  
if isMainModule:
  let params = commandLineParams()
  if params.len == 0:
    repl()
  elif params.len == 1:
    case params[0]:
    of "debug":
      debug = true
      repl()
    of "noLog":
      noLog = true
      repl()
    else:
      interpret(params[0])
  elif params.len == 2:
    case params[0]:
    of "debug":
      debug = true
      try:
        interpret(params[1])
      except IndexDefect:
        error(fmt"index defect at tokenPtr: {tokenPtr}")
        memDump()
        
      except:
        error("unknown interpretation error")
    of "noLog":
      noLog = true
      interpret(params[1])
    else:
      echo fmt"Unknown command: {params[0]}"
