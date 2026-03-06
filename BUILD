package(default_visibility = ["//visibility:public"])

load("@rules_cc//cc:cc_binary.bzl", "cc_binary")
load("@rules_cc//cc:cc_library.bzl", "cc_library")
load("@sonic_rules//:shared_library.bzl", "sonic_shared_library", "sonic_shared_library_versioned")
load("@sonic_rules//:sonic_deb.bzl", "sonic_deb")

exports_files(["LICENSE", "common/loglevel.cpp"])

sonic_shared_library_versioned(
    name = "swsscommon",
    srcs = glob(["common/*.cpp"], exclude=["common/loglevel.cpp", "common/loglevel_util.cpp"]),
    hdrs = glob([
                "common/**/*.h"
           ]),
    copts = [
        "-std=c++14",
        "-I/usr/include/libnl3", # Expected location in the SONiC build container"
    ],
    includes = [
        "common",
    ],
    include_prefix = "swss",
    strip_include_prefix = "common",
    linkopts = ["-lpthread -lhiredis -lnl-genl-3 -lnl-nf-3 -lnl-route-3 -lnl-3 -lzmq -lboost_serialization -luuid -lyang"],
    soversion = "0",
    version = "0.0.0",
    visibility = ["//visibility:public"],
)

cc_binary(
    name = "swssloglevel",
    srcs = ["common/loglevel.cpp", "common/loglevel_util.cpp"],
    deps = [":swsscommon_objs"],
)

sonic_shared_library_versioned(
    name = "sonicdbcli",
    srcs = ["sonic-db-cli/sonic-db-cli.cpp", "sonic-db-cli/sonic-db-cli.h"],
    deps = [":swsscommon_objs"],
    dynamic_deps = [":swsscommon"],
    linkopts = ["-lpthread"],
    soversion = "0",
    version = "0.0.0",
)

cc_binary(
    name = "sonic-db-cli",
    srcs = ["sonic-db-cli/main.cpp"],
    deps = [":sonicdbcli_objs", ":swsscommon_objs"],
    dynamic_deps = [":swsscommon"],
    linkopts = ["-lpthread"],
)

filegroup(
    name = "lua_scritps",
    srcs = glob(["common/*.lua"]),
)

sonic_deb(
    name = "libswsscommon_1.0.0_amd64.deb",
    content = {
        "/usr/bin::0755": [":swssloglevel"],
        "/usr/lib/x86_64-linux-gnu" : [":swsscommon_files", ":sonicdbcli_files"],
        "/usr/share/swss:common": [":lua_scritps"],
        "/var/run/redis/sonic-db:common": ["//:common/database_config.json"],
    },
    architecture = "amd64",
    version = "1.0.0",
    package = "libswsscommon",
    maintainer = "songqing.sq@alibaba-inc.com",
    description = "This package contains Switch State Service common library.",
    changelog = "debian/changelog",
    section = "libs",
)

sonic_deb(
    name = "libswsscommon-dev_1.0.0_amd64.deb",
    content = {
        "/usr/include/swss:common": [":swsscommon_hdr_files"],
        "/usr/lib/x86_64-linux-gnu" : [":swsscommon_dev_link"],
    },
    architecture = "amd64",
    version = "1.0.0",
    package = "libswsscommon-dev",
    maintainer = "songqing.sq@alibaba-inc.com",
    description = "This package contains development files for Switch State Service.",
    changelog = "debian/changelog",
    section = "libdevel",
    depends = ["libswsscommon"],
)

sonic_deb(
    name = "sonic-db-cli_1.0.0_amd64.deb",
    content = {
        "/usr/bin::0755": [":sonic-db-cli"],
    },
    architecture = "amd64",
    version = "1.0.0",
    package = "sonic-db-cli",
    maintainer = "songqing.sq@alibaba-inc.com",
    description = "This package contains SONiC DB cli.",
    changelog = "debian/changelog",
    section = "libs",
    depends = ["libswsscommon"],
)

sonic_deb(
    name = "python3-swsscommon_1.0.0_amd64.deb",
    content = {
        "/usr/lib/python3/dist-packages/swsscommon": ["//pyext/py3:__init__.py", "//pyext/py3:_swsscommon_files", "//pyext:swsscommon.py"],
    },
    architecture = "amd64",
    version = "1.0.0",
    package = "python3-swsscommon",
    maintainer = "songqing.sq@alibaba-inc.com",
    description = "This package contains Switch State Service common Python3 library.",
    changelog = "debian/changelog",
    section = "libs",
    depends = ["libswsscommon"],
)

sonic_deb(
    name = "python-swsscommon_1.0.0_amd64.deb",
    content = {
        "/usr/lib/python2.7/dist-packages/swsscommon": ["//pyext/py2:__init__.py", "//pyext/py2:_swsscommon_files", "//pyext:swsscommon.py"],
    },
    architecture = "amd64",
    version = "1.0.0",
    package = "python-swsscommon",
    maintainer = "songqing.sq@alibaba-inc.com",
    description = "This package contains Switch State Service common Python2 library.",
    changelog = "debian/changelog",
    section = "libs",
    depends = ["libswsscommon"],
)
