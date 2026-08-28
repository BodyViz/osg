if(CMAKE_SOURCE_DIR STREQUAL CMAKE_CURRENT_SOURCE_DIR)
    message(FATAL_ERROR
        "tests/ is part of the OpenSceneGraph build and cannot be configured on its "
        "own. Configure the top-level project instead; BUILD_TESTING is on by default.\n"
        "If you meant to verify an INSTALLED package from outside the build tree, that "
        "is tests/packageconsumer -- a separate project with its own README.md.")
endif()

################################################################################
# CTest suite
#
# Reached from the root CMakeLists.txt when BUILD_TESTING is ON, which
# INCLUDE(CTest) defaults to. Everything here is registered conditionally on the
# target actually existing, so turning off BUILD_OSG_APPLICATIONS or a plugin's
# dependency drops the corresponding tests instead of breaking the configure.
#
# Run with:  ctest --preset <preset> -C Release
################################################################################

# Tests get their own scratch directory. Several of them write files, and CTest
# runs every test in the same working directory by default.
SET(OSG_TEST_SCRATCH_DIR ${CMAKE_CURRENT_BINARY_DIR}/scratch)
FILE(MAKE_DIRECTORY ${OSG_TEST_SCRATCH_DIR})


################################################################################
# osgversion -- smoke test
#
# Proves the toolchain produced a binary that links against the static OSG
# libraries and runs. Matching the version string rather than just the exit code
# also proves the generated osg/Version header agrees with the build system's
# idea of the version, which are set in two different places.

IF(TARGET application_osgversion)
    ADD_TEST(
        NAME    osg.version
        COMMAND $<TARGET_FILE:application_osgversion>
    )
    SET_TESTS_PROPERTIES(osg.version PROPERTIES
        PASS_REGULAR_EXPRESSION "OpenSceneGraph Library ${OPENSCENEGRAPH_VERSION}"
        LABELS                  "smoke"
    )
ENDIF()


################################################################################
# osgunittests -- core unit tests
#
# The sources stay in examples/osgunittests where upstream put them, but the
# target is defined here because this is a test, not an example. Building it
# here means BUILD_TESTING is the only gate: examples/CMakeLists.txt registers
# osgunittests only inside the DYNAMIC_OPENSCENEGRAPH branch and only when
# BUILD_OSG_EXAMPLES is ON, so in the static configuration we ship it was never
# built at all. Defining it here also keeps it out of the install tree, where
# SETUP_EXAMPLE would have put it under share/OpenSceneGraph/bin.
#
# Two things about how this binary reports results, both verified by running it:
#
#   * With no arguments it prints its usage and returns 1 (osgunittests.cpp:579).
#     With at least one argument it runs the tests and returns 0 unconditionally
#     (osgunittests.cpp:725) whether they passed or not. So the exit status is
#     never a useful signal and an argument is mandatory.
#   * Results are printed, not returned: one tab-separated line per test,
#     "pass<TAB>name" / "fail<TAB>name" / "error<TAB>name", from the operator<<
#     in UnitTestFramework.cpp. The separate Polytope check reports "has
#     succeeded." / "has failed." instead.
#
# So the verdict has to be read out of the output, which is what
# FAIL_REGULAR_EXPRESSION is for. Both patterns below are needed to cover the
# two output styles. Neither phrase appears in any other string literal in these
# sources, so there is nothing to false-positive on.
#
# Note what is actually asserted: the registered test graph is 10 checks over
# osg::Vec3 arithmetic and osg::Matrix pre/post-mult translate, scale and
# rotate, plus the Polytope containment check. The "matrix", "quat", "sizeof"
# and "filenames" arguments only print diagnostics -- FileNameUtils.cpp, for
# instance, dumps what each path function returns and asserts nothing -- so they
# are registered separately below as crash coverage, not as assertions.

SET(OSGUNITTESTS_DIR ${PROJECT_SOURCE_DIR}/examples/osgunittests)

ADD_EXECUTABLE(test_osgunittests
    ${OSGUNITTESTS_DIR}/osgunittests.cpp
    ${OSGUNITTESTS_DIR}/UnitTestFramework.cpp
    ${OSGUNITTESTS_DIR}/UnitTests_osg.cpp
    ${OSGUNITTESTS_DIR}/performance.cpp
    ${OSGUNITTESTS_DIR}/MultiThreadRead.cpp
    ${OSGUNITTESTS_DIR}/FileNameUtils.cpp
    ${OSGUNITTESTS_DIR}/UnitTestFramework.h
    ${OSGUNITTESTS_DIR}/performance.h
    ${OSGUNITTESTS_DIR}/MultiThreadRead.h
)

TARGET_INCLUDE_DIRECTORIES(test_osgunittests PRIVATE ${OSGUNITTESTS_DIR})
TARGET_LINK_LIBRARIES(test_osgunittests PRIVATE OpenThreads osg osgDB)

SET_TARGET_PROPERTIES(test_osgunittests PROPERTIES
    OUTPUT_NAME   osgunittests
    DEBUG_POSTFIX "${CMAKE_DEBUG_POSTFIX}"
    FOLDER        "Tests"
)

