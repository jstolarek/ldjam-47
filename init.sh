#!/bin/bash

git submodule init
git submodule update

haxelib newrepo

# dependencies
haxelib install assertion 1.0.0
haxelib install format    3.5.0
haxelib install hashlink  # for native Linux builds
haxelib install hexlog    1.0.0-alpha.7
haxelib install hlsdl     1.10.0
haxelib install utest     1.13.1
haxelib install ogmo-3    1.0.2

# upstream versions of libraries
haxelib dev heaps heaps/

# setup git hooks
if [[ ! -e .git/hooks/pre-commit ]]; then
    cp .githooks/pre-commit .git/hooks/pre-commit
    chmod +x .githooks/pre-commit
else
    echo "Pre-commit hook already exists (.git/hooks/pre-commit)"
fi
