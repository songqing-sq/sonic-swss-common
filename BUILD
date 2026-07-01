load("@bazel_skylib//rules:common_settings.bzl", "bool_flag")
load("@rules_cc//cc:cc_binary.bzl", "cc_binary")
load("@rules_cc//cc:cc_library.bzl", "cc_library")
load("@rules_cc//cc:cc_shared_library.bzl", "cc_shared_library")
load("@rules_python//python:py_binary.bzl", "py_binary")
load("@sonic_build_infra//shared_library:shared_library.bzl", "sonic_shared_library_versioned")
load("@sonic_build_infra//sonic_deb:sonic_deb.bzl", "sonic_deb")
load("@sonic_build_infra//swig:gen.bzl", "swig_gen")

package(default_visibility = ["//visibility:public"])

# Export the Cargo workspace manifest so sibling modules that consume the
# swss-common Rust crate as a path-dep (e.g. sonic-supervisord-utilities-rs)
# can reference it from their crate.from_cargo manifests list.
exports_files(["Cargo.toml", "Cargo.lock"])

# YANG-driven decorator tables. Build with `--//src/sonic-swss-common:enable_yangmodules=False`
# to drop the 3 yang-dependent .cpp files; default keeps them.
bool_flag(
    name = "enable_yangmodules",
    build_setting_default = True,
)

config_setting(
    name = "yangmodules_enabled",
    flag_values = {":enable_yangmodules": "True"},
)

# =============================================================================
# cfg_schema.h: scan SONiC YANG models and emit `#define CFG_<TABLE>_TABLE_NAME`
# for each CONFIG_DB table.
#
# Make's common/Makefile.am uses gen_cfg_schema.py which needs sonic_yang +
# libyang + sonic-yang-models installed on the host at build time. We instead
# parse the yang text directly — see tools/cfg_schema_gen.py for the regex
# pattern and rationale. Output is byte-equivalent to gen_cfg_schema.py for
# every yang file that follows SONiC's YANG model guidelines (top-level
# container name == module name).
# =============================================================================
genrule(
    name = "cfg_schema_h_gen",
    srcs = ["@sonic-yang-models//:yang_models_files"],
    outs = ["common/cfg_schema.h"],
    cmd = """
set -e
# Yang sources come from two parent directories (4 jinja-rendered files live
# under bazel-out/.../gen/yang-models/, the rest under external/.../yang-models/).
# Stage them all into a single scratch dir so cfg_schema_gen can scan one dir.
stage=$$(mktemp -d)
for f in $(SRCS); do
    cp "$$f" "$$stage/"
done
$(execpath :cfg_schema_gen) --yang-dir "$$stage" --out $@
rm -rf "$$stage"
""",
    tools = [":cfg_schema_gen"],
)

py_binary(
    name = "cfg_schema_gen",
    srcs = ["tools/cfg_schema_gen.py"],
    main = "tools/cfg_schema_gen.py",
    visibility = ["//visibility:private"],
)

# =============================================================================
# libswsscommon — main C++ shared library.
# Source list mirrors common/Makefile.am's common_libswsscommon_la_SOURCES.
# autotools default libtool version is 0:0:0 → libswsscommon.so.0.0.0 (soname
# libswsscommon.so.0).
# =============================================================================
SWSSCOMMON_BASE_SRCS = [
    "common/asyncdbupdater.cpp",
    "common/configdb.cpp",
    "common/consumerstatetable.cpp",
    "common/consumertable.cpp",
    "common/consumertablebase.cpp",
    "common/countertable.cpp",
    "common/dbconnector.cpp",
    "common/dbinterface.cpp",
    "common/events.cpp",
    "common/events_common.cpp",
    "common/events_service.cpp",
    "common/exec.cpp",
    "common/ipaddress.cpp",
    "common/ipaddresses.cpp",
    "common/ipprefix.cpp",
    "common/json.cpp",
    "common/linkcache.cpp",
    "common/logger.cpp",
    "common/luatable.cpp",
    "common/macaddress.cpp",
    "common/netdispatcher.cpp",
    "common/netlink.cpp",
    "common/netmsg.cpp",
    "common/nfnetlink.cpp",
    "common/notificationconsumer.cpp",
    "common/notificationproducer.cpp",
    "common/performancetimer.cpp",
    "common/portmap.cpp",
    "common/producerstatetable.cpp",
    "common/producertable.cpp",
    "common/profileprovider.cpp",
    "common/pubsub.cpp",
    "common/redis_table_waiter.cpp",
    "common/rediscommand.cpp",
    "common/redisreply.cpp",
    "common/redisselect.cpp",
    "common/redistran.cpp",
    "common/redisutility.cpp",
    "common/restart_waiter.cpp",
    "common/saiaclschema.cpp",
    "common/select.cpp",
    "common/selectableevent.cpp",
    "common/selectabletimer.cpp",
    "common/sonicv2connector.cpp",
    "common/subscriberstatetable.cpp",
    "common/table.cpp",
    "common/timestamp.cpp",
    "common/tokenize.cpp",
    "common/warm_restart.cpp",
    "common/zmqclient.cpp",
    "common/zmqconsumerstatetable.cpp",
    "common/zmqproducerstatetable.cpp",
    "common/zmqserver.cpp",
    "common/c-api/configdbconnector.cpp",
    "common/c-api/consumerstatetable.cpp",
    "common/c-api/dbconnector.cpp",
    "common/c-api/events.cpp",
    "common/c-api/logger.cpp",
    "common/c-api/producerstatetable.cpp",
    "common/c-api/sonicv2connector.cpp",
    "common/c-api/subscriberstatetable.cpp",
    "common/c-api/table.cpp",
    "common/c-api/util.cpp",
    "common/c-api/zmqclient.cpp",
    "common/c-api/zmqconsumerstatetable.cpp",
    "common/c-api/zmqproducerstatetable.cpp",
    "common/c-api/zmqserver.cpp",
]

