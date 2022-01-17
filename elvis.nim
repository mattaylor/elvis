import options

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