# "polytope" is undocumented in the binary's own usage text but is read at
# osgunittests.cpp:602; it adds the one assertion that lives outside the test
# graph. Any argument at all also runs the full test graph.
ADD_TEST(
    NAME              osg.unittests
    COMMAND           $<TARGET_FILE:test_osgunittests> polytope
    WORKING_DIRECTORY ${OSG_TEST_SCRATCH_DIR}
)

SET_TESTS_PROPERTIES(osg.unittests PROPERTIES
    FAIL_REGULAR_EXPRESSION "(^|\n)(fail|error)\t;has failed"
    LABELS                  "unit"
)

# The diagnostic paths assert nothing, so this only proves they still run
# without crashing.
ADD_TEST(
    NAME              osg.unittests.diagnostics
    COMMAND           $<TARGET_FILE:test_osgunittests> matrix quat sizeof filenames
    WORKING_DIRECTORY ${OSG_TEST_SCRATCH_DIR}
)
SET_TESTS_PROPERTIES(osg.unittests.diagnostics PROPERTIES
    FAIL_REGULAR_EXPRESSION "(^|\n)(fail|error)\t;has failed"
    LABELS                  "unit"
)


################################################################################
# osgroundtrip -- plugin read/write round-trips
#
# The table below is the whole configuration: one row per format, giving the
# extension, the plugin target that provides it, whether it carries nodes or
# images, and how much fidelity the format can be held to.
#
# "exact" means the contents must come back unchanged. "structural" means only
# that the write produced a non-empty file and the read produced something
# usable -- which is all a lossy or hierarchy-flattening format can promise:
# .obj discards transforms, .stl is de-indexed triangles with no hierarchy at
# all, .jpg is lossy by construction. Asserting equality there would fail on
# correct behaviour. Every fidelity value here was checked by running the test,
# not assumed.
#
# Rows whose plugin target does not exist are skipped, so a format whose
# dependency was not found drops out of the link and the test list together
# rather than breaking the configure. That is the same conditional-on-dependency
# behaviour the plugins themselves have.

SET(OSG_ROUNDTRIP_FORMATS
    #  ext | plugin target   | kind  | fidelity
    "osgt  | osgdb_osg       | node  | exact"
    "osgb  | osgdb_osg       | node  | exact"
    "osgx  | osgdb_osg       | node  | exact"
    "ive   | osgdb_ive       | node  | exact"
    "obj   | osgdb_obj       | node  | structural"
    "stl   | osgdb_stl       | node  | structural"
    "dxf   | osgdb_dxf       | node  | structural"
    "3ds   | osgdb_3ds       | node  | structural"
    "ac    | osgdb_ac        | node  | structural"

    "bmp   | osgdb_bmp       | image  | exact"
    "ppm   | osgdb_pnm       | image  | exact"
    "rgb   | osgdb_rgb       | image  | exact"
    "tga   | osgdb_tga       | image  | exact"
    "png   | osgdb_png       | image  | exact"
    "tif   | osgdb_tiff      | image  | exact"
    "dds   | osgdb_dds       | image  | structural"
    "jpg   | osgdb_jpeg      | image  | structural"
    "jp2   | osgdb_jp2       | image  | structural"
    "hdr   | osgdb_hdr       | imagef | structural"
)

# On Apple, osgDB aliases png, tif and tga to the imageio plugin
# (src/osgDB/Registry.cpp:324-332), so a shared build serves those three through
# Core Graphics instead of osgdb_png/osgdb_tiff/osgdb_tga. ImageIO normalises the
# pixel format on the way through, so "exact" asserts something that plugin does
# not offer -- the assertion is what is wrong here, not the plugin. Verified with
# DYLD_PRINT_LIBRARIES: a shared .png round-trip loads osgdb_imageio.so and
# nothing else.
#
# A static build is unaffected, because it links the dedicated plugins and never
# loads imageio, leaving the alias nothing to resolve to. Windows has no imageio
# plugin at all, in either link mode.
IF(APPLE AND DYNAMIC_OPENSCENEGRAPH)
    SET(OSG_ROUNDTRIP_RELAXED "")
    FOREACH(row IN LISTS OSG_ROUNDTRIP_FORMATS)
        STRING(REGEX REPLACE "^ *([^ |]+).*" "\\1" row_ext "${row}")
        IF(row_ext MATCHES "^(png|tif|tga)$")
            STRING(REGEX REPLACE "exact$" "structural" row "${row}")
        ENDIF()
        LIST(APPEND OSG_ROUNDTRIP_RELAXED "${row}")
    ENDFOREACH()
    SET(OSG_ROUNDTRIP_FORMATS ${OSG_ROUNDTRIP_RELAXED})
    MESSAGE(STATUS
        "Round-trip: png/tif/tga relaxed to structural -- a shared Apple build serves "
        "them through imageio, which does not preserve pixel format")
ENDIF()

