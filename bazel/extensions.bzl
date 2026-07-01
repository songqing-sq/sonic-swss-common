"""Module extension exposing the host libclang closure repository.

The generated @swss_common_libclang repo provides a flat directory of
libclang.so + its transitive .so dependencies, used by the swss-common Rust
crate's `cargo_build_script` (which runs bindgen; clang-sys dlopen()s
libclang at action time).

This extension lives inside sonic-swss-common because the swss-common Rust
crate is currently the only bindgen consumer in this project. If more Rust
modules that need bindgen appear later, this can be lifted into sonic_rules
(the platform layer) so the closure is shared.

Usage from a downstream module's MODULE.bazel:

    libclang = use_extension("@sonic-swss-common//bazel:extensions.bzl", "libclang")
    use_repo(libclang, "swss_common_libclang")

Then in a BUILD.bazel:

    load("@sonic-swss-common//bazel:libdir.bzl", "libclang_libdir")

    libclang_libdir(name = "libclang_libs", libs = "@swss_common_libclang//:libs")

    cargo_build_script(
        ...
        build_script_env = {
            "LIBCLANG_PATH": "$(execpath :libclang_libs)",
            "LD_LIBRARY_PATH": "$(execpath :libclang_libs)",
        },
        data = [":libclang_libs", ...],
    )
"""

load(":libclang_repo.bzl", "libclang_repo")

def _libclang_ext_impl(_mctx):
    libclang_repo(name = "swss_common_libclang")

libclang = module_extension(implementation = _libclang_ext_impl)
