opam-cross-android
==================

This repository contains an up-to-date Android toolchain featuring OCaml 4.02.3, as well as some commonly used packages. Currently only x86_32/x86_64 Linux build systems and 32-bit targets are supported. If you need support for other build/target combinations, please [open an issue](https://github.com/whitequark/opam-android/issues).

Prerequisites
-------------

On 64-bit Linux build systems, install `gcc-multilib` (on Debian derivatives) or equivalent. Android SDK or NDK are not required.

The compiled toolchain requires about 5G of disk space.

Installation
------------

Add this repository to OPAM:

    opam repository add android git://github.com/whitequark/opam-cross-android

On 64-bit build systems, switch to 32-bit compiler when compiling for 32-bit targets:

    opam switch 4.02.3+32bit
    eval `opam config env`

Otherwise, use a regular compiler; its version must match the version of the cross-compiler:

    opam switch 4.02.3
    eval `opam config env`

Install the compiler:

    ANDROID_LEVEL=21 ANDROID_ARCH=armv7 opam install ocaml-android

The options have the following meaning:

  * `ANDROID_LEVEL` specifies the API level and defaults to latest available API;
  * `ANDROID_SUBARCH` specifies the ARM architecture version, e.g. `armv5te` or `armv7`, and defaults to `armv7`.

Note that you will need to specify `ANDROID_LEVEL` and `ANDROID_ARCH` again if you have to upgrade the compiler via `opam upgrade`; it is a good idea to add it to your environment.

**If you want to change `ANDROID_LEVEL` or `ANDROID_SUBARCH`, you need to reinstall the package ocaml-android32, *not* ocaml-android**.

Build some code:

    echo 'let () = print_endline "Hello, world!"' >helloworld.ml
    ocamlfind -toolchain android ocamlc -custom helloworld.ml -o helloworld.byte
    ocamlfind -toolchain android ocamlopt helloworld.ml -o helloworld.native

Install some packages:

    opam install re-android

Write some code using them:

    let () =
      let regexp = Re_pcre.regexp {|\b([a-z]+)\b|} in
      let result = Re.exec regexp "Hello, world!" in
      Format.printf "match: %s\n" (Re.get result 1)

Build it:

    ocamlfind -toolchain android ocamlopt -package re.pcre -linkpkg test_pcre.ml -o test_pcre

Make an object file out of it and link it with your Android project (you'll need to call `caml_startup(argv)` to run OCaml code; see [this article](http://www.mega-nerd.com/erikd/Blog/CodeHacking/Ocaml/calling_ocaml.html)):

    ocamlfind -toolchain android ocamlopt -package re.pcre -linkpkg -output-obj test_pcre.ml -o test_pcre.o

Make a shared object out of it:

    ocamlfind -toolchain android ocamlopt -package re.pcre -linkpkg -output-obj -cclib -shared test_pcre.ml -o test_pcre.so

With opam-android, cross-compilation is easy!

Porting packages
----------------

OCaml packages often have components that execute at compile-time (camlp4 or ppx syntax extensions, cstubs, OASIS, ...). Thus, it is not possible to just blanketly cross-compile every package in the OPAM repository; sometimes you would even need a cross-compiled and a non-cross-compiled package at once. The package definitions also often need package-specific modification in order to work.

As a result, if you want a package to be cross-compiled, you have to copy the definition from [opam-repository](https://github.com/ocaml/opam-repository), rename the package to add `-android` suffix while updating any dependencies it could have, and update the build script. Don't forget to add `ocaml-android` as a dependency!

Findlib 1.5.4 adds a feature that makes porting packages much simpler; namely, an `OCAMLFIND_TOOLCHAIN` environment variable that is equivalent to the `-toolchain` command-line flag. Now it is not necessary to patch the build systems of the packages to select the Android toolchain; it is often enough to add `["env" "OCAMLFIND_TOOLCHAIN=android" make ...]` to the build command in the `opam` file.

For projects using OASIS, the following steps will work:

    build: [
      ["ocaml" "setup.ml" "-configure" "--prefix" "%{prefix}%/linux-androideabi"]
      ["env" "OCAMLFIND_TOOLCHAIN=android" "ocaml" "setup.ml" "-build"]
      ["env" "OCAMLFIND_TOOLCHAIN=android" "ocaml" "setup.ml" "-install"]
    ]
    remove: [["ocamlfind" "-toolchain" "android" "remove" "pkg"]]
    depends: ["ocaml-android" ...]

For projects installing the files via OPAM's `.install` files (e.g. [topkg](https://github.com/dbuenzli/topkg)), the following steps will work:

    install: [["opam-installer" "--prefix=%{prefix}%/linux-androideabi" "pkg.install"]]
    remove: [["ocamlfind" "-toolchain" "android" "remove" "pkg"]]
    depends: ["ocaml-android" ...]

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

Acknowledgements
----------------

Some of the tricks in this repository were inspired by Jerome Vouillon's [opam-android-repository](https://github.com/vouillon/opam-android-repository). However, no code was reused.
