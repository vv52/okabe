import std/[strutils, strscans, strformat, strtabs]
import std/[algorithm, sequtils, tables, re]
import std/[cmdline, terminal, osproc]
import stacks, decimal

# TODO: ARRAYS, MAP, STRING OPS, ITERATORS, ENUM

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
docs["ex1"] = ("q( q -- ) pop qstack and execute quote")
proc exc() : void
docs["exc"] = ("q( q -- ) drop qstack and discard quote")
proc deferex() : void
docs["defer"] = ("q( q -- ) dreg[q] pop qstack and push to dreg")
proc dex() : void
docs["dex"] = ("execute quote in dreg")
proc question() : void
docs["?"] = ("( b -- ) q( q -- ) pop stack, pop qstack; if greater than 0, execute quote, otherwise discard")
proc questionelse() : void
docs["?:"] = ("( b -- ) q( q q -- ) pop stack; if greater than 0, qswap qpop execute qdrop, otherwise qpop execute qdrop")
proc gt0() : void
docs["gt0"] = ("( a -- a b ) if a is greater than 0, b is 1, otherwise b is 0")
proc lt0() : void
docs["lt0"] = ("( a -- a b ) if a is less than 0, b is 1, otherwise b is 0")
proc eq0() : void
docs["eq0"] = ("( a -- a b ) if a is equal to 0, b is 1, otherwise b is 0")
proc land() : void
docs["&"] = ("( t f -- f ) logical and, only returns 1 if both are also 1, otherwise returns 0")
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
proc map2() : void
docs["map2"] = ("[ a b c d -- e f g h ] apply top of quote stack to a and b, producing e and f, etc")
proc map4() : void
docs["map4"] = ("[ a b c d -- e f g h ] apply top of quote stack to a b c and d, producing e f g and h, etc")
proc array() : void
docs["["] = "[ a b c ] creates an anonymous array in memory"
proc store() : void
docs["store"] = "$( s -- ) pop string stack, pop internal array stack, store array in memory at string"
proc word() : void
docs["proc"] = "$( s -- ) ()( q -- ) make new word from top of string stack that does top of qstack"
proc cmd() : void
docs["cmd"] = "$( s -- ) ( -- e ) pop string stack and exec in shell, push exit code to stack and echo output"
proc stackDump(s : Stack) : void
proc memDump() : void
proc memClear() : void
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
var helpMode = false
var interpreting = false

var stack = newStack[DecimalType](capacity = 64)     # THE stack
var rstack = newStack[DecimalType](capacity = 64)    # rstack for forth algs
var sstack = newStack[string](capacity = 64) # stack for string literals
var qstack = newStack[string](capacity = 64) # stack for quoted code in conditionals and processes
var arrays = newStack[seq[DecimalType]](capacity = 16)
# var sarrays = newStack[seq[string]](capacity = 16)

var dreg : string
var buffer : seq[string]
var ifbuffer : string
var iftokens : seq[string]
# var ofbuffer : string

var procs = newStringTable()
var namedArrays = initTable[string, seq[DecimalType]]()

var tokenPtr : int = 0

let parseRule = re"""\s+(?=(?:[^\"]*[\"][^\"]*[\"])*[^\"]*$)"""

proc help =
  helpMode = true

proc dump =
  try:
    echo stack.pop
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
    let a = stack.pop
    let b = stack.pop
    let x = divmod(b, a)
    stack.push(x[0])
  except DivByZeroDefect:
    error("division by zero")
    memDump()
  except:
    error("less than two numbers on stack")
    memDump()
  
proc divrem = 
  try:
    let a = stack.pop
    let b = stack.pop
    let x = divmod(b, a)
    stack.push(x[1])
    stack.push(x[0])
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
    let a = stack.pop
    let b = stack.pop
    let x = divmod(b, a)
    stack.push(x[1])
  except DivByZeroDefect:
    error("division by zero")
  except:
    error("less than two numbers on stack")
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
    stack.push(shift(x, times))
  except:
    error("less than two numbers on stack")
    memDump()

proc bsr =
  try:
    let times = stack.pop * -1
    let x = stack.pop
    stack.push(shift(x, times))
  except:
    error("less than two numbers on stack")
    memDump()