ADD_EXECUTABLE(test_osgroundtrip osgroundtrip/osgroundtrip.cpp)
TARGET_LINK_LIBRARIES(test_osgroundtrip PRIVATE OpenThreads osg osgDB)
SET_TARGET_PROPERTIES(test_osgroundtrip PROPERTIES
    OUTPUT_NAME   osgroundtrip
    DEBUG_POSTFIX "${CMAKE_DEBUG_POSTFIX}"
    FOLDER        "Tests"
)

SET(OSG_ROUNDTRIP_PLUGIN_TARGETS "")
SET(OSG_ROUNDTRIP_SKIPPED "")

FOREACH(format IN LISTS OSG_ROUNDTRIP_FORMATS)
    STRING(REPLACE "|" ";" fields "${format}")
    LIST(GET fields 0 extension)
    LIST(GET fields 1 plugin_target)
    LIST(GET fields 2 kind)
    LIST(GET fields 3 fidelity)
    FOREACH(var extension plugin_target kind fidelity)
        STRING(STRIP "${${var}}" ${var})
    ENDFOREACH()

    IF(NOT TARGET ${plugin_target})
        LIST(APPEND OSG_ROUNDTRIP_SKIPPED "${extension} (${plugin_target})")
        CONTINUE()
    ENDIF()

    LIST(APPEND OSG_ROUNDTRIP_PLUGIN_TARGETS ${plugin_target})

    ADD_TEST(
        NAME              osg.roundtrip.${kind}.${extension}
        COMMAND           $<TARGET_FILE:test_osgroundtrip> ${kind} ${extension} ${fidelity}
        WORKING_DIRECTORY ${OSG_TEST_SCRATCH_DIR}
    )
    SET_TESTS_PROPERTIES(osg.roundtrip.${kind}.${extension} PROPERTIES
        LABELS "roundtrip"
    )
ENDFOREACH()

IF(OSG_ROUNDTRIP_PLUGIN_TARGETS)
    LIST(REMOVE_DUPLICATES OSG_ROUNDTRIP_PLUGIN_TARGETS)

    # .osgt/.osgb/.osgx are the serialization formats: the osg2 plugin does the
    # file format and the serializer library supplies the per-class read/write
    # code, so without it the plugin loads and then cannot handle any node.
    IF(TARGET osgdb_osg AND TARGET osgdb_serializers_osg)
        LIST(APPEND OSG_ROUNDTRIP_PLUGIN_TARGETS osgdb_serializers_osg)
    ENDIF()

    # One HAVE_<TARGET> define per available plugin, which is what the
    # USE_OSGPLUGIN block in osgroundtrip.cpp keys off. Harmless in a shared
    # build, where that whole block is compiled out.
    FOREACH(plugin_target IN LISTS OSG_ROUNDTRIP_PLUGIN_TARGETS)
        STRING(TOUPPER ${plugin_target} plugin_define)
        TARGET_COMPILE_DEFINITIONS(test_osgroundtrip PRIVATE HAVE_${plugin_define})
    ENDFOREACH()

    # Only static builds link the plugins. In a shared build they are MODULE
    # libraries, loaded at runtime and not linkable at all.
    IF(NOT DYNAMIC_OPENSCENEGRAPH)
        TARGET_LINK_LIBRARIES(test_osgroundtrip PRIVATE ${OSG_ROUNDTRIP_PLUGIN_TARGETS})
    ENDIF()
ENDIF()

IF(OSG_ROUNDTRIP_SKIPPED)
    MESSAGE(STATUS "Round-trip tests skipped, plugin not built: ${OSG_ROUNDTRIP_SKIPPED}")
ENDIF()

# A shared build dlopens its plugins at runtime instead of having them linked in,
# and the Registry looks for <dir>/osgPlugins-<version>/osgdb_<ext>.so for each
# <dir> on its library file path. Nothing puts the build tree on that path by
# default, so without this every format test fails with "Could not find plugin to
# write nodes" -- the plugin is built and correct, just unreachable.
IF(DYNAMIC_OPENSCENEGRAPH)
    # A MODULE library is a RUNTIME artefact on Windows and a LIBRARY artefact
    # everywhere else, so the top-level CMakeLists points
    # CMAKE_LIBRARY_OUTPUT_DIRECTORY at bin/ on Windows and lib/ elsewhere. The
    # search entry has to follow it, because the Registry appends
    # osgPlugins-<version>/ to whatever is on the path.
    IF(WIN32)
        SET(OSG_TEST_PLUGIN_DIR "${OUTPUT_BINDIR}")
    ELSE()
        SET(OSG_TEST_PLUGIN_DIR "${OUTPUT_LIBDIR}")
    ENDIF()

    GET_PROPERTY(OSG_TEST_NAMES DIRECTORY PROPERTY TESTS)
    IF(OSG_TEST_NAMES)
        SET_TESTS_PROPERTIES(${OSG_TEST_NAMES} PROPERTIES
            ENVIRONMENT "OSG_LIBRARY_PATH=${OSG_TEST_PLUGIN_DIR}")
    ENDIF()
ENDIF()
