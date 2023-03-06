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
  ## Navigates the tree, extracting each step into an expression, adding to `result`
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
  ## Navigates the tree, extracting each step into an expression, returning them
  case n.kind
  of nnkCallKinds:
    if n.len > 1:
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
    else:
      result.add n

  of nnkBracketExpr, nnkDotExpr:
    let cleanCall = n.copyNimTree()
    cleanCall[0] = newEmptyNode()
    result.add cleanCall
    flattenExpression(n[0], result)
  else:
    result.add n

proc replaceCheckedVal(expr, cached: NimNode) =
  ## Navigates the tree replacing the first Node of concern with the `cached` symbol
  if cached != nil:
    case expr.kind
    of nnkBracketExpr:
      expr[0] = cached
    of nnkCallKinds:
      if expr.len > 1:
        case expr[0].kind
        of nnkDotExpr:
          expr[0][0] = cached
        else:
          expr[1] = cached
    else:
      discard

proc generateIfExpr(s: seq[NimNode], l, r: NimNode): NimNode =
  var
    lastArg: NimNode
    lastExpr: NimNode

  for i in countDown(s.high, 0): # iterate the flattened expression backwards as each step is one further left
    let
      expr = s[i]
      argName = gensym(nskLet, "TruthyVar")
    expr.replaceCheckedVal(lastArg)

    let thisExpr =
      genast(expr, argName, r):
        let argName = expr
        if ?argName:
          discard # placerholder rewritten either by next expression or return expression
        else:
          r
    if lastExpr.kind == nnkNilLit:
      result = thisExpr
    else:
      lastExpr[1][0][1] = thisExpr

    lastExpr = thisExpr
    lastArg = argName

  lastExpr[1][0][1] = genAst(l, r, lastArg): # Mimics the logic used prior
    when l isnot Option and r is Option:
      some(lastArg)
    elif l is Option and r isnot Option:
      lastArg.get()
    else:
      lastArg

  result = genast(result, r):
    try:
      # We need to wrap the expression inside a `try` incase an exception is raised.
      # Since we cache the value expressions that raise exceptions do not go right into `?`.
      result
    except CatchableError:
      r

# return left if truthy otherwise right
macro `?:`*(l, r: untyped): untyped =
  if l.kind == nnkInfix and l[0].eqIdent"?:": # We want the left hand evaluated first so make it a stmt list if it's an elvis operator
    result = newStmtList(newCall("?:", newStmtList(l), r))
  else:
    var expr = flattenExpression(l)
    result = expr.generateIfExpr(l, r)

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
  except CatchableError: default(typeof(left.right))

type Branch[T] = object
  then, other: T

# special case for '?' for ternary operations (from Araq https://forum.nim-lang.org/t/3342)
template `?`*[S,T](c: S; p: Branch[T]): T = (if ?c: p.then else: p.other)

# ternary branch selector 
proc `!`*[T](a, b: T): Branch[T] {.inline.} = Branch[T](then: a, other: b)

when isMainModule: import tests
