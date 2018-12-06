# Elvis

The `elvis` package implements a 'truthy', 'ternary' and a 'coalesce' operator to Nim as syntactic sugar for working with conditional expressions. 

### Truthy operator : `?`

The `?` operator will try to convert any expression to a boolean. In general a value is considered false if it has not yet been initialised or isNil, none or throws an excpetion. 

These rules are currently implmented..

| type   | false |  falsy example  | truthy example 
|--------|-------|----------|---------------
| int    | 0     | `assert(not(?0))` | `assert ?1`  
| float  | 0.0 or NaN   | `assert(not(?NaN))` | `assert ?1.1`
| string | ""    | `assert(not(?""))` | `assert ?"0"`
| seq[T] | @[]   | `var s:seq[int]; assert(not(?s))` | `assert ?(@[0])`
| option[T] | none   | `assert(not(none(string)))` | `assert ?some("")`
| Any    | exception   | `assert(not(?{"one":1}.newTable["two"]))` | `assert ?{"one":1}.newTable["one"]`
| nilable | isNil()   | `` | ``


### Elvis Operator: `?:`

The elvis operator will return the left operand if it is 'truthy' otherwise it will return the right operand.

See [null coalescing operator](https://en.wikipedia.org/wiki/Null_coalescing_operator) `?:` 

Examples, Test and Implmentation ideas have been in part derived from 'https://github.com/piedar/coalesce'

Examples:
  - `assert ("" ?: "b") == "b"`
  - `assert (0 ?: 1) == 1`
  - `assert (none(int) ?: 1) == 1`

Longer chains work too, and the expression short-circuits if possible.

  eg `let result = tryComputeFast(input) ?: tryComputeSlow(input) ?: myDefault`

### Ternary Operator : `? !`

The Ternary operator will return the  middle operand if the left operand evaluates to true otherwise it will return the right operand.

This implementation was taken from Arak's suggestion on from https://forum.nim-lang.org/t/3342

Note: Due to compiler limitations the '!' operation is implemented as a proc and is evaluated eagerly. 

Examples:
- `assert (true ? "a" ! "b") == "a"`
- `assert (false ? "a" ! "b") == "b"`
