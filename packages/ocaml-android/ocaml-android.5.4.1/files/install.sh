#!/bin/sh

set -e

PREFIX="$1"
HOST="$2"

for bin in ocamlc ocamlopt ocamlmklib ocamlmktop ocamldoc ocamldep; do
  ln -sf "${PREFIX}/android-sysroot/bin/${bin}" "${PREFIX}/bin/${HOST}-${bin}"
done
