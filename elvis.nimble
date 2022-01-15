# Package
version       = "0.3.0"
author        = "Mat Taylor"
description   = "truthy, elvis, ternary and conditional assignment operators for nim"
license       = "MIT"

# Dependencies
requires "nim >= 0.17.0"

# Tasks
task test, "run tests": exec "nim c -r tests.nim"
