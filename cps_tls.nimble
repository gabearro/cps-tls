version = "2.0.0"
author = "Gabriel Arroyo"
description = "Async TLS client and server streams for the CPS Nim runtime."
license = "MIT"
srcDir = "src"
skipDirs = @["tests", "examples", "benchmarks", ".github"]

requires "nim >= 2.0.0"
requires "https://github.com/gabearro/cps-runtime == 2.0.0"

task checkDocs, "Verify developer documentation coverage":
  exec "python3 scripts/check_dev_docs.py"

task docs, "Generate the HTML API reference":
  exec "python3 scripts/build_docs.py"

task test, "Run the project test suite":
  exec "nim c -r tests/http/test_fingerprint.nim"

task testMms, "Run TLS under ARC, ORC, and AtomicARC":
  for mm in ["arc", "orc", "atomicArc"]:
    exec "nim c -r --threads:on --mm:" & mm & " tests/http/test_fingerprint.nim"
