# Package

version       = "0.1.0"
author        = "Carlo Capocasa"
description   = "Super simple URL shortener"
license       = "MIT"
srcDir        = "src"
bin           = @["nimshort"]

# Dependencies

requires "nim >= 2.0.0"
requires "limdb"
requires "httpbeast#master"
requires "libsha"


