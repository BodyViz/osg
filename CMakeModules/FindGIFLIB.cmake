# Find giflib.
#
# CMake ships no FindGIFLIB, so this module is bundled with OpenSceneGraph and --
# unlike every other find module the exported package depends on -- it has to be
# installed alongside the package for a consumer's find_dependency(GIFLIB) to
# work. See the CMakeModules install in the top-level CMakeLists.txt.
#
# Defines:
#   GIFLIB::GIFLIB       imported target, with per-configuration locations
#   GIFLIB_FOUND
#   GIFLIB_INCLUDE_DIRS
#   GIFLIB_LIBRARIES
#
# GIFLIB_DIR (variable or environment) can be set to point at a prefix.
#
# Originally by Eric Wing. Rewritten to locate debug and release libraries
# separately and to provide an imported target: giflib names its debug library
# with a "d" suffix, and linking a release giflib into a debug MSVC build is an
# LNK2038 runtime-library mismatch. An imported target also keeps the resolved
# path out of OpenSceneGraph's exported package, which a raw path variable does
# not -- install(EXPORT) writes those verbatim.

include(FindPackageHandleStandardArgs)
include(SelectLibraryConfigurations)

find_path(GIFLIB_INCLUDE_DIR gif_lib.h
    HINTS
        ${GIFLIB_DIR}
        ENV GIFLIB_DIR
    PATH_SUFFIXES include
)

find_library(GIFLIB_LIBRARY_RELEASE
    NAMES gif ungif libgif libungif
    HINTS
        ${GIFLIB_DIR}
        ENV GIFLIB_DIR
    PATH_SUFFIXES lib64 lib
)

find_library(GIFLIB_LIBRARY_DEBUG
    NAMES gifd ungifd libgifd libungifd
    HINTS
        ${GIFLIB_DIR}
        ENV GIFLIB_DIR
    PATH_SUFFIXES lib64 lib
)

# Sets GIFLIB_LIBRARY, and GIFLIB_LIBRARIES, to the release library, the debug
# library, or the "optimized;<rel>;debug;<dbg>" pair as appropriate.
select_library_configurations(GIFLIB)

# Read the version out of gif_lib.h so a consumer can require one.
if(GIFLIB_INCLUDE_DIR AND EXISTS "${GIFLIB_INCLUDE_DIR}/gif_lib.h")
    file(STRINGS "${GIFLIB_INCLUDE_DIR}/gif_lib.h" _giflib_version_line
         REGEX "^#define[ \t]+GIFLIB_MAJOR[ \t]+[0-9]+")
    string(REGEX REPLACE ".*GIFLIB_MAJOR[ \t]+([0-9]+).*" "\\1" _giflib_major "${_giflib_version_line}")
    file(STRINGS "${GIFLIB_INCLUDE_DIR}/gif_lib.h" _giflib_version_line
         REGEX "^#define[ \t]+GIFLIB_MINOR[ \t]+[0-9]+")
    string(REGEX REPLACE ".*GIFLIB_MINOR[ \t]+([0-9]+).*" "\\1" _giflib_minor "${_giflib_version_line}")
    file(STRINGS "${GIFLIB_INCLUDE_DIR}/gif_lib.h" _giflib_version_line
         REGEX "^#define[ \t]+GIFLIB_RELEASE[ \t]+[0-9]+")
    string(REGEX REPLACE ".*GIFLIB_RELEASE[ \t]+([0-9]+).*" "\\1" _giflib_patch "${_giflib_version_line}")
    if(_giflib_major MATCHES "^[0-9]+$")
        set(GIFLIB_VERSION "${_giflib_major}.${_giflib_minor}.${_giflib_patch}")
    endif()
    unset(_giflib_version_line)
    unset(_giflib_major)
    unset(_giflib_minor)
    unset(_giflib_patch)
endif()

find_package_handle_standard_args(GIFLIB
    REQUIRED_VARS GIFLIB_LIBRARY GIFLIB_INCLUDE_DIR
    VERSION_VAR   GIFLIB_VERSION
)

if(GIFLIB_FOUND)
    set(GIFLIB_INCLUDE_DIRS "${GIFLIB_INCLUDE_DIR}")

    if(NOT TARGET GIFLIB::GIFLIB)
        add_library(GIFLIB::GIFLIB UNKNOWN IMPORTED)
        set_target_properties(GIFLIB::GIFLIB PROPERTIES
            INTERFACE_INCLUDE_DIRECTORIES "${GIFLIB_INCLUDE_DIR}")

        if(GIFLIB_LIBRARY_RELEASE)
            set_property(TARGET GIFLIB::GIFLIB APPEND PROPERTY
                IMPORTED_CONFIGURATIONS RELEASE)
            set_target_properties(GIFLIB::GIFLIB PROPERTIES
                IMPORTED_LOCATION_RELEASE "${GIFLIB_LIBRARY_RELEASE}")
        endif()

        if(GIFLIB_LIBRARY_DEBUG)
            set_property(TARGET GIFLIB::GIFLIB APPEND PROPERTY
                IMPORTED_CONFIGURATIONS DEBUG)
            set_target_properties(GIFLIB::GIFLIB PROPERTIES
                IMPORTED_LOCATION_DEBUG "${GIFLIB_LIBRARY_DEBUG}")
        endif()

        if(NOT GIFLIB_LIBRARY_RELEASE AND NOT GIFLIB_LIBRARY_DEBUG)
            set_target_properties(GIFLIB::GIFLIB PROPERTIES
                IMPORTED_LOCATION "${GIFLIB_LIBRARY}")
        endif()
    endif()
endif()

mark_as_advanced(GIFLIB_INCLUDE_DIR GIFLIB_LIBRARY_RELEASE GIFLIB_LIBRARY_DEBUG)
