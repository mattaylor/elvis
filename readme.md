# Elvis

The __Elvis__ package implements a __truthy__ (`?`), __ternary__ (`?!`), __coalesce__ (`?:`) and a __conditional assignment__ (`?=`) operator and an experimental __conditional access operator__ (`.?`) as syntactic sugar for Nim to work with conditional expressions using more than just boolean types. 

### Truthy operator  `?`

The `?` operator will try to convert any expression to a boolean. In general a value is considered false if it has not yet been initialised or isNil, none or throws an excpetion. 

These rules are currently implmented..

| type   | false |  falsy example  | truthy example 
|--------|-------|----------|---------------
| int    | 0     | `assert(not(?0))` | `assert ?1`  
| float  | 0.0 or NaN   | `assert(not(?NaN))` | `assert ?1.1`
| char   | \0    | `assert(not(?'\0'))` | `assert ?'0'`
| string | ""    | `assert(not(?""))` | `assert ?"0"`
| seq[T] | @[]   | `var s:seq[int]; assert(not(?s))` | `assert ?(@[0])`
| option[T] | none   | `assert(not(none(string)))` | `assert ?some("")`
| Any    | exception   | `assert(not(?{"one":1}.newTable["two"]))` | `assert ?{"one":1}.newTable["one"]`
| nilable | isNil()   | `` | ``

### Elvis Operator `?:`

The elvis operator will return the left operand if it is 'truthy' otherwise it will return the right operand.

See [null coalescing operator](https://en.wikipedia.org/wiki/Null_coalescing_operator) `?:` 

Examples, Test and Implmentation ideas have been in part derived from the Coalesce module ('https://github.com/piedar/coalesce'). That module should be prefered by those looking for a stricter implmentation of a Null coalescing operator, but the implmentation here may be more usefull especially now that stings are not nilable (from Nim 0.19)

__Examples:__

```nim
assert ("" ?: "b") == "b"
assert (0 ?: 1) == 1
assert (none(int) ?: 1) == 1
assert (1 ?: 2) == 1
assert ("1" ?: "2") == "1"
```

Longer chains work too, and the expression short-circuits if possible.

eg. 
```nim
let result = tryComputeFast(input) ?: tryComputeSlow(input) ?: myDefault
```

### Ternary Operator `? !`

The Ternary operator will return the  middle operand if the left operand evaluates as truthy otherwise it will return the right operand.

This implementation was taken from Araq's suggestion on from https://forum.nim-lang.org/t/3342

Note: Due to compiler limitations the '!' operation is implemented as a proc and is evaluated eagerly. 

__Examples:__

```nim
assert (true ? "a" ! "b") == "a"
assert (false ? "a" ! "b") == "b"
assert ("c" ? "a" ! "b") == "a"
assert ("" ? "a" ! "b") == "b"
```

### Conditional Assignment Operator `?=`

The Conditional assignment operator will assign the right operand to the left operand only when the left operand evaluates as falsey

__Examples:__

```nim
var s:string
s ?= "a" 
assert (s == "a")
s ?= "b"
assert (s == "a")
```
### Conditional Assignment Operator (Reverse) `=?`

The Reverse Conditional assignment operator will assign the right operand to the left operand only when the right operand evaluates as truthy

__Examples:__

```nim
var s:string
s =? "a" 
assert (s == "a")
s =? ""
assert (s == "a")
```


### Conditional Access Operator `.?`

The Conditional access operator will call the right operand with the left operand as thefirst argument when the left operand evaluates as truthy. Otherwise it will return a new unintiated instance (falsy) whatever type the right operand proc would have returned. Chained conditional access is also supported for pertties and simple functions, however conidtioanl access to chained function calls with additonal arguments will currnetly not compile.

__Examples:__

```nim
 let opt0 = none(string)
 let opt1 = some("one")
 assert(opt0.?get.?len == 0)
 assert(opt1.?get.?len == 3)
 #assert(opt1.?get("none") == "none" # compile error 
```
