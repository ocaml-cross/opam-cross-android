opam-android
============

This repository contains an up-to-date Android toolchain featuring OCaml 4.02.1, as well as some commonly used packages. Currently only x86_32/x86_64 Linux build systems and 32-bit targets are supported.

Prerequisites
-------------

On 64-bit Linux build systems, install `gcc-multilib` (on Debian derivatives) or equivalent.

Installation
------------

Add this repository to OPAM:

    opam repository add android git://github.com/whitequark/opam-android

On 64-bit build systems, switch to 32-bit compiler when compiling for 32-bit targets:

    opam switch 4.02.1+32bit
    eval `opam config env`

Otherwise, use a regular compiler; its version must match the version of the cross-compiler:

    opam switch 4.02.1
    eval `opam config env`

Install the compiler:

    opam ocaml-android

Build some code:

    echo 'let () = print_endline "Hello, world!"' >helloworld.ml
    ocamlfind -toolchain android ocamlc -custom helloworld.ml -o helloworld.native
    ocamlfind -toolchain android ocamlopt helloworld.ml -o helloworld.byte

Install some packages:

    opam install re-android

Write some code using them:

    let () =
      let regexp = Re_pcre.regexp {|\b([a-z]+)\b|} in
      let result = Re.exec regexp "Hello, world!" in
      Format.printf "match: %s\n" (Re.get result 1)

Build it:

    ocamlfind -toolchain android ocamlopt -package re.pcre -linkpkg test_pcre.ml -o test_pcre

With opam-android, cross-compilation is easy!

Porting packages
----------------

Findlib 1.5.4 adds a feature that makes porting packages much simpler; namely, an `OCAMLFIND_TOOLCHAIN` environment variable that is equivalent to the `-toolchain` command-line flag. Now it is not necessary to patch the build systems of the packages to select the Android toolchain; it is often enough to add `["env" "OCAMLFIND_TOOLCHAIN=android" make ...]` to the build command in the `opam` file.

For projects using OASIS, the following steps will work:

    build: [
      ["ocaml" "setup.ml" "-configure" "--prefix" "%{prefix}%/linux-androideabi"]
      ["env" "OCAMLFIND_TOOLCHAIN=android" "ocaml" "setup.ml" "-build"]
      ["env" "OCAMLFIND_TOOLCHAIN=android" "ocaml" "setup.ml" "-install"]
    ]
    remove: [["ocamlfind" "-toolchain" "android" "remove" "pkg"]]

The output of the `configure` script will be entirely wrong, referring to the host configuration rather than target configuration. Thankfully, it is not actually used in the build process itself, so it doesn't matter.

Internals
---------

The aim of this repository is to build a cross-compiler while altering the original codebase in the minimal possible way. (Indeed, only about 50 lines are changed.) There are no attempts to alter the `configure` script; rather, the configuration is provided directly. The resulting cross-compiler has several interesting properties:

  * All paths to the Android toolchain are embedded inside `ocamlc` and `ocamlopt`; thus, no knowledge of the Android toolchain is required even for packages that have components in C, provided they use the OCaml driver to compile the C code. (This is usually the case.)
  * The build system makes several assumptions that are not strictly valid while cross-compiling, mainly the fact that the bytecode the cross-compiler has just built can be ran by the `ocamlrun` on the build system. Thus, the requirement for a 32-bit build compiler for 32-bit targets, as well as for the matching versions.
  * The `.opt` versions of the compiler are built using itself, which doesn't work while cross-compiling, so all provided tools are bytecode-based.

License
-------

All files contained in this repository are licensed under the [CC0 1.0 Universal](https://creativecommons.org/publicdomain/zero/1.0/) license.
