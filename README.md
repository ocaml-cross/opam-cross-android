opam-cross-android
==================

This repository contains an Android toolchain featuring OCaml `5.4.1`, along
with cross-compiled opam packages to build against it.

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

The [Android NDK][ndk]. This repository is developed and tested against r29.
Older releases are untested.

**macOS**

    brew install --cask android-ndk           # -> /opt/homebrew/share/android-ndk

**Debian / Ubuntu**

    apt search google-android-ndk             # pick the newest r-NN installer
    sudo apt install google-android-ndk-rNN-installer

The package downloads Google's NDK and unpacks it into Debian-friendly paths,
typically `/usr/lib/android-ndk`.

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

Install the compiler:

    opam install ocaml-android

`conf-ndk-android` finds the NDK under the variables the Android tooling
already sets — `ANDROID_NDK_ROOT`, `ANDROID_NDK_HOME`, `ANDROID_NDK_LATEST_HOME`,
`ANDROID_NDK` — and on `PATH`. Point it at one if none of those is set:

    ANDROID_NDK_ROOT=/opt/homebrew/share/android-ndk opam install ocaml-android

`ANDROID_API` selects the API level, the minimum Android version the resulting
binaries run on. It defaults to `26` and should match your app's `minSdk`:

    ANDROID_API=21 opam install ocaml-android

Both are read when `conf-ndk-android` is built, so reinstall that package if you
switch NDKs or API levels. Neither is needed again when upgrading
`ocaml-android`.

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
straggler domains while the main one is terminating. `ocaml-android` patches
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

Cross-compiled C libraries
--------------------------

Some OCaml packages bind a C library, which then has to exist for the target
before they will build. This repository builds those libraries as well as the
OCaml ones, so a cross switch can be assembled from opam alone.

### The sysroot

`build-android-sysroot` declares one location, and everything for the target
lives under it: the cross compiler's own installation, the OCaml libraries built
against it, and the C libraries they bind. `conf-<lib>` packages look there and
`build-<lib>` packages install there.

The location is `$(opam var prefix)/android-sysroot` and is not configurable.
dune picks it for anything cross-installed, and it will not be talked out of it,
so the rest of the repository is aligned to dune's choice rather than the other
way around: the findlib toolchain points there, and packages that do not build
with dune are told to install there.

  * **`build-<lib>`** — builds one library into the sysroot. Optional: install
    it to have this repository build that library, or put your own cross-built
    copy there and leave it out.

  * **`conf-<lib>`** — checks that the library is available for the target.

### Library discovery

A package that depends on a `conf-<lib>-android` builds with
`PKG_CONFIG_LIBDIR`, `LIBRARY_PATH` and `C_INCLUDE_PATH` pointed at the sysroot
and `PKG_CONFIG_PATH` and `CPATH` cleared. The decision, for now, is to override
all of them: without it a build picks up system libraries and assumes they work
for the target.

This goes through `build-env`, on those packages only, so the rest of the switch
is untouched and native work in it behaves normally.

This may need revisiting as the repository grows — a cross-compiled package
whose build needs a host binary linked against a host library would want both
sets of paths at once.

Contributing a package
----------------------

Take the package's opam file from opam-repository and adapt it. The dependency
rewriting applies to any package; the `build` and `install` steps below are for
dune-based ones, which is most of what is here. A package with its own build
system needs its steps adapted to the cross compiler by hand — see
`zarith-android` for one that does.

  * `depends`: `ocaml` becomes `ocaml-android`, and each cross-compiled
    dependency gains an `-android` suffix. Build-time tools — `dune`, `cppo`,
    ppx runners, `opam-installer` — stay native. So do `seq` and `bytes`, which
    the compiler provides and which are shipped here as findlib METAs only.
  * `depopts` and `conflicts` need the same rewriting as `depends`. Missing this
    is silent: an optional dependency that keeps its native name is simply never
    detected.
  * Drop `{with-test}` and `{with-doc}` dependencies.
  * Keep the `url` block unchanged.

For a dune package:

  * `build`/`install`: add `-x android`, and use the package name rather than
    `name` in `-p`.
  * Remove the generated `%{name}%.install` after building.
