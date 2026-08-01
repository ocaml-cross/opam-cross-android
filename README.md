opam-cross-android
==================

This repository contains an Android toolchain featuring OCaml `5.4.1`, as well
as the packages needed to cross-compile a substantial Lwt/cohttp application.

The target is 64-bit ARM Android (`aarch64-linux-android`).

Whether a machine can build for it comes down to three things:

  * **A native OCaml of the same version.** Cross-compiling is not
    self-contained — the compiler builds its own tools with the host compiler,
    and dune, cppo and every ppx rewriter run natively throughout.

  * **An NDK for that host.** Google publishes prebuilt toolchains for a limited
    set of host architectures; see [the NDK downloads][ndk-dl] for the current
    set. There is no supported way to target Android without one.

  * **A POSIX shell.** The packages here are shell scripts, and so are the NDK's
    own per-API compiler drivers, so the compiler cannot be invoked without one.

macOS and `x86_64` Linux satisfy all three.

Prerequisites
-------------

The [Android NDK][ndk], r23 or later. Everything from r23 on is Clang plus LLVM
binutils, with no GCC and no standalone-toolchain step; earlier releases will
not work.

**macOS**

    brew install --cask android-ndk           # -> /opt/homebrew/share/android-ndk

**Debian / Ubuntu**

    apt search google-android-ndk             # pick the newest r-NN installer
    sudo apt install google-android-ndk-rNN-installer

The package downloads Google's NDK and unpacks it into Debian-friendly paths,
typically `/usr/lib/android-ndk`. The packaged release lags upstream, which is
fine as long as it is r23 or later.

**Fedora, or any distribution without a package**

There is no NDK package in Fedora. Take it from Google directly — either the
[zip][ndk-dl], unpacked wherever you like, or through the SDK manager:

    sudo dnf install java-21-openjdk-headless
    # unpack android-commandlinetools, then:
    sdkmanager --list | grep ndk       # then install a recent one
    sdkmanager --install "ndk;<version>"

[ndk]: https://developer.android.com/ndk
[ndk-dl]: https://developer.android.com/ndk/downloads

Installation
------------

Add this repository to opam:

    opam repository add android https://github.com/ocaml-cross/opam-cross-android.git

The version of the regular compiler installed in your current opam switch must
match the version of the cross-compiler:

    opam switch 5.4.1
    eval $(opam env)

