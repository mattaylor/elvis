import std/[options, macros, genasts]

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
template `?`*[T](val: T): bool = (try: truthy(val) except CatchableError: false)

template truthy*[T](val: T): bool = not compiles(val.isNil())


proc flattenExpression(n: NimNode, result: var seq[NimNode]) =
  case n.kind
  of nnkCallKinds:
    let cleanCall = n.copyNimTree()
    case cleanCall[0].kind:
    of nnkDotExpr:
      cleanCall[0][0] = newEmptyNode()
      result.add cleanCall
      flattenExpression(n[0][0], result)
    else:
      cleanCall[1] = newEmptyNode()
      result.add cleanCall
      flattenExpression(n[1], result)

  of nnkBracketExpr, nnkDotExpr:
    let cleanCall = n.copyNimTree()
    cleanCall[0] = newEmptyNode()
    result.add cleanCall
    flattenExpression(n[0], result)

  else:
    result.add n

proc flattenExpression(n: NimNode): seq[NimNode] =
  case n.kind
  of nnkCallKinds:
    let cleanCall = n.copyNimTree()
    case cleanCall[0].kind:
    of nnkDotExpr:
      cleanCall[0][0] = newEmptyNode()
      result.add cleanCall
      flattenExpression(n[0][0], result)
    else:
      cleanCall[1] = newEmptyNode()
      result.add cleanCall
      flattenExpression(n[1], result)

  of nnkBracketExpr, nnkDotExpr:
    let cleanCall = n.copyNimTree()
    cleanCall[0] = newEmptyNode()
    result.add cleanCall
    flattenExpression(n[0], result)
  else:
    result.add n

proc replaceCheckedVal(expr, cached: NimNode) =
  if cached != nil:
    case expr.kind
    of nnkBracketExpr:
      expr[0] = cached
    of nnkCallKinds:
      case expr[0].kind
      of nnkDotExpr:
        expr[0][0] = cached
      else:
        expr[1] = cached
    else:
      discard

proc generateIfCond(s: seq[NimNode]): (NimNode, NimNode) =
  # Generates the if condition and retuns the name of the last variable used
  for i in countDown(s.high, 0):
    let
      expr = s[i]
      argName = gensym(nskLet, "TruthyVar")

    expr.replaceCheckedVal(result[1])

    if result[0].kind == nnkNilLit:
      result[0] =
        genast(argName, expr):
          truthy((let argName = expr; argName))
    else:
      result[0] =
        genast(result = result[0], argName, expr):
          result and truthy((let argName = expr; argName))
    result[1] = argName

# return left if truthy otherwise right
macro `?:`*(l, r: untyped): untyped =
  result = nnkIfStmt.newTree()
  var expr = flattenExpression(l)
  let (cond, lastSym) = expr.generateIfCond()
  result = genast(l, r, cond, lastSym, opt = bindSym"Option"):
    if cond:
      when r is opt:
        some(lastSym)
      when lastSym is opt and r isnot opt:
        lastSym.get()
      else:
        lastSym
    else:
      r
  echo result.repr

# Assign only when left is not truthy
template `?=`*[T](l: T, r: T) = (if not(?l): l = r)

# Assign only when right is truthy
template `=?`*[T](l: T, r: T) = (if ?r: l = r)

# Return right if truthy otherwise default
template `?.`*[T](right: T):T =
  if ?right: right else: default(typeof(right))

# Access right from left only if truthy otherwise default
template `.?`*(left, right: untyped): untyped =
  try:
    var tmp = left
    if truthy(tmp): tmp.right
    else: default(typeof(left.right))
  except: default(typeof(left.right))

type Branch[T] = object
  then, other: T

# special case for '?' for ternary operations (from Araq https://forum.nim-lang.org/t/3342)
template `?`*[S,T](c: S; p: Branch[T]): T = (if ?c: p.then else: p.other)

# ternary branch selector 
proc `!`*[T](a, b: T): Branch[T] {.inline.} = Branch[T](then: a, other: b)

when isMainModule: import tests
