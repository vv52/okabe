import std/[strutils, strscans, strformat, strtabs]
import std/[algorithm, sequtils, cmdline, re]
from std/math import divmod
import stacks

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
docs["/"] = "( a b -- c ) a / b, floored int"
proc divrem() : void
docs["/%"] = "( a b -- c d ) a / b, int and remainder"
proc modulus() : void
docs["%"] = "( a b -- c ) a / b, remainder"
proc inc() : void
docs["++"] = "( a -- b ) b is a + 1"
proc dec() : void
docs["--"] = "( a -- b ) b is a - 1"
proc bsl() : void
docs["<<"] = "( a b -- c ) c is a bitshifted left b times"
proc bsr() : void
docs[">>"] = "( a b -- c ) c is a bitshifted right b times"
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
proc word() : void
docs["proc"] = "$( s -- ) ()( q -- ) make new word from top of string stack that does top of qstack"
proc stackDump(s : Stack) : void
proc executeQuote(q : string) : void
proc parseToken(token : string) : void
proc repl() : void
proc interpret(file : string) : void
proc compile(file : string) : void

var debug = false
var help_mode = false

var stack = newStack[int](capacity = 16)     # THE stack
var rstack = newStack[int](capacity = 16)    # rstack for forth algs
var sstack = newStack[string](capacity = 16) # stack for string literals
var qstack = newStack[string](capacity = 16) # stack for quoted code in conditionals and processes

var dreg : string
var buffer : seq[string]

var procs = newStringTable()

var token_ptr : int = 0

let parse_rule = re"""\s+(?=(?:[^\"]*[\"][^\"]*[\"])*[^\"]*$)"""

proc help =
  help_mode = true

proc dump =
  try:
    echo stack.pop()
  except:
    echo: "ERROR: nothing on stack to pop"

proc sdump =
  try:
    echo sstack.pop()
  except:
    echo: "ERROR: nothing on $stack to pop"

proc top =
  try:
    echo stack.peek()
  except:
    echo: "ERROR: nothing on stack to peek"

proc add =
  try:
    let a = stack.pop()
    let b = stack.pop()
    stack.push(a + b)
  except:
    echo "ERROR: less than two numbers on stack"
  
proc sub =
  try:
    let a = stack.pop()
    let b = stack.pop()
    stack.push(b - a)
  except:
    echo "ERROR: less than two numbers on stack"
  
proc mul =
  try:
    let a = stack.pop()
    let b = stack.pop()
    stack.push(a * b)
  except:
    echo "ERROR: less than two numbers on stack"

proc divide = 
  try:
    let a = stack.pop()
    let b = stack.pop()
    let x = divmod(b, a)
    stack.push(x[0])
  except DivByZeroDefect:
    echo "ERROR: division by zero"
  except:
    echo "ERROR: less than two numbers on stack"
  
proc divrem = 
  try:
    let a = stack.pop()
    let b = stack.pop()
    let x = divmod(b, a)
    stack.push(x[1])
    stack.push(x[0])
  except DivByZeroDefect:
    echo "ERROR: division by zero"
  except:
    echo "ERROR: less than two numbers on stack"
  
proc modulus = 
  try:
    let a = stack.pop()
    let b = stack.pop()
    let x = divmod(b, a)
    stack.push(x[1])
  except DivByZeroDefect:
    echo "ERROR: division by zero"
  except:
    echo "ERROR: less than two numbers on stack"

proc inc =
  try:
    stack.push(stack.pop + 1)
  except:
    echo "ERROR: nothing on stack to increment"

proc dec =
  try:
    stack.push(stack.pop - 1)
  except:
    echo "ERROR: nothing on stack to decrement"

proc bsl =
  try:
    let times = stack.pop
    let x = stack.pop
    stack.push(x shl times)
  except:
    echo "ERROR: less than two numbers on stack"

proc bsr =
  try:
    let times = stack.pop
    let x = stack.pop
    stack.push(x shr times)
  except:
    echo "ERROR: less than two numbers on stack"