Install the compiler, pointing `TOOLPREF64` at the NDK. The prebuilt directory
is named after the build machine — `darwin-x86_64` on macOS, `linux-x86_64` on
Linux — so let the shell find it rather than hardcoding either:

    export ANDROID_NDK_HOME=/opt/homebrew/share/android-ndk   # or /usr/lib/android-ndk, ...
    NDK_BIN=$(echo "$ANDROID_NDK_HOME"/toolchains/llvm/prebuilt/*/bin)

    TOOLPREF64=$NDK_BIN/aarch64-linux-android26- opam install ocaml-android64

The API level embedded in that prefix is the minimum Android version the
resulting binaries will run on, and it should match your app's `minSdk`.

`TOOLPREF64` is recorded inside `conf-ndk-android`, so reinstall that package if
you switch NDKs. It is not needed again when upgrading `ocaml-android64`.

Usage
-----

    dune build -x android _build/default.android/bin/your.exe

Naming the artifact rather than the target keeps dune to the cross context. A
bare `dune build -x android` builds the native context as well, which will want
the host libraries that a cross build has just been told to ignore.

The findlib toolchain is named `android`:

    ocamlfind -toolchain android ocamlopt -config

Notes on the target
-------------------

**Bionic has no `pthread_cancel`.** OCaml's runtime calls it once, to cancel
straggler domains while the main one is terminating. `ocaml-android64` patches
that call out and leaves the domain marked as cancelled, which is what stops the
teardown loop from freeing a lock the thread may still hold. The consequence is
narrow: a program that leaves extra domains running at `caml_shutdown` will not
force them to stop. `pthread_cancel` is best-effort even where it exists —
deferred cancellation only acts at cancellation points — so this is a difference
of degree. It matters most to embedders that call `caml_shutdown` and keep
running.

**`--disable-function-sections`.** configure enables it for an ELF target, but
the build machine compiles its own tools with the target's flags, and a macOS
`ocamlopt` reports `function_sections: false` — so a macOS host fails with
"OCaml has been configured without support for -function-sections". It is
disabled unconditionally rather than per-host, which costs a Linux host nothing
but `--gc-sections` dead-code trimming and keeps one build recipe.

**GMP is built from source** by `build-gmp-android`, since zarith needs it for
the target. It is static but position-independent: Android binaries are all PIE,
and zarith links its stubs into a `.cmxs`, which will not link against a non-PIC
archive.

**Host library discovery is cut off, not merely deprioritised.** Every package
here builds with `PKG_CONFIG_LIBDIR` pointed at the sysroot, `LIBRARY_PATH` and
`C_INCLUDE_PATH` likewise, and `PKG_CONFIG_PATH` and `CPATH` emptied.

A configurator that reaches for the ambient environment otherwise describes the
build machine while claiming to describe the target — and pkg-config is only
part of it. lwt's libev probe reads `LIBRARY_PATH`, takes its parent directory
and tests for `include/ev.h`, so a host libev is found with no `.pc` file
involved anywhere. Setting only `PKG_CONFIG_LIBDIR` would leave that untouched.

Cross-compiled C libraries
--------------------------

Some OCaml packages bind a C library, which then has to exist for the target
before they will build — zarith needs GMP, for instance. This repository builds
those libraries as well as the OCaml ones, so a cross switch can be assembled
from opam alone.

### The sysroot

`build-android-sysroot` declares one location, and everything for the target
lives under it: the cross compiler's own installation, the OCaml libraries built
against it, and the C libraries they bind. `conf-<lib>` packages look there and
`build-<lib>` packages install there.

The location is `$(opam var prefix)/android-sysroot` and is not configurable.
`dune install -x android` writes there by its own convention, ignoring findlib's
destdir, so that is where the sysroot has to be for OCaml packages and C
libraries to land in the same tree.

  * **`build-<lib>`** — builds one library into the sysroot. Optional: install
    it to have this repository build that library, or put your own cross-built
    copy there and leave it out.

  * **`conf-<lib>`** — detection only, mirroring the native `conf-<lib>`
    packages. It compiles *and links* a test program with the cross compiler and
    exports `cflags`, `libs`, `includedir` and `libdir` for dependents. Linking
    matters: the build machine has headers for libraries the target does not
    have, so a successful `#include` proves nothing, and only the link catches a
    host archive.

### A switch with this toolchain is a cross switch

`build-android-sysroot` sets `PKG_CONFIG_LIBDIR`, `LIBRARY_PATH` and
`C_INCLUDE_PATH` to the sysroot, and clears `PKG_CONFIG_PATH` and `CPATH`,
through `setenv`. Every cross build needs library discovery confined this way,
so it is declared once rather than repeated in each package.

`PKG_CONFIG_LIBDIR` replaces pkg-config's search path where `PKG_CONFIG_PATH`
would only prepend to it. The other two are not pkg-config's business at all and
matter just as much: lwt's libev probe reads `LIBRARY_PATH`, takes its parent
directory and tests for `include/ev.h`, so a host libev is found with no `.pc`
file involved anywhere.

opam exports `setenv` through `opam env`, which is what covers a project built
against this toolchain — and everything else in the switch with it. **Native
builds in the same switch will not find host C libraries.** Use a switch for
cross-compiling and another for native work; they are cheap.

Contributing a package
----------------------

Take the package's opam file from opam-repository and adapt it:

  * `build`/`install`: add `-x android`, and use the package name rather than
    `name` in `-p`.
  * Remove the generated `%{name}%.install` after building.
  * `depends`: `ocaml` becomes `ocaml-android`, and each cross-compiled
    dependency gains an `-android` suffix. Build-time tools — `dune`, `cppo`,
    ppx runners, `opam-installer` — stay native. So do `seq` and `bytes`, which
    the compiler provides and which are shipped here as findlib METAs only.
  * `depopts` and `conflicts` need the same rewriting as `depends`. Missing this
    is silent: an optional dependency that keeps its native name is simply never
    detected.
  * Drop `{with-test}` and `{with-doc}` dependencies.
  * Keep the `url` block unchanged.
