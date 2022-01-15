# Package
version       = "0.4.0"
author        = "Mat Taylor"
description   = "truthy, elvis, ternary and conditional assignment, conditional access and coalesce operators for nim"
license       = "MIT"

# Dependencies
requires "nim >= 0.17.0"

# Tasks
task test, "run tests": exec "nim c -r tests.nim"