proc dup =
  try:
    stack.push(stack.peek())
  except:
    echo "ERROR: nothing on stack to duplicate"
  
proc drop =
  try:
    discard stack.pop()
  except:
    echo "ERROR: nothing on stack to drop"

proc rot =
  try:
    let a = stack.pop()
    let b = stack.pop()
    let c = stack.pop()
    stack.push(b)
    stack.push(a)
    stack.push(c)
  except:
    echo "ERROR: less than three numbers on stack"

proc swap =
  try:
    let a = stack.pop()
    let b = stack.pop()
    stack.push(a)
    stack.push(b)
  except:
    echo "ERROR: less than two numbers on stack"

proc over =
  try:
    let a = stack.pop
    let b = stack.pop
    stack.push(b)
    stack.push(a)
    stack.push(b)
  except:
    echo "ERROR: less than two numbers on stack"

proc pick =
  try:
    let i = stack.pop
    let temp = stack.toSeq.reversed
    stack.push(temp[i])
  except:
    echo "ERROR: nothing on stack"
  
proc tuck =
  try:
    let top = stack.peek
    swap()
    stack.push(top)
  except:
    echo "ERROR: less than two numbers on stack"
  
proc roll =
  try:
    let i = stack.pop()
    case i:
    of 0: discard
    of 1: swap()
    of 2: rot()
    else:
      var temp = stack.toSeq.reversed
      var newTop : int = temp[i]
      temp.delete(i..i)
      temp = temp.reversed
      stack.clear()
      for item in temp.items:
        stack.push(item)
      stack.push(newTop)
  except:
    echo "ERROR: nothing on stack"

proc sdup =
  try:
    sstack.push(sstack.peek())
  except:
    echo "ERROR: nothing on $stack"
  
proc sdrop =
  try:
    discard sstack.pop
  except:
    echo "ERROR: nothing on $stack"

proc sswap =
  try:
    let s1 = sstack.pop
    let s2 = sstack.pop
    sstack.push(s1)
    sstack.push(s2)
  except:
    echo "ERROR: less than two strings on $stack"

proc stop =
  try:
    echo sstack.peek
  except:
    echo "ERROR: nothing on $stack to peek"

proc rpush =
  try:
    rstack.push(stack.pop)
  except:
    echo: "ERROR: nothing on stack to pop"
  
proc rpop =
  try:
    stack.push(rstack.pop)
  except:
    echo: "ERROR: nothing on rstack to pop"
  
proc quote =
  token_ptr += 1
  if buffer[token_ptr] == ")":
    return
  var depth = 0
  var quoted = """"""
  var end_quote = false
  while not end_quote:
    if buffer[token_ptr].len > 0:
      if buffer[token_ptr] == "(":
        quoted = fmt"""{quoted}( {nested()}) """
      else: quoted = fmt"""{quoted}{buffer[token_ptr]} """
    token_ptr += 1
    if buffer[token_ptr] == ")":
      if depth == 0:
        end_quote = true
  qstack.push(quoted)

proc nested : string =
  token_ptr += 1
  if buffer[token_ptr] == ")":
    return
  var depth = 0
  var quoted = """"""
  var end_quote = false
  while not end_quote:
    if buffer[token_ptr].len > 0:
      if buffer[token_ptr] == "(":
        quoted = fmt"""{quoted}( {nested()}) """
      else: quoted = fmt"""{quoted}{buffer[token_ptr]} """
    token_ptr += 1
    if buffer[token_ptr] == ")":
      if depth == 0:
        end_quote = true
  return quoted  

proc qpush() =
  qstack.push(sstack.pop)

proc qpop() =
  try:
    sstack.push(qstack.pop)
  except:
    echo "ERROR: nothing on qstack to pop"

proc exqtop =
  if not qstack.isEmpty:
    executeQuote(qstack.peek)
  else:
    echo "ERROR: nothing on qstack to peek"

proc exqpop =
  if not qstack.isEmpty:
    executeQuote(qstack.pop)
  else:
    echo "ERROR: nothing on qstack to pop"

