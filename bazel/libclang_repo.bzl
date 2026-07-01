"""Host libclang shared-library closure for bindgen-driven Rust build scripts.

Any Rust `cargo_build_script` that uses bindgen (via clang-sys) needs a
host-loadable `libclang.so` at build-script *action* time. Build scripts run in
the exec configuration, i.e. natively on the build host — not in the trixie
target sysroot. Trixie's libclang/libLLVM are linked against glibc 2.38 and
can't be loaded on older-glibc build hosts we still support.

This repository rule fetches the LLVM 10 libclang shared library and its
transitive dependency closure from Ubuntu focal (glibc 2.31), which loads on
any reasonably recent host, and flattens every `.so*` into a single directory
that can be handed to clang-sys via LIBCLANG_PATH / LD_LIBRARY_PATH.

Design rationale:
* Standalone repo rule rather than an apt.install on the shared @rules_deb
  extension: adding extra suites to that extension would perturb package
  resolution for every other module using it.
* Uses the OFFICIAL Ubuntu mirror (archive.ubuntu.com) — no internal URLs.
* The glibc family (libc/libm/ld-linux/libpthread/librt/libdl) and
  libstdc++/libgcc_s are deliberately NOT staged; those come from the host
  (newer copies are backward compatible with the LLVM 10 libraries; staging
  mismatched glibc copies would break dlopen).
"""

# Ubuntu focal (20.04) debs from the OFFICIAL Ubuntu archive.
# data.tar.xz so they extract with host `ar` + `tar` (no zstd needed).
_MIRROR = "http://archive.ubuntu.com/ubuntu"

_DEBS = [
    ("pool/universe/l/llvm-toolchain-10/libclang1-10_10.0.0-4ubuntu1_amd64.deb", "d2be849a8e9f126970300d34250ab0bcd42ebca5891cb7e0d812810d6e18db7f"),
    ("pool/main/l/llvm-toolchain-10/libllvm10_10.0.0-4ubuntu1_amd64.deb", "92b4096a0f659f4798cd60f1d5e15117c164e82a548a4e7f3a0f391c8f99b634"),
    ("pool/main/libf/libffi/libffi7_3.3-4_amd64.deb", "4584aa8fef1bf5086168ce2f7078cd2ebd78fdc4cc0d86d958d795d4e0b0f50d"),
    ("pool/main/libe/libedit/libedit2_3.1-20191231-1_amd64.deb", "51a1190157e2dfe2c26bbdc114d1fc659456def2e78e6e9582809cf92a0a49a4"),
    ("pool/main/z/zlib/zlib1g_1.2.11.dfsg-2ubuntu1_amd64.deb", "dbfea100d99ffe17fcb94f62b396c0b27c15aa46e875556126c4f769dc77f1f1"),
    ("pool/main/n/ncurses/libtinfo6_6.2-0ubuntu2_amd64.deb", "87f281a8d5e56dbb259c7ef9f9dead8c52c73982c7bd65b267a71dfc700875fb"),
    ("pool/main/libb/libbsd/libbsd0_0.10.0-1_amd64.deb", "4f668025fe923a372eb7fc368d6769fcfff6809233d48fd20fc072917cd82e60"),
    ("pool/universe/libm/libmd/libmd0_1.0.1-3_amd64.deb", "fe904769ee32a2250a40fce092a92c9ad0baaf34e1ae4a2c90f8c2a3d536a98d"),
    ("pool/universe/z/z3/libz3-4_4.8.7-4build1_amd64.deb", "3f82361ae41eb29f4c09c94f0f7e88f54ddbaf68db94c269571528d889394d94"),
]

_EXCLUDE_PREFIXES = [
    "ld-linux-",
    "libc.so.",
    "libm.so.",
    "libdl.so.",
    "libpthread.so.",
    "librt.so.",
    "libstdc++.so.",
    "libgcc_s.so.",
]

def _libclang_repo_impl(rctx):
    raw = "raw"
    for (i, (path, sha)) in enumerate(_DEBS):
        deb = "deb_{}.deb".format(i)
        rctx.download(url = "{}/{}".format(_MIRROR, path), output = deb, sha256 = sha)

        # .deb is an `ar` archive containing data.tar.xz with the FHS payload.
        res = rctx.execute(["ar", "p", deb, "data.tar.xz"])
        if res.return_code != 0:
            fail("ar failed for {}: {}".format(path, res.stderr))
        rctx.file("data.tar.xz", content = res.stdout, legacy_utf8 = False)
        rctx.extract(archive = "data.tar.xz", output = raw)
        rctx.delete(deb)
        rctx.delete("data.tar.xz")

    # Flatten every .so* (including SONAME symlinks) into lib/, excluding the
    # host-provided glibc / libstdc++ / libgcc_s families.
    rctx.execute(["mkdir", "-p", "lib"])
    script = """
set -e
for f in $(find {raw} \\( -type f -o -type l \\) \\( -name '*.so' -o -name '*.so.*' \\)); do
    b=$(basename "$f")
    skip=0
    for pat in {pats}; do
        case "$b" in $pat*) skip=1 ;; esac
    done
    [ "$skip" = "1" ] && continue
    cp -fL "$f" "lib/$b" 2>/dev/null || true
done
""".format(raw = raw, pats = " ".join([p for p in _EXCLUDE_PREFIXES]))
    res = rctx.execute(["bash", "-c", script])
    if res.return_code != 0:
        fail("flattening libclang closure failed: {}".format(res.stderr))
    rctx.delete(raw)

    rctx.file("BUILD.bazel", content = """\
package(default_visibility = ["//visibility:public"])

# Flattened libclang shared-library closure (LLVM 10, glibc-2.31 era).
filegroup(
    name = "libs",
    srcs = glob(["lib/**"]),
)
""")

libclang_repo = repository_rule(
    implementation = _libclang_repo_impl,
    doc = "Fetch and flatten a host-loadable libclang.so closure for bindgen.",
)
