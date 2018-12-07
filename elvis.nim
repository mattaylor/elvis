import options

type BranchPair[T] = object
  then, other: T


#true if not 0 or NaN
template truthy*(val: float): bool  = (val < 0 or val > 0)

#true if not 0
template truthy*(val: int): bool  = (val != 0)

#try if not \0
template truthy*(val: char): bool = val != '\0'

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

# Conditional Assignment
template `?=`*[T](left: T, right: T) = 
  if not(?left): left = right
  
#Conditional acess (WIP)
#[
template `?.`*[T,U,V](left: T, right: proc (x: T,y: U): V): V =
  if ?left: right(left) else: (var r:V)

template `?.`*[T,U](left: T, right: U): U =
  if ?left: left.right else: (var r:U)
]#

# from Arak https://forum.nim-lang.org/t/3342
template `?`*[S,T](cond: S; p: BranchPair[T]): T = (if ?cond: p.then else: p.other)

proc `!`*[T](a, b: T): BranchPair[T] {.inline.} = BranchPair[T](then: a, other: b)

when isMainModule: import tests
