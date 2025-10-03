import std/[strutils, strscans, strformat, strtabs]
import std/[algorithm, sequtils, cmdline, re]
from std/math import divmod
import stacks

var docs = newStringTable()

proc dump() : void
docs["."] = "( a -- ) echo a"
proc peek() : void
docs["peek"] = "( a -- a ) echo a"
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
proc dup() : void
docs["dup"] = "( a -- a a )"
proc drop() : void
docs["drop"] = "( a -- )"
proc rot() : void
docs["rot"] = "( a b c -- b c a )"
proc swap() : void
docs["swap"] = "( a b -- b a )"
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
proc quote() : void
docs["("] = "begin storing code for later execution; terminates at matched ')'"
proc exn() : void
docs["exn"] = ("q( q -- q ) peek qstack and execute quote")
proc ex1() : void
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

let parse_rule = re"""\s+(?=(?:[^\'"]*[\'"][^\'"]*[\'"])*[^\'"]*$)"""

proc help =
  help_mode = true

proc dump =
  if stack.isEmpty():
    echo: "ERROR: nothing on stack to pop"
  else:
    echo stack.pop()

proc peek =
  if stack.isEmpty():
    echo: "ERROR: nothing on stack to peek"
  else:
    echo stack.peek()

proc add =
  let a = stack.pop()
  let b = stack.pop()
  stack.push(a + b)
  
proc sub =
  let a = stack.pop()
  let b = stack.pop()
  stack.push(b - a)
  
proc mul =
  let a = stack.pop()
  let b = stack.pop()
  stack.push(a * b)

proc divide = 
  let a = stack.pop()
  let b = stack.pop()
  let x = divmod(b, a)
  stack.push(x[0])
  
proc divrem = 
  let a = stack.pop()
  let b = stack.pop()
  let x = divmod(b, a)
  stack.push(x[1])
  stack.push(x[0])
  
proc modulus = 
  let a = stack.pop()
  let b = stack.pop()
  let x = divmod(b, a)
  stack.push(x[1])

proc dup =
  stack.push(stack.peek())
  
proc drop =
  discard stack.pop()

proc rot =
  let a = stack.pop()
  let b = stack.pop()
  let c = stack.pop()
  stack.push(b)
  stack.push(a)
  stack.push(c)

proc swap =
  let a = stack.pop()
  let b = stack.pop()
  stack.push(a)
  stack.push(b)

proc over =
  let a = stack.pop()
  let b = stack.pop()
  stack.push(b)
  stack.push(a)
  stack.push(b)

proc pick =
  let i = stack.pop()
  let temp = stack.toSeq.reversed
  stack.push(temp[i])
  
proc tuck =
  let top = stack.peek()
  swap()
  stack.push(top)
  
proc roll =
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

proc rpush =
  if stack.isEmpty():
    echo: "ERROR: nothing on stack to pop"
  else:
    rstack.push(stack.pop)
  
proc rpop =
  if rstack.isEmpty():
    echo: "ERROR: nothing on rstack to pop"
  else:
    stack.push(rstack.pop)
  
proc quote =
  token_ptr += 1
  var quoted = """"""
  while buffer[token_ptr] != ")":
    if buffer[token_ptr].len > 0:
      if buffer[token_ptr] == "(": quote()
      else: quoted = fmt"""{quoted}{buffer[token_ptr]} """
    token_ptr += 1
  qstack.push(quoted)

proc exn =
  if not qstack.isEmpty:
    executeQuote(qstack.peek)

proc ex1 =
  if not qstack.isEmpty:
    executeQuote(qstack.pop)

proc exc =
  if not qstack.isEmpty:
    discard qstack.pop

proc deferex =
  if not qstack.isEmpty:
    dreg = qstack.pop

proc dex =
  executeQuote(dreg)

proc question =
  if stack.pop > 0:
    executeQuote(qstack.pop)
  else:
    discard qstack.pop

proc questionelse =
  if stack.pop > 0:
    discard qstack.pop
    executeQuote(qstack.pop)
  else:
    executeQuote(qstack.pop)
    discard qstack.pop

proc gt0 =
  if stack.peek > 0:
    stack.push(1)
  else: stack.push(0)

proc lt0 =
  if stack.peek < 0:
    stack.push(1)
  else: stack.push(0)

proc eq0 =
  if stack.peek == 0:
    stack.push(1)
  else: stack.push(0)

proc word =
  procs[sstack.pop] = qstack.pop

proc stackDump(s : Stack) =
  var i : int = 0
  let stack_dump = s.toSeq.reversed
  echo "cell | value"
  for item in stackdump:
    echo fmt"  {i}  |   {$item}"
    i += 1

proc executeQuote(q : string) =
  let tokens : seq[string] = q.split(parseRule)
  buffer = tokens
  var quote_ptr = 0
  while quote_ptr < tokens.len:
    let token = tokens[quote_ptr]
    if token.len > 0:
      parseToken(token)
    quote_ptr += 1

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
        of "+": add()
        of "-": sub()
        of "*": mul()
        of "/": divide()
        of "/%": divrem()
        of "%": modulus()
        of "dup": dup()
        of "drop": drop()
        of "rot": rot()
        of "swap": swap()
        of "over": over()
        of "pick": pick()
        of "tuck": tuck()
        of "roll": roll()
        of "peek": peek()
        of ">r": rpush()
        of "r>": rpop()
        of "(": quote()
        of "exn": exn()
        of "ex1": ex1()
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
          if procs[token] != "":
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
