################################################################################
# Out-of-tree consumer test for an INSTALLED OpenSceneGraph package.
#
# NOT part of the OpenSceneGraph build. tests/CMakeLists.txt deliberately does
# not add_subdirectory() this: the whole point is to configure it separately,
# against an install prefix, exactly as a real application would. Wiring it into
# the main build would test the build tree instead and prove nothing about the
# installed package.
#
# See README.md in this directory for how to run it.
################################################################################

cmake_minimum_required(VERSION 3.30)
project(osgPackageConsumer LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# COMPONENTS are checked against what the install actually contains, so asking
# for one that is missing fails here rather than at link time.
find_package(OpenSceneGraph REQUIRED COMPONENTS osg osgDB osgUtil CONFIG)

message(STATUS "Found OpenSceneGraph ${OpenSceneGraph_VERSION}")

add_executable(osgPackageConsumer main.cpp)
target_link_libraries(osgPackageConsumer PRIVATE osg3::osg osg3::osgDB osg3::osgUtil)

# Passed in so the program can check the version three ways -- installed headers,
# linked library, and what the package config itself declared.
target_compile_definitions(osgPackageConsumer PRIVATE
    CONSUMER_EXPECTED_VERSION="${OpenSceneGraph_VERSION}")

# Whether this is a static package is discoverable rather than assumed: plugins
# are only exported as linkable targets by a static build. In a shared build they
# are MODULE libraries loaded from disk, and there is nothing to link.
if(TARGET osg3::osgdb_osg)
    message(STATUS "Static package: linking plugins explicitly")
    target_compile_definitions(osgPackageConsumer PRIVATE CONSUMER_STATIC_PLUGINS)
    target_link_libraries(osgPackageConsumer PRIVATE
        osg3::osgdb_osg osg3::osgdb_serializers_osg)

    # One entry per optional plugin. A plugin absent from the package -- because
    # its dependency was not found when OpenSceneGraph was built -- drops out of
    # both the link and the checks, so this reports on what is actually there.
    set(optional_plugins
        PNG      osgdb_png
        JPEG     osgdb_jpeg
        TIFF     osgdb_tiff
        GIF      osgdb_gif
        JP2      osgdb_jp2
        FREETYPE osgdb_freetype
    )
    set(found_plugins "")
    set(missing_plugins "")
    while(optional_plugins)
        list(POP_FRONT optional_plugins tag target)
        if(TARGET osg3::${target})
            target_compile_definitions(osgPackageConsumer PRIVATE HAVE_${tag})
            target_link_libraries(osgPackageConsumer PRIVATE osg3::${target})
            list(APPEND found_plugins ${target})
        else()
            list(APPEND missing_plugins ${target})
        endif()
    endwhile()

    message(STATUS "  plugins found:   ${found_plugins}")
    if(missing_plugins)
        message(STATUS "  plugins absent:  ${missing_plugins}")
    endif()
else()
    message(STATUS "Shared package: plugins are loaded at runtime, none to link")
endif()

# Run it as a test too, so ctest can drive it.
enable_testing()
add_test(NAME osg.package.consumer COMMAND osgPackageConsumer)
