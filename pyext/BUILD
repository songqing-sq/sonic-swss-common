
config_setting(
    name = "x86_64",
    values = {"cpu": "k8"},
)

config_setting(
    name = "aarch64",
    values = {"cpu": "aarch64"},
)

# should move swig to toolchain
genrule(
    name = "swsscommon_wrap_gen",
    srcs = [
        "swsscommon.i",
        "//:swsscommon_hdr_files"
    ],
    outs = [
        "swsscommon_wrap.cpp",
        "swsscommon.py",
    ],
    cmd = "swig -Wall -c++ -python -keyword " + select({
        ":x86_64": "-DSWIGWORDSIZE64 ",
        ":aarch64": "-DSWIGWORDSIZE64 ",
        "//conditions:default": "",
    }) + "-I$$(dirname $$(echo $(locations //:swsscommon_hdr_files) | cut -d' ' -f1)) -o $(@D)/swsscommon_wrap.cpp $(location swsscommon.i)",
    visibility = ["//visibility:public"],
)