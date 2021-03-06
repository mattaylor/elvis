import options

#true if not 0 or NaN
template truthy*(val: float): bool  = (val < 0 or val > 0)

#true if not 0
template truthy*(val: int): bool  = (val != 0)

#try if not \0
template truthy*(val: char): bool = (val != '\0')

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

# return left if truthy otherwise right
template `?:`*[T](l: T, r: T): T = (if ?l: l else: r)

# return some left if truthy otherwise right
template `?:`*[T](l: T, r: Option[T]): Option[T] = (if ?l: some(l) else: r)
 
template `?:`*[T](l: Option[T], r: T): T = (if ?l.get(): l.get() else: r)

# Conditional Assignment
template `?=`*[T](l: T, r: T) = (if not(?l): l = r)

# Conditional Assignment (Reverse)
template `=?`*[T](l: T, r: T) = (if ?r: l = r)

#Conditional access (WIP)
template `?.`*[T,U](left: T, right: proc (x: T): U):U =
  if ?left: right(left) 
  else:
    var res: U
    res

type Branch[T] = object
  then, other: T

# special case for '?' for ternary operations (from Araq https://forum.nim-lang.org/t/3342)
template `?`*[S,T](c: S; p: Branch[T]): T = (if ?c: p.then else: p.other)

# ternary branch selector 
proc `!`*[T](a, b: T): Branch[T] {.inline.} = Branch[T](then: a, other: b)

when isMainModule: import tests
