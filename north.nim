import std/[strutils, strscans, strformat, algorithm, sequtils]
import stacks

proc add() : void
proc sub() : void
proc mul() : void
proc dup() : void
proc drop() : void
proc rot() : void
proc swap() : void
proc over() : void
proc pick() : void
proc tuck() : void
proc roll() : void
proc stackDump() : void
proc main() : void

var stack = newStack[int](capacity = 64)
var rstack = newStack[int](capacity = 64)

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

proc stackDump =
  var i : int = 0
  let stack_dump = stack.toSeq.reversed
  echo "\ncell | value"
  for item in stackdump:
    echo fmt"  {i}  |   {$item}"
    i += 1

proc main =
  var should_end : bool = false
  while not should_end:
    let input : string = readLine(stdin)
    if input != "quit":
      let tokens : seq[string] = input.split(' ')
      for token in tokens:
        var x : int
        if scanf(token, "$i", x):
          stack.push(x)
        else:
          case token:
          of "+": add()
          of "-": sub()
          of "*": mul()
          of "dup": dup()
          of "drop": drop()
          of "rot": rot()
          of "swap": swap()
          of "over": over()
          of "pick": pick()
          of "tuck": tuck()
          of "roll": roll()
          echo stack.peek()
      echo "ok"
      stackDump()
    else:
      should_end = true

if isMainModule:
  main()
