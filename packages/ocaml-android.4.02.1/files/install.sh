#!/bin/sh -e

PREFIX="$1"

for bin in ocaml ocamlbuild ocamlbuild.byte ocamlc ocamlcp ocamldebug ocamldep ocamldoc ocamllex ocamlmklib ocamlmktop ocamlobjinfo ocamlopt ocamloptp ocamlprof ocamlrun ocamlyacc; do
  path="${PREFIX}/arm-linux-androideabi/bin/${bin}"
  if [ -e "${path}" ] && [ "$(head -c 1 ${path})" = "/" ]; then
    echo -n '#!' | cat - "${path}" >"${path}.n"
    mv "${path}.n" "${path}"
    chmod +x "${path}"
  fi
done

for pkg in bigarray bytes compiler-libs dynlink findlib graphics num num-top ocamlbuild stdlib str threads unix; do
  cp -r "${PREFIX}/lib/${pkg}" "${PREFIX}/arm-linux-androideabi/lib/"
done

mkdir -p "${PREFIX}/lib/findlib.conf.d"
cp android.conf "${PREFIX}/lib/findlib.conf.d"