proc trunc =
  try:
    stack.push(truncate(stack.pop))
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
    let a = stack.pop
    let b = stack.pop
    let c = stack.pop
    stack.push(b)
    stack.push(a)
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
    let i = parseInt($stack.pop)
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
    let i = parseInt($stack.pop)
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
    if stack.peek == rstack.peek:
      stack.push(newDecimal(1))
    else: stack.push(newDecimal(0))
  except:
    error("cannot compare stack and rstack if either is empty")
    memDump()
  
proc quote =
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

proc nested : string =
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

proc qpush() =
  qstack.push(sstack.pop)

proc qpop() =
  try:
    sstack.push(qstack.pop)
  except:
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
  executeQuote(dreg)

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

proc questionelse =
  try:
    discard stack.peek
  except:
    error("no condition result on stack to pop")
    memDump()
  if qstack.len < 2:
    error("less than two quotes on qstack")
    memDump()
  try:
    if stack.pop > 0:
      discard qstack.pop
      executeQuote(qstack.pop)
    else:
      let q = qstack.pop
      discard qstack.pop
      executeQuote(q)
  except:
    error("syntax")
    usage("cond_result_int ( 1+_branch ) ( 0-_branch ) ?:")

proc gt0 =
  try:
    if stack.peek > 0:
      stack.push(newDecimal(1))
    else: stack.push(newDecimal(0))
  except:
    error("nothing on stack to compare")
    memDump()

proc lt0 =
  try:
    if stack.peek < 0:
      stack.push(newDecimal(1))
    else: stack.push(newDecimal(0))
  except:
    error("nothing on stack to compare")
    memDump()

proc eq0 =
  try:
    if stack.peek == 0:
      stack.push(newDecimal(1))
    else: stack.push(newDecimal(0))
  except:
    error("nothing on stack to compare")
    memDump()

proc land() =
  try:
    if stack.pop + stack.pop == 2:
      stack.push(newDecimal(1))
    else: stack.push(newDecimal(0))
  except:
    error("less than two values on stack")
    memDump()
  
proc lor() =
  try:
    let t = stack.pop + stack.pop
    if t == 1 or t == 2:
      stack.push(newDecimal(1))
    else: stack.push(newDecimal(0))
  except:
    error("less than two values on stack")
    memDump()
  
proc lxor() =
  try:
    if stack.pop + stack.pop == 1:
      stack.push(newDecimal(1))
    else: stack.push(newDecimal(0))
  except:
    error("less than two values on stack")
    memDump()

proc eq =
  try:
    if stack.pop - stack.peek == 0:
      stack.push(newDecimal(1))
    else: stack.push(newDecimal(0))
  except:
    error("less than two values on stack")
    memDump()

proc linv =
  try:
    if stack.pop == 0:
      stack.push(newDecimal(1))
    else: stack.push(newDecimal(0))
  except:
    error("nothing on stack")
    memDump()

proc map1 =
  var a = arrays.pop
  var i : int = 0
  while i < a.len:
    stack.push(a[i])
    executeQuote(qstack.peek)
    a[i] = stack.pop
    i += 1
  discard qstack.pop
  arrays.push(a)
  echo arrays.peek

proc map2 =
  var a = arrays.pop
  var b : seq[DecimalType]
  var i : int = 0
  while i < a.len:
    stack.push(a[i])
    stack.push(a[i + 1])
    executeQuote(qstack.peek)
    b.add(stack.pop)
    i += 2
  discard qstack.pop
  arrays.push(b)
  echo arrays.peek

proc map4 =
  var a = arrays.pop
  var i : int = 0
  while i < a.len:
    stack.push(a[i])
    stack.push(a[i + 1])
    stack.push(a[i + 2])
    stack.push(a[i + 3])
    executeQuote(qstack.peek)
    a[i + 3] = stack.pop
    a[i + 2] = stack.pop
    a[i + 1] = stack.pop
    a[i] = stack.pop
    i += 4
  discard qstack.pop
  arrays.push(a)
  echo arrays.peek

