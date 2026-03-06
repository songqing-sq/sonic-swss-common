
load("@sonic_rules//:shared_library.bzl", "sonic_shared_library", "sonic_shared_library_versioned")
sonic_shared_library_versioned(
    name = "_swsscommon",
    srcs = ["//pyext:swsscommon_wrap.cpp"],
    deps = ["//:swsscommon_objs"],
    dynamic_deps = ["//:swsscommon"],
    cxxopts = [
        "-std=c++11",
        "-I/usr/include/python3.13",
        "-Wno-deprecated-declarations",
    ],
    linkopts = [
        "-lpython3.13",
        "-lhiredis",
    ],
    output_name = "_swsscommon",
    soversion = "0",
    version = "0.0.0",
    visibility = ["//visibility:public"],
)

exports_files(["__init__.py"])