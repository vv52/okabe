# okabe-lang

okabe is a reflective, concatenative, interpreted programming language with a cross-platform interpreter and REPL written in Nim.

okabe started out as a forth core implementation that grew beyond that inspiration. while some okabe code looks similar and simple forth words may be definable with the same operations, the recursion model, wordlist, and approach to metaprogramming break from forth heavily.

the primary system of code organization is defining recursive anonymois procedures. the exact same code can become a named procedure with a name provided and the word "proc". named procs are stored in memory for execution on demand, whereas anonymous procedures are stored as strings on a stack that can be manipulated and shifted to and from a string literal stack for printing or modification. anonymous procedures are also utilized in conditional expressions. generally, quotes are the mechanism that drives functional complexity.

okabe embraces the "code as data" approach to metaprogramming.

beside the quote stack and string stack, there is a second pair of interoperable stacks that hold floating point numbers***, "the stack" and the rstack (a holdover from okabe's origin). finally, there is a stack of single dimensional dynamic arrays that can interact with the stack, as well as the defer register, which holds one quote anonymously so it can be executed without interfering with the quote stack.

everything in okabe uses reverse polosh notation

there is no enforced code structure, but numerous examples are provided that can be considered idiomatic okabe.

***these were originally stacks of arbitrary precision decimals, but that proved impractical and eventually held the design back. there may be a subset of okabe released that retains this original data model but it is currently shelved.

# dependencies
```
nimble install stacks
```