SWSSCOMMON_YANGMODS_SRCS = [
    "common/decoratorsubscriberstatetable.cpp",
    "common/decoratortable.cpp",
    "common/defaultvalueprovider.cpp",
]

sonic_shared_library_versioned(
    name = "swsscommon",
    srcs = SWSSCOMMON_BASE_SRCS + select({
        ":yangmodules_enabled": SWSSCOMMON_YANGMODS_SRCS,
        "//conditions:default": [],
    }),
    hdrs = glob(["common/**/*.h"]) + [":cfg_schema_h_gen"],
    include_prefix = "swss",
    strip_include_prefix = "common",
    includes = ["common"],
    copts = [
        "-std=c++17",
        "-Wall",
        "-Wno-unused-parameter",
        "-Wno-unused-variable",
        "-Wno-deprecated-declarations",
    ],
    linkopts = [
        "-Wl,-z,now",
        "-lpthread",
    ],
    dynamic_deps = [
        "@libnl3//:libnl_3_shared",
        "@libnl3//:libnl_nf_3_shared",
        "@libnl3//:libnl_route_3_shared",
    ] + select({
        ":yangmodules_enabled": ["@libyang3//:yang_shared"],
        "//conditions:default": [],
    }),
    deps = [
        "@libnl3//:libnl_3",
        "@swss_deps//libboost-serialization1.83-dev:boost_serialization",
        "@swss_deps//libhiredis-dev:libhiredis",
        "@swss_deps//libzmq3-dev:libzmq3",
        "@swss_deps//nlohmann-json3-dev:nlohmann-json3",
        "@swss_deps//uuid-dev:uuid",
    ] + select({
        ":yangmodules_enabled": [
            "@libyang3//:yang_hdrs",
            "@libyang3//:yang_hdrs_prefixed",
            "@swss_deps//libpcre2-dev:libpcre2",
        ],
        "//conditions:default": [],
    }),
    soversion = "0",
    version = "0.0.0",
    output_name = "libswsscommon",
    # Match Make: common_libswsscommon_la_LDFLAGS = -Wl,-z,now (no -z,defs).
    allow_undefined = True,
    visibility = ["//visibility:public"],
)

# =============================================================================
# swssloglevel binary — sets logger levels via redis CONFIG_DB.
# =============================================================================
cc_binary(
    name = "swssloglevel",
    srcs = [
        "common/loglevel.cpp",
        "common/loglevel_util.cpp",
    ],
    copts = [
        "-std=c++17",
        "-Wall",
    ],
    dynamic_deps = [
        ":swsscommon_shared",
        "@libnl3//:libnl_3_shared",
        "@libnl3//:libnl_nf_3_shared",
        "@libnl3//:libnl_route_3_shared",
        "@libyang3//:yang_shared",
    ],
    deps = [":swsscommon"],
    visibility = ["//visibility:public"],
)

filegroup(
    name = "lua_scripts",
    srcs = glob(["common/*.lua"]),
)