proc exc =
  if not qstack.isEmpty:
    discard qstack.pop
  else:
    echo "ERROR: nothing on qstack to drop"

proc deferex =
  if not qstack.isEmpty:
    dreg = qstack.pop
  else:
    echo "ERROR: nothing on qstack to pop"

proc dex =
  executeQuote(dreg)

proc question =
  try:
    discard stack.peek
  except:
    echo "ERROR: no condition result on stack to pop"
  try:
    discard qstack.peek
  except:
    echo "ERROR: no branch on qstack to pop"
  try:
    if stack.pop > 0:
      executeQuote(qstack.pop)
    else:
      discard qstack.pop
  except:
    echo "ERROR: syntax"
    echo "USAGE: cond_result_int ( branch_quote ) ?"

proc questionelse =
  try:
    discard stack.peek
  except:
    echo "ERROR: no condition result on stack to pop"
  if qstack.len < 2:
    echo "ERROR: less than two quotes on qstack"
  try:
    if stack.pop > 0:
      discard qstack.pop
      executeQuote(qstack.pop)
    else:
      executeQuote(qstack.pop)
      discard qstack.pop
  except:
    echo "ERROR: syntax"
    echo "USAGE: cond_result_int ( 1+_branch ) ( 0-_branch ) ?:"

proc gt0 =
  try:
    if stack.peek > 0:
      stack.push(1)
    else: stack.push(0)
  except:
    echo "ERROR: nothing on stack to compare"

proc lt0 =
  try:
    if stack.peek < 0:
      stack.push(1)
    else: stack.push(0)
  except:
    echo "ERROR: nothing on stack to compare"

proc eq0 =
  try:
    if stack.peek == 0:
      stack.push(1)
    else: stack.push(0)
  except:
    echo "ERROR: nothing on stack to compare"

proc word =
  try:
    discard sstack.peek
  except:
    echo "ERROR: no proc name provided; nothing on $stack"
  try:
    discard qstack.peek
  except:
    echo "ERROR: cannot declare proc without quote body; nothing on qstack"
  try:
    let name = sstack.pop.strip
    procs[name] = qstack.pop
    echo fmt"""{name} created"""
  except:
    echo "ERROR: could not create proc"

proc stackDump(s : Stack) =
  var i : int = 0
  let stack_dump = s.toSeq.reversed
  echo "cell | value"
  for item in stackdump:
    echo fmt"  {i}  |   {$item}"
    i += 1

proc executeQuote(q : string) =
  let return_ptr = token_ptr
  let tokens : seq[string] = q.split(parseRule)
  buffer = tokens
  token_ptr = 0
  while token_ptr < tokens.len:
    let token = tokens[token_ptr]
    if token.len > 0:
      parseToken(token)
    token_ptr += 1
  token_ptr = return_ptr

proc parseToken(token : string) =
  var x : int
  if scanf(token, "$i", x):
    stack.push(x)
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
        of "++": inc()
        of "--": dec()
        of "<<": bsl()
        of ">>": bsr()
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
        of "proc": word()
        of "help": help()
        else:
          if token in procs:
            executeQuote(procs[token])
          else: echo fmt"""ERROR: Unknown word "{token}""""

proc repl =
  var should_end : bool = false
  while not should_end:
    let input : string = readLine(stdin)
    if input != "quit":
      let tokens : seq[string] = input.split(parseRule)
      buffer = tokens
      token_ptr = 0
      while token_ptr < tokens.len:
        let token = tokens[token_ptr]
        if token.len > 0:
          if help_mode:
            if docs[token] == "":
              echo fmt"""No help available for "{token}""""
            else: echo docs[token]
            help_mode = false
          else: parseToken(token)
        token_ptr += 1
      echo "ok"
      if debug:
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
    else:
      should_end = true

proc interpret(file : string) =
  echo "TODO: add file interpreter"

proc compile(file : string) =
  echo "TODO: add file compiler to asm or nim"

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
  else:
    echo "TODO: File handling and options"
