import options

type BranchPair[T] = object
  then, other: T

# from Arak https://forum.nim-lang.org/t/3342
proc `!`*[T](a, b: T): BranchPair[T] {.inline.} = BranchPair[T](then: a, other: b)

template `?`*[T](cond: bool; p: BranchPair[T]): T = (if cond: p.then else: p.other)

#true if not 0 or NaN
template truthy*(val: float): bool  = (val < 0 or val > 0)

#true if not 0
template truthy*(val: int): bool  = (val != 0)

#true if true
template truthy*(val: bool): bool = val

#true if not empty
template truthy*(val: string): bool = (val != "")

# true if not isNil()
template truthy*[T](val: T): bool = not compiles(val.isNil())

# true if not empty
template truthy*[T](val: seq[T]): bool = (val != @[])

# true if not none
template truthy*[T](val: Option[T]): bool = isSome(val)

# like truthy but also returns false on an exception.
template `?`*[T](val: T): bool = (try: truthy(val) except: false)

# return left if truthy and unexcpetional otherwise right
template `?:`*[T](left: T, right: T): T = 
  if ?left: left else: right

template `?:`*[T](left: T, right: Option[T]): Option[T] = 
  if ?left: some(left) else: right
 
template `?:`*[T](left: Option[T], right: T): T = 
  if ?left.get(): left.get() else: right

when isMainModule:
  import unittest
  import tables
 
  template `==`[T](left: Option[T], right: T): bool =
    if isSome(left): left.get() == right else: false

  template `==`[T](left: T, right: Option[T]): bool =
    right == left

  suite "truthy": 
    var s0: string
    var a0: seq[string]
    test "empty string": check(not(truthy("")))
    test "zero float": check(not ?0.0)
    test "NaN float": check(not ?NaN)
    test "zero int": check(not ?0)
    test "empty seq": check(not ?a0)
    test "none option": check(not ?none(string))
    test "not empty string": check(?"1")
    test "not zero float": check(?1.1)
    test "not zero int": check(?1)
    test "not empty seq": check(?[0])
    test "some option": check(?some(""))

  suite "ternary":
    test "true": check((false ? "a" ! "b") == "b")
    test "false": check((true ? "a" ! "b") == "a")
    test "false truthy": check((?0 ? "a" ! "b") == "b")
    test "true truthy": check((?1 ? "a" ! "b") == "a")
 
  suite "elvis number": 
    test "zero left": check((0 ?: 1) == 1)
    test "good left": check((1 ?: 2) == 1)
    test "expr left": check(((1 - 1) ?: 1) == 1)
    
  suite "elvis sequence":
    var s:seq[int] 
    test "empty left": check((s ?:  @[1]) == @[1])
    test "good  left": check((@[0] ?: @[1]) == @[0])

  suite "elvis except":
    let tab = { "one": 1 }.newTable
    test "none left": check((tab["two"] ?: 0) == 0)
    test "good left": check((tab["one"] ?: 0) == 1)

  suite "elvis string": 
    var s0: string
    test "empty left": check(("" ?: "empty") == "empty")
    test "uninit left": check((s0 ?: "empty") == "empty")
    test "good  left": check(("good" ?: "empty") == "good")

  suite "elvis except":
    let tab = { "one": 1 }.newTable
    test "none left": check((tab["two"] ?: 0) == 0)
    test "good left": check((tab["one"] ?: 0) == 1)
    
  suite "coalesce option and option":
    test "left some":
      let a: Option[string] = some("a")
      let b: Option[string] = none(string)
      check((a ?: b) == a)
    test "left none":
      let a: Option[string] = none(string)
      let b: Option[string] = some("b")
      check((a ?: b) == b)
    test "left not nillable":
      let a: Option[int] = some(0)
      let b: Option[int] = some(1)
      check((a ?: b) == a)

  suite "coalesce option and raw":
    test "left some":
      let a: Option[string] = some("a")
      let b: string = "b"
      check((a ?: b) == a)
    test "left none":
      let a: Option[string] = none(string)
      let b: string = "b"
      check((a ?: b) == b)
    
  suite "coalesce raw and option":
    test "left not nil":
      let a: string = "a"
      let b: Option[string] = none(string)
      check((a ?: b) == a)
    test "left empty":
      var a: string
      let b: Option[string] = some("b")
      check((a ?: b) == b)
  
  suite "coalesce options and raw":
    test "first some":
      let a: Option[string] = some("a")
      let b: Option[string] = some("b")
      let c: string = "c"
      check((a ?: b ?: c) == a)
    test "second some":
      let a: Option[string] = none(string)
      let b: Option[string] = some("b")
      let c: string = "c"
      check((a ?: b ?: c) == b)
    test "both none":
      let a: Option[string] = none(string)
      let b: Option[string] = none(string)
      let c: string = "c"
      check((a ?: b ?: c) == c)

  suite "coalesce option and raws":
    test "first some":
      let a: Option[string] = some("a")
      let b: string = "b"
      let c: string = "c"
      check((a ?: b ?: c) == a)
    test "first none, second not nil":
      let a: Option[string] = none(string)
      let b: string = "b"
      let c: string = "c"
      check((a ?: b ?: c) == b)
    test "first none, second empty":
      let a: Option[string] = none(string)
      let b: string = ""
      let c: string = "c"
      check((a ?: b ?: c) == c)

  suite "coalesce raw and options":
    test "first not nil":
      let a: string = "a"
      let b: Option[string] = some("b")
      let c: Option[string] = some("c")
      check((a ?: b ?: c) == a)
    test "first empty, second some":
        let a: string = ""
        let b: Option[string] = some("b")
        let c: Option[string] = some("c")
        check((a ?: b ?: c) == b)
    test "first nil, second none":
      let a: string = ""
      let b: Option[string] = none(string)
      let c: Option[string] = some("c")
      check((a ?: b ?: c) == c)

  suite "coalesce raws and option":
    test "first not nil":
      let a: string = "a"
      let b: string = "b"
      let c: Option[string] = some("c")
      check((a ?: b ?: c) == a)
    test "first empty, second not nil":
      let a: string = ""
      let b: string = "b"
      let c: Option[string] = some("c")
      check((a ?: b ?: c) == b)
    test "first empty, second empty":
      let a: string = ""
      let b: string = ""
      let c: Option[string] = some("c")
      check((a ?: b ?: c) == c)

  suite "short circuit options":
    test "first some":
      proc getA(): Option[string] = return some("a")
      proc getB(): Option[string] = raise newException(ValueError, "expensive operation")
      discard getA() ?: getB()
    test "first none":
      proc getA(): Option[string] = return none(string)
      proc getB(): Option[string] = raise newException(ValueError, "expensive operation")
      expect ValueError:
        discard getA() ?: getB()

  suite "short circuit raws":
    test "first not nil":
      proc getA(): string = return "a"
      proc getB(): string = raise newException(ValueError, "expensive operation")
      discard getA() ?: getB()
    test "first empty":
      proc getA(): string = return ""
      proc getB(): string = raise newException(ValueError, "expensive operation")
      expect ValueError:
        discard getA() ?: getB()
