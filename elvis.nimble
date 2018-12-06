# Package
version       = "0.1.0"
author        = "Mat Taylor"
description   = "truthy, elvis and ternary operators for nim"
license       = "MIT"

# Dependencies
requires "nim >= 0.17.0"

# Tasks
task test, "run tests": exec "nim c -r elvis.nim"
