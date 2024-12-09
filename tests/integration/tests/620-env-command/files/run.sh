#!/usr/bin/env bash

set -euxo pipefail

stack build --resolver lts-23.0 async
eval `stack config env --resolver lts-23.0`
ghc Main.hs
