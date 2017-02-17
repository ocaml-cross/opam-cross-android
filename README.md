opam-cross-android
==================

This repository contains an up-to-date Android toolchain featuring OCaml 4.04.0, as well as some commonly used packages.

The supported build systems are 32-bit and 64-bit x86 Linux. The supported target systems are 32-bit x86 and ARM Android.

If you need support for other platforms or versions, please [open an issue](https://github.com/whitequark/opam-cross-android/issues).

Prerequisites
-------------

On 64-bit Linux build systems, 32-bit libraries must be installed. On Debian derivatives they are provided in the `gcc-multilib` package.

The compiled toolchain requires about 5G of disk space.

Installation
------------

Add this repository to OPAM:

    opam repository add android git://github.com/whitequark/opam-cross-android

On 64-bit build systems, switch to 32-bit compiler when compiling for 32-bit targets:

    opam switch 4.04.0+32bit
    eval `opam config env`

Otherwise, use a regular compiler; its version must match the version of the cross-compiler:

    opam switch 4.04.0
    eval `opam config env`

Pin some prerequisite packages that don't yet have fixes merged upstream:

    opam pin add ocamlbuild https://github.com/ocaml/ocamlbuild.git
    opam pin add topkg https://github.com/whitequark/topkg.git

Configure the compiler for ARM:

    ARCH=arm SUBARCH=armv7 SYSTEM=linux_eabi \
      CCARCH=arm TOOLCHAIN=arm-linux-androideabi-4.9 \
      TRIPLE=arm-linux-androideabi LEVEL=24 \
      STLVER=4.9 STLARCH=armeabi \
      opam install conf-android

Alternatively, configure the compiler for AArch64:

    ARCH=arm64 SUBARCH=arm64 SYSTEM=linux_eabi \
      CCARCH=arm64 TOOLCHAIN=aarch64-linux-android-4.9 \
      TRIPLE=aarch64-linux-android LEVEL=24 \
      STLVER=4.9 STLARCH=arm64-v8a \
      opam install conf-android

Alternatively, configure the compiler for x86:

    ARCH=i386 SUBARCH=default SYSTEM=linux_elf \
      CCARCH=x86 TOOLCHAIN=x86-4.9 \
      TRIPLE=i686-linux-android LEVEL=24 \
      STLVER=4.9 STLARCH=x86 \
      opam install conf-android

Some options can be tweaked:

  * `SUBARCH` (on ARM) specifies the ARM architecture version, e.g. `armv5te` or `armv7`;
  * `SYSTEM` (on ARM) specifies the ABI: `linux_eabi` for soft-float and `linux_eabihf` for hard-float;
  * `LEVEL` specifies the Android API level and defaults to latest available API.

The options above (`ARCH`, `SUBARCH`, `SYSTEM`, `LEVEL`, `TOOLCHAIN` and `TRIPLE`) are recorded inside the `conf-android` package, so make sure to reinstall that package if you wish to switch to a different toolchain. Otherwise, it is not necessary to supply them while upgrading the `ocaml-android*` packages.

If desired, request the compiler to be built with [flambda][] optimizers:

    opam install conf-flambda-android

[flambda]: https://caml.inria.fr/pub/docs/manual-ocaml/flambda.html

Install the compiler:

    opam install ocaml-android

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

    ocamlfind -toolchain android ocamlopt -package re.pcre -linkpkg -output-complete-obj test_pcre.ml -o test_pcre.o

Make a shared object out of it:

    ocamlfind -toolchain android ocamlopt -package re.pcre -linkpkg -output-obj -cclib -shared test_pcre.ml -o test_pcre.so

With opam-android, cross-compilation is easy!

Porting packages
----------------

OCaml components execute at compile-time (camlp4 or ppx syntax extensions, cstubs, OASIS, ...). You cannot blanketly cross-compile every package in the OPAM repository, in case you need a cross-compiled and a non-cross-compiled package at the same time. The package definitions also need modification specific to the package.

For a package to be cross-compiled, you need to do the following: copy the definition from [opam-repository](https://github.com/ocaml/opam-repository) , rename the package to add `-android` suffix while updating necessary dependencies, update the build script and add `ocaml-android` as a dependency!

Findlib 1.5.4 adds a feature that makes porting packages much simpler, namely, an `OCAMLFIND_TOOLCHAIN` environment variable equivalent to the `-toolchain` command-line flag. It is not necessary to patch the build systems of the packages to select the Android toolchain. It is enough to add `["env" "OCAMLFIND_TOOLCHAIN=android" make ...]` to the build command in the `opam` file.

For projects using OASIS, the following steps will work:

    build: [
      ["ocaml" "setup.ml" "-configure" "--prefix" "%{prefix}%/android-sysroot"]
      ["env" "OCAMLFIND_TOOLCHAIN=android" "ocaml" "setup.ml" "-build"]
    ]
    install: [
      ["env" "OCAMLFIND_TOOLCHAIN=android" "ocaml" "setup.ml" "-install"]
    ]
    remove: [["ocamlfind" "-toolchain" "android" "remove" "pkg"]]
    depends: ["ocaml-android" ...]

The output of the `configure` script will be entirely wrong, referring to the host configuration rather than target configuration. Thankfully, it is not actually used in the build process itself, so it doesn't matter.

For projects installing the files via OPAM's `.install` files (e.g. [topkg](https://github.com/dbuenzli/topkg)), the following steps will work:

    build: [["ocaml" "pkg/pkg.ml" "build" "--pinned" "%{pinned}%" "--toolchain" "windows" ]]
    install: [["opam-installer" "--prefix=%{prefix}%/android-sysroot" "pkg.install"]]
    remove: [["ocamlfind" "-toolchain" "android" "remove" "pkg"]]
    depends: ["ocaml-android" ...]

Internals
---------

The aim of this repository is to build a cross-compiler while altering the original codebase in the minimal possible way. (Indeed, only about 50 lines are changed.) You do not need to alter the `configure` script; rather, the configuration is provided directly. The resulting cross-compiler has several interesting properties:

  * All paths to the Android toolchain are embedded inside `ocamlc` and `ocamlopt`; thus, no knowledge of the Android toolchain is required even for packages that have components in C, provided they use the OCaml driver to compile the C code. (This is usually the case.)
  * The build system makes several assumptions that are not strictly valid while cross-compiling, mainly the fact that the bytecode the cross-compiler has just built can be ran by the `ocamlrun` on the build system. Thus, the requirement for a 32-bit build compiler for 32-bit targets, as well as for the matching versions.
  * The `.opt` versions of the compiler are built using itself, which doesn't work while cross-compiling, so all provided tools are bytecode-based.

License
-------

All files contained in this repository are licensed under the [CC0 1.0 Universal](https://creativecommons.org/publicdomain/zero/1.0/) license.

Acknowledgements
----------------

Some of the tricks in this repository were inspired by Jerome Vouillon's [opam-android-repository](https://github.com/vouillon/opam-android-repository). However, no code was reused.

References
----------

See also [opam-cross-windows](https://github.com/whitequark/opam-cross-windows) and [opam-cross-ios](https://github.com/whitequark/opam-cross-ios).
