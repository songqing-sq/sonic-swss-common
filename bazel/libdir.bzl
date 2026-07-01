"""libclang_libdir rule: stage libclang closure into one declared directory.

bindgen (run by build.rs via clang-sys) dlopen()s libclang.so at build-script
action time. @sonic_libclang exposes a flat set of host-loadable `.so*` files;
this rule materializes them into a single tree artifact so its `$(execpath ...)`
resolves to one directory path usable as both LIBCLANG_PATH and LD_LIBRARY_PATH.
"""

def _libclang_libdir_impl(ctx):
    out = ctx.actions.declare_directory(ctx.attr.name)
    libs = ctx.files.libs
    ctx.actions.run_shell(
        inputs = libs,
        outputs = [out],
        command = "cp -fL {srcs} {out}/".format(
            srcs = " ".join([f.path for f in libs]),
            out = out.path,
        ),
        mnemonic = "StageLibclang",
        progress_message = "Staging libclang shared-library closure",
    )
    return [DefaultInfo(files = depset([out]))]

libclang_libdir = rule(
    implementation = _libclang_libdir_impl,
    attrs = {
        "libs": attr.label(
            allow_files = True,
            mandatory = True,
            doc = "Filegroup of flattened libclang .so* files to stage in one dir.",
        ),
    },
)
