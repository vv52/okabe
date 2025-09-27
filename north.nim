import std/[strutils, strscans]
import stacks

proc main() : void
proc add() : void
proc sub() : void
proc mul() : void
proc dup() : void

var stack = newStack[int](capacity = 64)

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

proc swap =
  let a = stack.pop()
  let b = stack.pop()
  stack.push(a)
  stack.push(b)

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
          of "swap": swap()
          echo stack.peek()
      echo "ok"
    else:
      should_end = true

if isMainModule:
  main()