# =============================================================================
# libswsscommon .deb — main runtime library + lua scripts + swssloglevel.
# =============================================================================
sonic_deb(
    name = "libswsscommon_1.0.0.deb",
    package = "libswsscommon",
    version = "1.0.0",
    content = {
        "/usr/bin:*:0755": [":swssloglevel"],
        "${LIBDIR}:*:0644": [
            ":swsscommon_files",
            ":sonicdbcli_files",
        ],
        "/usr/share/swss:*:0644": [":lua_scripts"],
        "/var/run/redis/sonic-db:*:0644": ["common/database_config.json"],
    },
    depends = [
        # Mirrors what dpkg-shlibdeps generates in the Make recipe.
        "libboost-serialization1.83.0 (>= 1.83.0)",
        "libc6 (>= 2.38)",
        "libgcc-s1 (>= 3.0)",
        "libhiredis1.1.0 (>= 1.2.0)",
        "libnl-3-200 (>= 3.7.0-0.2+b1sonic1)",
        "libnl-nf-3-200 (>= 3.7.0-0.2+b1sonic1)",
        "libnl-route-3-200 (>= 3.7.0-0.2+b1sonic1)",
        "libstdc++6 (>= 13.1)",
        "libuuid1 (>= 2.16)",
        "libyang3 (>= 3.12.2)",
        "libzmq5 (>= 4.0.1+dfsg)",
    ],
    description = "Switch State Service common library.",
    section = "libs",
    maintainer = "SONiC Maintainers",
    gen_dbg = True,
    visibility = ["//visibility:public"],
)

# =============================================================================
# libswsscommon-dev .deb — headers + .so symlink for downstream linking.
# =============================================================================
sonic_deb(
    name = "libswsscommon-dev_1.0.0.deb",
    package = "libswsscommon-dev",
    version = "1.0.0",
    content = {
        "/usr/include/swss:common/:0644": [":swsscommon_hdr_files"],
        "${LIBDIR}:*:0644": [":swsscommon_dev_link"],
        # SWIG interface file ships in -dev so other downstream language
        # bindings (Go, Rust, etc.) can re-process swsscommon.i themselves.
        "/usr/share/swss:pyext/:0644": ["pyext/swsscommon.i"],
    },
    depends = [
        "libswsscommon (= 1.0.0)",
        "libboost-dev | libboost1.71-dev | libboost1.83-dev",
    ],
    description = "Development files for Switch State Service common library.",
    section = "libdevel",
    maintainer = "SONiC Maintainers",
    visibility = ["//visibility:public"],
)

# =============================================================================
# Stage 2: python3-swsscommon (SWIG bindings) + sonic-db-cli
# =============================================================================

# -----------------------------------------------------------------------------
# SWIG codegen: pyext/swsscommon.i  →  swsscommon_wrap.cpp + swsscommon.py
# Mirrors pyext/py3/Makefile.am:
#     $(SWIG) -c++ -python -Wall -keyword [-DENABLE_YANG_MODULES] -Icommon
#             -o pyext/py3/swsscommon_wrap.cpp pyext/swsscommon.i
# -----------------------------------------------------------------------------
swig_gen(
    name = "swsscommon_wrap_gen",
    interface = "pyext/swsscommon.i",
    cpp_out = "pyext/py3/swsscommon_wrap.cpp",
    python_out = "pyext/py3/swsscommon.py",
    wordsize64 = True,
    deps = [":swsscommon"],
)

# -----------------------------------------------------------------------------
# _swsscommon native extension. Mirrors pyext_py3__swsscommon_la in
# Makefile.am: produces _swsscommon.so.0.0.0 with soname _swsscommon.so.0
# (autotools default -version-info 0:0:0). Make ships all three names
# (.so, .so.0, .so.0.0.0) in the python3-swsscommon binary package; we use
# sonic_shared_library_versioned's _files (runtime: .so.0.0.0 + .so.0) and
# _dev_link (.so) filegroups to replicate that layout exactly.
#
# Links libpython3.13 (the system Python on trixie) — the rules_python
# 3.13.4 toolchain we registered above provides matching Python.h.
# -----------------------------------------------------------------------------
sonic_shared_library_versioned(
    name = "_swsscommon",
    srcs = [":swsscommon_wrap_gen"],
    copts = [
        "-std=c++17",
        "-fPIC",
        "-Wno-deprecated-declarations",
    ],
    linkopts = ["-Wl,-z,now"],
    dynamic_deps = [
        ":swsscommon_shared",
        "@libnl3//:libnl_3_shared",
        "@libnl3//:libnl_nf_3_shared",
        "@libnl3//:libnl_route_3_shared",
        "@libyang3//:yang_shared",
    ],
    deps = [
        ":swsscommon",
        "@swss_deps//libhiredis-dev:libhiredis",
        "@rules_python//python/cc:current_py_cc_headers",
        "@rules_python//python/cc:current_py_cc_libs",
    ],
    soversion = "0",
    version = "0.0.0",
    output_name = "_swsscommon",
    allow_undefined = True,
    visibility = ["//visibility:public"],
)