proc array =
  tokenPtr += 1
  try:
    if buffer[tokenPtr] == "]":
      return
    # var stringArray = false
    var f : float
    var arrayContents : seq[DecimalType]
    # var sarrayContents : seq[string]
    # if buffer[tokenPtr][0] == '"':
      # stringArray = true
    var endArray = false
    while not endArray:
      if buffer[tokenPtr].len > 0:
        # if stringArray:
          # sarrayContents.add(buffer[tokenPtr])
        # else:
          # if scanf(buffer[tokenPtr], "$f", f):
          #   arrayContents.add(newDecimal(buffer[tokenPtr]))
          # else: raise newException(ArithmeticDefect, "arithmetic error")
        if scanf(buffer[tokenPtr], "$f", f):
          arrayContents.add(newDecimal(buffer[tokenPtr]))
        else: raise newException(ArithmeticDefect, "arithmetic error")
      tokenPtr += 1
      if buffer[tokenPtr] == "]":
        endArray = true
    # if stringArray:
    #   sarrays.push(sarrayContents)
    # else:
    #   arrays.push(arrayContents)
      if arrayContents.len > 0:
        arrays.push(arrayContents)
  except:
    error("invalid array")
    warning(fmt"""problem at [{tokenPtr}]: "{buffer[token_ptr]}"""")
    while buffer[tokenPtr] != "]":
      tokenPtr += 1

proc store =
  var name = sstack.pop
  namedArrays[name] = arrays.pop
  info(fmt"""{namedArrays[name]} stored at "{name}"""")

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
    info(fmt"""{name} created""")
  except:
    error("could not create proc")
    memDump()

proc cmd =
  try:
    var result = execCmdEx(sstack.pop)
    stack.push(newDecimal(result[1]))
    echo result[0]
    echo fmt"Exit code: {result[1]}"
  except:
    warning("could not execute command or nothing on string stack")

proc stackDump(s : Stack) =
  var i : int = 0
  let stackContents = s.toSeq.reversed
  echo "cell | value"
  for item in stackContents:
    echo fmt"  {i}  |   {$item}"
    i += 1

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
  echo ""

proc memClear =
  stack.clear()
  rstack.clear()
  sstack.clear()
  qstack.clear()
  dreg = """"""
  
proc executeQuote(q : string) =
  let returnPtr = tokenPtr
  let tokens : seq[string] = q.split(parseRule)
  buffer = tokens
  tokenPtr = 0
  while tokenPtr < tokens.len:
    let token = tokens[tokenPtr]
    if token.len > 0:
      if debug:
        echo fmt"""({tokenPtr}) {token}"""
        # memDump()
      parseToken(token)
    tokenPtr += 1
  tokenPtr = returnPtr
  if interpreting:
    buffer = iftokens

proc parseToken(token : string) =
  var x : int
  if scanf(token, "$i", x):
    let d = newDecimal(token)
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
        of "?:": questionelse()
        of "gt0": gt0()
        of "lt0": lt0()
        of "eq0": eq0()
        of "&": land()
        of "|": lor()
        of "x|": lxor()
        of "=": eq()
        of "!": linv()
        of "map": map1()
        of "map2": map2()
        of "map4": map4()
        of "[": array()
        of "store": store()
        of "proc": word()
        of "cmd": cmd()
        of "include": incl()
        of "help": help()
        of "bin": todo("swap base to BINARY")
        of "hex": todo("swap base to HEXADECIMAL")
        of "f": todo("swap num mode to FLOAT")
        of "dec": todo("swap base to DECIMAL")
        else:
          if token in procs:
            executeQuote(procs[token])
          elif token in namedArrays:
            arrays.push(namedArrays[token])            
            info(fmt"""{namedArrays[token]} loaded from "{token}"""")
          else: error(fmt""" unknown word "{token}"""")

proc repl =
  var shouldEnd : bool = false
  while not shouldEnd:
    let input : string = readLine(stdin)
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
  while tokenPtr < tokens.len:
    let token = tokens[tokenPtr]
    if token.len > 0:
      if helpMode:
        helpMode = false
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
    else:
      interpret(params[0])
  elif params.len == 2:
    case params[0]:
    of "debug":
      debug = true
      interpret(params[1])
    else:
      echo fmt"Unknown command: {params[0]}"
