import elvis
import unittest
import tables
import options

template `==`[T](left: Option[T], right: T): bool =
  if isSome(left): left.get() == right else: false

template `==`[T](left: T, right: Option[T]): bool =
  right == left

var str0: string
var seq0: seq[int]
var cha0: char 
let seq1 = @["one"]
let tab0 = { "one": "uno" }.toTable
let tab1 = { "one": 1 }.newTable
let opt0 = none(string)
let opt1 = some("one")


type 
  Data = ref object
    val: int

  Obj = ref object
    data: Data

var nilObj:Obj
var objNilData = Obj()
var obj = Obj()
obj.data = Data()
obj.data.val = 10

suite "truthy": 
  test "empty string": check(not(?""))
  test "zero float": check(not ?0.0)
  test "NaN float": check(not ?NaN)
  test "\0 char": check(not ?cha0)
  test "not \0 char": check(?'0')
  test "zero int": check(not ?0)
  test "empty array": check(not ?seq0)
  test "empty seq lit": check(?seq1)
  test "none option": check(not ?none(string))
  test "not empty string": check(?"1")
  test "not zero float": check(?1.1)
  test "not zero int": check(?1)
  test "not empty array": check(?[0])
  test "not empty seq lit": check(?seq1)

  test "some option": check(?some(""))

suite "ternary":
  test "true": check((false ? "a" ! "b") == "b")
  test "false": check((true ? "a" ! "b") == "a")
  test "falsy": check((0 ? "a" ! "b") == "b")
  test "truthy": check((1 ? "a" ! "b") == "a")

suite "conditional assign":
  test "falsy assign":
    var i0 = 0
    i0 ?= 2
    check(i0 == 2)
  test "truthy assign": 
    var i1 = 1
    i1 ?= 2
    check(i1 == 1)
  test "reverse falsy assign":
    var i0 = 1
    i0 =? 0
    check(i0 == 1)
  test "reverse truthy assign": 
    var i1 = 1
    i1 =? 2
    check(i1 == 2)

suite "conditional access":
  var s1 = @["one"]
  var s2 = @["one"]
  test "truthy getter": check(seq1[0].?len == 3) 
  test "falsey getter": check(seq1[1].?len == 0)
  test "truthy precedence": check(seq1[0].?len == 3) 
  test "nil check": check(nilObj.?data == nil)
  test "falsy on ref": check(nilObj.?data.?val == 0)
  test "falsy on ref": check(objNilData.?data.?val == 0)
  test "truthy on ref": check(obj.?data.?val == 10)
  test "truthy chained proc": check(opt1.?get.?len == 3)
  test "falsey chained proc": check(opt0.?get.?len == 0)
  test "no sideeffects": check(s1.?pop == "one")
  test "no sideeffects (chained)": check(s2.?pop.?len == 3)

suite "default coaelsce":
  var s1 = @["one"]
  test "truthy getter": check(?.tab0.getOrDefault("one") == "uno")
  test "falsey getter": check(?.tab0.getOrDefault("two") == "")
  test "multiple args": check(?.tab0.getOrDefault("two", "zero") == "zero")
  test "truthy chained": check(?.tab0.getOrDefault("one").len == 3)
  test "falsey chained": check(?.tab0.getOrDefault("two").len == 0)
  test "no sideeffects": check(s1.?pop.len == 3)

suite "elvis number":
  test "zero left": check((0 ?: 1) == 1)
  test "good left": check((1 ?: 2) == 1)
  test "expr left": check(((1 - 1) ?: 1) == 1)

suite "elvis sequence":
  test "empty left": check((seq0 ?: @[1]) == @[1])
  test "good  left": check((@[0] ?: @[1]) == @[0])

suite "elvis except":
  test "none left": check((tab1["two"] ?: 0) == 0)
  test "good left": check((tab1["one"] ?: 0) == 1)

suite "elvis string": 
  test "empty left": check(("" ?: "empty") == "empty")
  test "uninit left": check((str0 ?: "empty") == "empty")
  test "good  left": check(("good" ?: "empty") == "good")

suite "elvis except":
  test "none left": check((tab1["two"] ?: 0) == 0)
  test "good left": check((tab1["one"] ?: 0) == 1)
  
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