# -----------------------------------------------------------------------------
# python3-swsscommon .deb
# Layout matches Make:
#   /usr/lib/python3/dist-packages/swsscommon/__init__.py
#   /usr/lib/python3/dist-packages/swsscommon/swsscommon.py
#   /usr/lib/python3/dist-packages/swsscommon/_swsscommon.so.0.0.0  (real)
#   /usr/lib/python3/dist-packages/swsscommon/_swsscommon.so.0      (soname)
#   /usr/lib/python3/dist-packages/swsscommon/_swsscommon.so        (dev link)
# -----------------------------------------------------------------------------
sonic_deb(
    name = "python3-swsscommon_1.0.0.deb",
    package = "python3-swsscommon",
    version = "1.0.0",
    content = {
        "/usr/lib/python3/dist-packages/swsscommon:*:0644": [
            "pyext/py3/__init__.py",
            "pyext/py3/swsscommon.py",
            ":_swsscommon_files",
            ":_swsscommon_dev_link_direct",
        ],
    },
    depends = [
        # Mirrors what dpkg-shlibdeps generates in the Make recipe.
        "libc6 (>= 2.32)",
        "libgcc-s1 (>= 3.0)",
        "libhiredis1.1.0 (>= 1.2.0)",
        "libpython3.13 (>= 3.13.0~rc3)",
        "libstdc++6 (>= 13.1)",
        "libswsscommon (>= 1.0.0)",
    ],
    description = "Python3 bindings for Switch State Service common library.",
    section = "libs",
    maintainer = "SONiC Maintainers",
    gen_dbg = True,
    visibility = ["//visibility:public"],
)

# -----------------------------------------------------------------------------
# libsonicdbcli — shared library backing sonic-db-cli. Mirrors
# sonic-db-cli/Makefile.am's lib_LTLIBRARIES += sonic-db-cli/libsonicdbcli.la
# (autotools default version-info => libsonicdbcli.so.0.0.0 with soname
# libsonicdbcli.so.0). The Make recipe ships this .so inside the
# libswsscommon binary package; we match that layout below.
# -----------------------------------------------------------------------------
sonic_shared_library_versioned(
    name = "sonicdbcli",
    srcs = ["sonic-db-cli/sonic-db-cli.cpp"],
    hdrs = ["sonic-db-cli/sonic-db-cli.h"],
    includes = ["sonic-db-cli"],
    copts = [
        "-std=c++17",
        "-Wall",
    ],
    linkopts = [
        "-Wl,-z,now",
        "-lpthread",
    ],
    dynamic_deps = [
        ":swsscommon_shared",
        "@libnl3//:libnl_3_shared",
        "@libnl3//:libnl_nf_3_shared",
        "@libnl3//:libnl_route_3_shared",
        "@libyang3//:yang_shared",
    ],
    deps = [":swsscommon"],
    soversion = "0",
    version = "0.0.0",
    output_name = "libsonicdbcli",
    # Match Make: sonic_db_cli_libsonicdbcli_la_LDFLAGS = -Wl,-z,now (no -z,defs).
    allow_undefined = True,
    visibility = ["//visibility:public"],
)

# -----------------------------------------------------------------------------
# sonic-db-cli command-line tool. Links the libsonicdbcli shared lib + main.cpp.
# -----------------------------------------------------------------------------
cc_binary(
    name = "sonic-db-cli",
    srcs = ["sonic-db-cli/main.cpp"],
    copts = [
        "-std=c++17",
        "-Wall",
    ],
    linkopts = [
        "-Wl,-z,now",
        "-lpthread",
    ],
    dynamic_deps = [
        ":sonicdbcli_shared",
        ":swsscommon_shared",
        "@libnl3//:libnl_3_shared",
        "@libnl3//:libnl_nf_3_shared",
        "@libnl3//:libnl_route_3_shared",
        "@libyang3//:yang_shared",
    ],
    deps = [
        ":sonicdbcli",
        ":swsscommon",
    ],
    visibility = ["//visibility:public"],
)

sonic_deb(
    name = "sonic-db-cli_1.0.0.deb",
    package = "sonic-db-cli",
    version = "1.0.0",
    content = {
        "/usr/bin:*:0755": [":sonic-db-cli"],
    },
    depends = [
        # Mirrors what dpkg-shlibdeps generates in the Make recipe.
        "libc6 (>= 2.34)",
        "libgcc-s1 (>= 3.0)",
        "libstdc++6 (>= 13.1)",
        "libswsscommon (>= 1.0.0)",
    ],
    description = "SONiC DB command-line client.",
    section = "libs",
    maintainer = "SONiC Maintainers",
    gen_dbg = True,
    visibility = ["//visibility:public"],
)
