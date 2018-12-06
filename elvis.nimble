# Package
version       = "0.1.0"
author        = "Mat Taylor"
description   = "return the first truthy value that exists"
license       = "MIT"

# Dependencies
requires "nim >= 0.17.0"

# Tasks
task test, "run tests": exec "nim c -r elvis.nim"
