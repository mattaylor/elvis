import std / [options, macros]

#true if float not 0 or NaN
template truthy*(val: float): bool  = (val < 0 or val > 0)

#true if int not 0
template truthy*(val: int): bool  = (val != 0)

#try if char not \0
template truthy*(val: char): bool = (val != '\0')

#true if true
template truthy*(val: bool): bool = val

#true if string not empty 
template truthy*(val: string): bool = (val != "")

# true if ref or ptr not isNil

template truthy*(val: ref | ptr | pointer): bool = not val.isNil

# true if seq not empty
template truthy*[T](val: seq[T]): bool = (val != @[])

# true if opt not none
template truthy*[T](val: Option[T]): bool = isSome(val)

# true if truthy and no exception.
template `?`*[T](val: T): bool = (try: truthy(val) except: false)

template truthy*[T](val: T): bool = not compiles(val.isNil())

# return left if truthy otherwise right
template `?:`*[T](l: T, r: T): T = (if ?l: l else: r)

# return some left if truthy otherwise right
template `?:`*[T](l: T, r: Option[T]): Option[T] = (if ?l: some(l) else: r)
 
template `?:`*[T](l: Option[T], r: T): T = (if ?l.get(): l.get() else: r)

# Assign only when left is not truthy
template `?=`*[T](l: T, r: T) = (if not(?l): l = r)

# Assign only when right is truthy
template `=?`*[T](l: T, r: T) = (if ?r: l = r)

# alternate syntax for conditional access to boost operator precendence (https://github.com/mattaylor/elvis/issues/3) 
# conditional access, a macro is required to handle AST rewriting for calls
proc condAccFlatten(args: NimNode): seq[NimNode] =
  # flatten the arguments a.?b.?c produces an Infix tree, this gives us seq
  case args.kind:
  of nnkArgList: 
    result.add condAccFlatten(args[0])
    result.add args[1]
  of nnkInfix:
    assert args[0].eqIdent("?.")
    result.add condAccFlatten(args[1])
    result.add condAccFlatten(args[2])
  else:
    result.add args

proc genExpr(parts: seq[NimNode], index: int): NimNode =
  # produces the DotExpr tree for each nested level
  if index == 0:
    result = parts[0]
  else:
    result = newDotExpr(parts[0], parts[1])

  if index > 1:
    for i in 2..index:
      result = newDotExpr(result, parts[i])

proc genDefault(parts: seq[NimNode], callArgs:seq[NimNode], index: int): NimNode =
  # produces the default value of the full expression
  var expr = parts.genExpr(index)
  if callArgs.len > 0:
    expr = newCall(expr)
    for ca in callArgs:
      expr.add ca
  result = quote do:
    default(typeof(`expr`))

proc genIf(parts: seq[NimNode], defaultVal: NimNode, callArgs: seq[NimNode], index: int): NimNode =
  # generates the nested if expressions for testing each DotExpr for truthy'ness

  var falsyBranch = newTree(nnkElifExpr, 
    newTree(nnkPrefix, ident("not"), 
      newTree(nnkPrefix, ident("?"), 
        parts.genExpr(index))), 
    defaultVal)
  if index == parts.len - 2:
    result = newTree(nnkIfExpr, falsyBranch)
    if callargs.len == 0:
      result.add newTree(nnkElseExpr, parts.genExpr(index + 1))
    else:
      var call = newCall(parts.genExpr(index + 1))
      for ca in callArgs:
        call.add ca
      result.add newTree(nnkElseExpr, call)
  else:
    result = newTree(nnkIfExpr,
      falsyBranch,
      newTree(nnkElseExpr, newTree(nnkPar, genIf(parts, defaultVal, callargs, index+1)))
    )

macro `?.`*(args: varargs[untyped]): untyped =
  var parts = condAccFlatten(args)
  var callArgs: seq[NimNode]
  if parts[^1].kind == nnkCall or parts[^1].kind == nnkCommand:
    let call = parts.pop()
    parts.add call[0]
    for carg in call[1..^1]:
      callArgs.add carg

  let defaultVal = genDefault(parts, callArgs, parts.len - 1)
  result = genIf(parts, defaultVal, callargs, 0)

type Branch[T] = object
  then, other: T

# special case for '?' for ternary operations (from Araq https://forum.nim-lang.org/t/3342)
template `?`*[S,T](c: S; p: Branch[T]): T = (if ?c: p.then else: p.other)

# ternary branch selector 
proc `!`*[T](a, b: T): Branch[T] {.inline.} = Branch[T](then: a, other: b)

when isMainModule: import tests