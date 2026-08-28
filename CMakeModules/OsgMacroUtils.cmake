
#######################################################################################################
#  macro for linking libraries that come from Findxxxx commands, so there is a variable that contains the
#  full path of the library name. in order to differentiate release and debug, this macro get the
#  NAME of the variables, so the macro gets as arguments the target name and the following list of parameters
#  is intended as a list of variable names each one containing  the path of the libraries to link to
#  The existence of a variable name with _DEBUG appended is tested and, in case it' s value is used
#  for linking to when in debug mode
#  the content of this library for linking when in debugging
#######################################################################################################

#######################################################################################################
# Records that some target names an imported target from another package.
#
# install(EXPORT) writes imported targets into the exported link interface by
# name, not by path, so the name has to exist again on the consumer's machine.
# The root CMakeLists turns this list into the find_dependency() calls at the top
# of OpenSceneGraphConfig.cmake.
#
#######################################################################################################

FUNCTION(OSG_ADD_PACKAGE_DEPENDENCY PACKAGE_NAME)
    SET_PROPERTY(DIRECTORY APPEND PROPERTY OSG_PENDING_PACKAGE_DEPENDENCIES "${PACKAGE_NAME}")
ENDFUNCTION(OSG_ADD_PACKAGE_DEPENDENCY)

# Call from wherever a target is added to EXPORT OpenSceneGraphTargets. Anything
# this directory registered and never promotes is a dependency of a target the
# installed package does not describe, so consumers must not be asked for it.
MACRO(OSG_PROMOTE_PACKAGE_DEPENDENCIES)
    GET_PROPERTY(OSG_PENDING_DEPENDENCIES DIRECTORY PROPERTY OSG_PENDING_PACKAGE_DEPENDENCIES)
    IF(OSG_PENDING_DEPENDENCIES)
        SET_PROPERTY(GLOBAL APPEND PROPERTY OSG_PACKAGE_DEPENDENCIES ${OSG_PENDING_DEPENDENCIES})
    ENDIF()
    UNSET(OSG_PENDING_DEPENDENCIES)
ENDMACRO(OSG_PROMOTE_PACKAGE_DEPENDENCIES)

MACRO(LINK_WITH_VARIABLES TRGTNAME)
    FOREACH(varname ${ARGN})
        IF(${varname}_DEBUG)
            IF(${varname}_RELEASE)
                TARGET_LINK_LIBRARIES(${TRGTNAME} optimized "${${varname}_RELEASE}" debug "${${varname}_DEBUG}")
            ELSE(${varname}_RELEASE)
                TARGET_LINK_LIBRARIES(${TRGTNAME} optimized "${${varname}}" debug "${${varname}_DEBUG}")
            ENDIF(${varname}_RELEASE)
        ELSE(${varname}_DEBUG)
            TARGET_LINK_LIBRARIES(${TRGTNAME} ${${varname}} )
        ENDIF(${varname}_DEBUG)
    ENDFOREACH(varname)
ENDMACRO(LINK_WITH_VARIABLES TRGTNAME)

MACRO(LINK_INTERNAL TRGTNAME)
    TARGET_LINK_LIBRARIES(${TRGTNAME} ${ARGN})
ENDMACRO(LINK_INTERNAL TRGTNAME)

MACRO(LINK_EXTERNAL TRGTNAME)
    FOREACH(LINKLIB ${ARGN})
        TARGET_LINK_LIBRARIES(${TRGTNAME} "${LINKLIB}" )
    ENDFOREACH(LINKLIB)
ENDMACRO(LINK_EXTERNAL TRGTNAME)


#######################################################################################################
# Sets ALL_GL_LIBRARIES to whatever provides GL on this platform.
#
# Prefer the imported target: install(EXPORT) records it by name, so
# find_dependency(OpenGL) recreates it on the consumer's machine.
# ${OPENGL_gl_LIBRARY} is an absolute path -- inside the active SDK on macOS --
# and would be frozen into the installed package. The iOS and GLES branches of
# the root CMakeLists set the variable by hand without calling
# FIND_PACKAGE(OpenGL), so the raw fallback has to stay.
#######################################################################################################

MACRO(SET_ALL_GL_LIBRARIES)
    IF(TARGET OpenGL::GL)
        SET(ALL_GL_LIBRARIES OpenGL::GL)
    ELSE()
        SET(ALL_GL_LIBRARIES ${OPENGL_gl_LIBRARY})
    ENDIF()
    IF (OSG_GLES1_AVAILABLE OR OSG_GLES2_AVAILABLE OR OSG_GLES3_AVAILABLE)
        SET(ALL_GL_LIBRARIES ${ALL_GL_LIBRARIES} ${EGL_LIBRARY})
    ENDIF()
ENDMACRO(SET_ALL_GL_LIBRARIES)

#######################################################################################################
#  macro for common setup of core libraries: it links OPENGL_LIBRARIES in undifferentiated mode
#######################################################################################################

MACRO(LINK_CORELIB_DEFAULT CORELIB_NAME)
    SET_ALL_GL_LIBRARIES()
    IF(TARGET OpenGL::GL)
        OSG_ADD_PACKAGE_DEPENDENCY(OpenGL)
    ENDIF()

    LINK_EXTERNAL(${CORELIB_NAME} ${ALL_GL_LIBRARIES})
    LINK_WITH_VARIABLES(${CORELIB_NAME} OPENTHREADS_LIBRARY)
    IF(OPENSCENEGRAPH_SONAMES)
      SET_TARGET_PROPERTIES(${CORELIB_NAME} PROPERTIES VERSION ${OPENSCENEGRAPH_VERSION} SOVERSION ${OPENSCENEGRAPH_SOVERSION})
    ENDIF(OPENSCENEGRAPH_SONAMES)

ENDMACRO(LINK_CORELIB_DEFAULT CORELIB_NAME)


#######################################################################################################
#  macro for common setup of plugins, examples and applications it expect some variables to be set:
#  either within the local CMakeLists or higher in hierarchy
#  TARGET_NAME is the name of the folder and of the actually .exe or .so or .dll
#  TARGET_TARGETNAME  is the name of the target , this get buit out of a prefix, if present and TARGET_TARGETNAME
#  TARGET_SRC  are the sources of the target
#  TARGET_H are the eventual headers of the target
#  TARGET_LIBRARIES are the libraries to link to that are internal to the project and have d suffix for debug
#  TARGET_EXTERNAL_LIBRARIES are external libraries and are not differentiated with d suffix
#  TARGET_LABEL is the label IDE should show up for targets
##########################################################################################################

MACRO(SETUP_LINK_LIBRARIES)
    ######################################################################
    #
    # This set up the libraries to link to, it assumes there are two variable: one common for a group of examples or plugins
    # kept in the variable TARGET_COMMON_LIBRARIES and an example or plugin specific kept in TARGET_ADDED_LIBRARIES
    # they are combined in a single list checked for unicity
    # the suffix ${CMAKE_DEBUG_POSTFIX} is used for differentiating optimized and debug
    #
    # a second variable TARGET_EXTERNAL_LIBRARIES hold the list of  libraries not differentiated between debug and optimized
    ##################################################################################
    SET(TARGET_LIBRARIES ${TARGET_COMMON_LIBRARIES})

    FOREACH(LINKLIB ${TARGET_ADDED_LIBRARIES})
      SET(TO_INSERT TRUE)
      FOREACH (value ${TARGET_COMMON_LIBRARIES})
            IF ("${value}" STREQUAL "${LINKLIB}")
                  SET(TO_INSERT FALSE)
            ENDIF ("${value}" STREQUAL "${LINKLIB}")
        ENDFOREACH (value ${TARGET_COMMON_LIBRARIES})
      IF(TO_INSERT)
          LIST(APPEND TARGET_LIBRARIES ${LINKLIB})
      ENDIF(TO_INSERT)
    ENDFOREACH(LINKLIB)

    SET_ALL_GL_LIBRARIES()

#    FOREACH(LINKLIB ${TARGET_LIBRARIES})
#            TARGET_LINK_LIBRARIES(${TARGET_TARGETNAME} optimized ${LINKLIB} debug "${LINKLIB}${CMAKE_DEBUG_POSTFIX}")
#    ENDFOREACH(LINKLIB)
        LINK_INTERNAL(${TARGET_TARGETNAME} ${TARGET_LIBRARIES})
#    FOREACH(LINKLIB ${TARGET_EXTERNAL_LIBRARIES})
#            TARGET_LINK_LIBRARIES(${TARGET_TARGETNAME} ${LINKLIB})
#    ENDFOREACH(LINKLIB)
        TARGET_LINK_LIBRARIES(${TARGET_TARGETNAME} ${TARGET_EXTERNAL_LIBRARIES})
        IF(TARGET_LIBRARIES_VARS)
            LINK_WITH_VARIABLES(${TARGET_TARGETNAME} ${TARGET_LIBRARIES_VARS})
        ENDIF(TARGET_LIBRARIES_VARS)
    IF(MSVC  AND OSG_MSVC_VERSIONED_DLL)
        #when using full path name to specify linkage, it seems that already linked libs must be specified
            LINK_EXTERNAL(${TARGET_TARGETNAME} ${ALL_GL_LIBRARIES})
    ENDIF(MSVC AND OSG_MSVC_VERSIONED_DLL)

ENDMACRO(SETUP_LINK_LIBRARIES)

############################################################################################
# this is the common set of command for all the plugins
#

# Redirects a target's build output into a subdirectory of the default one.
#
# Load-bearing for shared builds: a plugin has to sit in a directory literally
# named osgPlugins-<version>, because Registry::createLibraryNameForExtension()
# prepends that directory to every filename it dlopens.
MACRO(SET_OUTPUT_DIR_PROPERTY_260 TARGET_TARGETNAME RELATIVE_OUTDIR)
    # Global properties (single-config generators)
    FILE(TO_CMAKE_PATH "${CMAKE_ARCHIVE_OUTPUT_DIRECTORY}/${RELATIVE_OUTDIR}" TMPVAR)
    SET_TARGET_PROPERTIES(${TARGET_TARGETNAME} PROPERTIES ARCHIVE_OUTPUT_DIRECTORY "${TMPVAR}")
    FILE(TO_CMAKE_PATH "${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/${RELATIVE_OUTDIR}" TMPVAR)
    SET_TARGET_PROPERTIES(${TARGET_TARGETNAME} PROPERTIES RUNTIME_OUTPUT_DIRECTORY "${TMPVAR}")
    FILE(TO_CMAKE_PATH "${CMAKE_LIBRARY_OUTPUT_DIRECTORY}/${RELATIVE_OUTDIR}" TMPVAR)
    SET_TARGET_PROPERTIES(${TARGET_TARGETNAME} PROPERTIES LIBRARY_OUTPUT_DIRECTORY "${TMPVAR}")

    # Per-configuration properties
    FOREACH(CONF ${CMAKE_CONFIGURATION_TYPES})        # For each configuration (Debug, Release, MinSizeRel... and/or anything the user chooses)
        STRING(TOUPPER "${CONF}" CONF)                # Go uppercase (DEBUG, RELEASE...)

        # We use "FILE(TO_CMAKE_PATH", to create nice looking paths
        FILE(TO_CMAKE_PATH "${CMAKE_ARCHIVE_OUTPUT_DIRECTORY_${CONF}}/${RELATIVE_OUTDIR}" TMPVAR)
        SET_TARGET_PROPERTIES(${TARGET_TARGETNAME} PROPERTIES "ARCHIVE_OUTPUT_DIRECTORY_${CONF}" "${TMPVAR}")
        FILE(TO_CMAKE_PATH "${CMAKE_RUNTIME_OUTPUT_DIRECTORY_${CONF}}/${RELATIVE_OUTDIR}" TMPVAR)
        SET_TARGET_PROPERTIES(${TARGET_TARGETNAME} PROPERTIES "RUNTIME_OUTPUT_DIRECTORY_${CONF}" "${TMPVAR}")
        FILE(TO_CMAKE_PATH "${CMAKE_LIBRARY_OUTPUT_DIRECTORY_${CONF}}/${RELATIVE_OUTDIR}" TMPVAR)
        SET_TARGET_PROPERTIES(${TARGET_TARGETNAME} PROPERTIES "LIBRARY_OUTPUT_DIRECTORY_${CONF}" "${TMPVAR}")
    ENDFOREACH(CONF ${CMAKE_CONFIGURATION_TYPES})
ENDMACRO(SET_OUTPUT_DIR_PROPERTY_260 TARGET_TARGETNAME RELATIVE_OUTDIR)



#######################################################################################################
#  macro for common setup of libraries it expect some variables to be set:
#  either within the local CMakeLists or higher in hierarchy
#  LIB_NAME  is the name of the target library
#  TARGET_SRC  are the sources of the target
#  TARGET_H are the eventual headers of the target
#  TARGET_H_NO_MODULE_INSTALL are headers that belong to target but shouldn't get installed by the ModuleInstall script
#  TARGET_LIBRARIES are the libraries to link to that are internal to the project and have d suffix for debug
#  TARGET_EXTERNAL_LIBRARIES are external libraries and are not differentiated with d suffix
#  TARGET_LABEL is the label IDE should show up for targets
##########################################################################################################

MACRO(SETUP_LIBRARY LIB_NAME)
    IF(GLCORE_FOUND)
        INCLUDE_DIRECTORIES( ${GLCORE_INCLUDE_DIR} )
    ENDIF()

        SET(TARGET_NAME ${LIB_NAME} )
        SET(TARGET_TARGETNAME ${LIB_NAME} )
        ADD_LIBRARY(${LIB_NAME}
            ${OPENSCENEGRAPH_USER_DEFINED_DYNAMIC_OR_STATIC}
            ${TARGET_H}
            ${TARGET_H_NO_MODULE_INSTALL}
            ${TARGET_SRC}
        )

        TARGET_INCLUDE_DIRECTORIES(${LIB_NAME}
            PUBLIC
                $<BUILD_INTERFACE:${PROJECT_SOURCE_DIR}/include>
                $<BUILD_INTERFACE:${PROJECT_BINARY_DIR}/include>
                $<INSTALL_INTERFACE:${INSTALL_INCDIR}>
        )

        IF(OPENSCENEGRAPH_USER_DEFINED_DYNAMIC_OR_STATIC STREQUAL "STATIC")
            TARGET_COMPILE_DEFINITIONS(${LIB_NAME} PUBLIC OSG_LIBRARY_STATIC)
        ENDIF()

        SET_TARGET_PROPERTIES(${LIB_NAME} PROPERTIES FOLDER "OSG Core")
        IF(APPLE)
            IF(OSG_BUILD_PLATFORM_IPHONE)
                SET_TARGET_PROPERTIES(${LIB_NAME} PROPERTIES XCODE_ATTRIBUTE_ENABLE_BITCODE ${IPHONE_ENABLE_BITCODE})
            ENDIF()
            SET_TARGET_PROPERTIES(${LIB_NAME} PROPERTIES XCODE_ATTRIBUTE_WARNING_CFLAGS "")
        ENDIF()
        IF(TARGET_LABEL)
            SET_TARGET_PROPERTIES(${TARGET_TARGETNAME} PROPERTIES PROJECT_LABEL "${TARGET_LABEL}")
        ENDIF(TARGET_LABEL)

        IF(TARGET_LIBRARIES)
            LINK_INTERNAL(${LIB_NAME} ${TARGET_LIBRARIES})
        ENDIF()
        IF(TARGET_EXTERNAL_LIBRARIES)
            LINK_EXTERNAL(${LIB_NAME} ${TARGET_EXTERNAL_LIBRARIES})
        ENDIF()
        IF(TARGET_LIBRARIES_VARS)
            LINK_WITH_VARIABLES(${LIB_NAME} ${TARGET_LIBRARIES_VARS})
        ENDIF(TARGET_LIBRARIES_VARS)
        LINK_CORELIB_DEFAULT(${LIB_NAME})

    OSG_PROMOTE_PACKAGE_DEPENDENCIES()

    INCLUDE(ModuleInstall OPTIONAL)
ENDMACRO(SETUP_LIBRARY LIB_NAME)

MACRO(SETUP_PLUGIN PLUGIN_NAME)
    IF(GLCORE_FOUND)
        INCLUDE_DIRECTORIES( ${GLCORE_INCLUDE_DIR} )
    ENDIF()

    SET(TARGET_NAME ${PLUGIN_NAME} )

    #MESSAGE("in -->SETUP_PLUGIN<-- ${TARGET_NAME}-->${TARGET_SRC} <--> ${TARGET_H}<--")

    ## we have set up the target label and targetname by taking into account global prfix (osgdb_)

    IF(NOT TARGET_TARGETNAME)
            SET(TARGET_TARGETNAME "${TARGET_DEFAULT_PREFIX}${TARGET_NAME}")
    ENDIF(NOT TARGET_TARGETNAME)
    IF(NOT TARGET_LABEL)
            SET(TARGET_LABEL "${TARGET_DEFAULT_LABEL_PREFIX} ${TARGET_NAME}")
    ENDIF(NOT TARGET_LABEL)

    ## plugins gets put in libopenscenegraph by default
    IF(${ARGC} GREATER 1)
      SET(PACKAGE_COMPONENT libopenscenegraph-${ARGV1})

      # add cpack config variables for plugin with own package
      IF(BUILD_OSG_PACKAGES)
        IF("${CPACK_GENERATOR}" STREQUAL "DEB")
            STRING(TOUPPER ${PACKAGE_COMPONENT} UPPER_PACKAGE_COMPONENT)
            SET(CPACK_${UPPER_PACKAGE_COMPONENT}_DEPENDENCIES
                "libopenscenegraph"
                CACHE STRING
                "Dependend packages for the ${PACKAGE_COMPONENT} package with all components (uses deb dependecy format), e.g., 'libc6, libcurl3-gnutls, libgif4, libjpeg8, libpng12-0'"
            )
            SET(CPACK_${UPPER_PACKAGE_COMPONENT}_CONFLICTS
                ""
                CACHE STRING
                "Conflicting packages for the ${PACKAGE_COMPONENT} package (uses deb dependecy format), e.g., 'libc6, libcurl3-gnutls, libgif4, libjpeg8, libpng12-0'"
            )
        ENDIF()
      ENDIF()
    ELSE(${ARGC} GREATER 1)
      SET(PACKAGE_COMPONENT libopenscenegraph)
    ENDIF(${ARGC} GREATER 1)

    # Add the VisualStudio versioning info, but only to shared plugins.
    IF(DYNAMIC_OPENSCENEGRAPH)
        SET(TARGET_SRC ${TARGET_SRC} ${OPENSCENEGRAPH_VERSIONINFO_RC})
    ENDIF()

    # here we use the command to generate the library
    IF   (DYNAMIC_OPENSCENEGRAPH)
        ADD_LIBRARY(${TARGET_TARGETNAME} MODULE ${TARGET_SRC} ${TARGET_H})
    ELSE (DYNAMIC_OPENSCENEGRAPH)
        ADD_LIBRARY(${TARGET_TARGETNAME} STATIC ${TARGET_SRC} ${TARGET_H})

        # Record the target so an application can link the whole plugin set
        # without naming each one. Only static plugins go on the list -- a MODULE
        # is dlopened at runtime and is not linkable at all. Read back with
        # GET_PROPERTY(... GLOBAL PROPERTY OSG_STATIC_PLUGIN_TARGETS); see
        # applications/osgconv/CMakeLists.txt. Same pattern as
        # OSG_PACKAGE_DEPENDENCIES.
        SET_PROPERTY(GLOBAL APPEND PROPERTY OSG_STATIC_PLUGIN_TARGETS ${TARGET_TARGETNAME})
    ENDIF(DYNAMIC_OPENSCENEGRAPH)

    IF(MSVC)
        SET_OUTPUT_DIR_PROPERTY_260(${TARGET_TARGETNAME} "${OSG_PLUGINS}")        # Sets the ouput to be /osgPlugin-X.X.X ; also ensures the /Debug /Release are removed
    ELSEIF(DYNAMIC_OPENSCENEGRAPH)
        # A shared plugin has to sit in a directory literally named
        # osgPlugins-<version> or the Registry cannot find it:
        # Registry::createLibraryNameForExtension() unconditionally prepends that
        # directory to the filename it dlopens (src/osgDB/Registry.cpp:786).
        #
        # Static builds are deliberately left alone: nothing searches for an archive
        # at runtime, and this macro also moves ARCHIVE_OUTPUT_DIRECTORY, which would
        # relocate every plugin archive for no benefit.
        SET_OUTPUT_DIR_PROPERTY_260(${TARGET_TARGETNAME} "${OSG_PLUGINS}")
    ENDIF(MSVC)

    SET_TARGET_PROPERTIES(${TARGET_TARGETNAME} PROPERTIES PROJECT_LABEL "${TARGET_LABEL}")
    SET_TARGET_PROPERTIES(${TARGET_TARGETNAME} PROPERTIES FOLDER "Plugins")
    IF(APPLE)
        SET_TARGET_PROPERTIES(${TARGET_TARGETNAME} PROPERTIES XCODE_ATTRIBUTE_WARNING_CFLAGS "")
        IF(OSG_BUILD_PLATFORM_IPHONE)
            SET_TARGET_PROPERTIES(${TARGET_TARGETNAME} PROPERTIES XCODE_ATTRIBUTE_ENABLE_BITCODE ${IPHONE_ENABLE_BITCODE})
        ENDIF()
    ENDIF()
    SETUP_LINK_LIBRARIES()

    # A static plugin is an ordinary archive, so it goes in the export set and
    # consumers can link it by name. In a shared build a plugin is a MODULE --
    # opened at runtime by osgDB, never linked against -- and CMake will not
    # accept a MODULE library in an export set.
    IF(DYNAMIC_OPENSCENEGRAPH)
        SET(PLUGIN_EXPORT_ARGS)
    ELSE()
        SET(PLUGIN_EXPORT_ARGS EXPORT OpenSceneGraphTargets)
        OSG_PROMOTE_PACKAGE_DEPENDENCIES()
    ENDIF()

# the installation path are differentiated for win32 that install in bin versus
# other architecture that install in ${OSG_INSTALL_LIBDIR}/${OSG_PLUGINS}
    IF(WIN32)
        INSTALL(TARGETS ${TARGET_TARGETNAME}
            ${PLUGIN_EXPORT_ARGS}
            RUNTIME DESTINATION bin COMPONENT ${PACKAGE_COMPONENT}
            ARCHIVE DESTINATION lib/${OSG_PLUGINS} COMPONENT libopenscenegraph-dev
            LIBRARY DESTINATION bin/${OSG_PLUGINS} COMPONENT ${PACKAGE_COMPONENT})
        IF(MSVC AND DYNAMIC_OPENSCENEGRAPH)
            INSTALL(FILES $<TARGET_PDB_FILE:${TARGET_TARGETNAME}> DESTINATION bin/${OSG_PLUGINS} COMPONENT ${PACKAGE_COMPONENT} OPTIONAL)
        ENDIF(MSVC AND DYNAMIC_OPENSCENEGRAPH)
    ELSE(WIN32)
        INSTALL(TARGETS ${TARGET_TARGETNAME}
            ${PLUGIN_EXPORT_ARGS}
            RUNTIME DESTINATION bin COMPONENT ${PACKAGE_COMPONENT}
            ARCHIVE DESTINATION ${OSG_INSTALL_LIBDIR}/${OSG_PLUGINS} COMPONENT libopenscenegraph-dev
            LIBRARY DESTINATION ${OSG_INSTALL_LIBDIR}/${OSG_PLUGINS} COMPONENT ${PACKAGE_COMPONENT})
    ENDIF(WIN32)
ENDMACRO(SETUP_PLUGIN)


#################################################################################################################
# Links every static plugin archive into an executable with whole-archive.
#
# A static build has no plugin files to discover at runtime; the Registry is
# populated by static initializers instead, and those only run if the linker keeps
# the archive members that define them. Ordinary static linking pulls only the
# members it needs to resolve a symbol, so without help every plugin archive is
# discarded and the executable can read no file format at all.
#
# The usual remedy is a USE_OSGPLUGIN(name) per plugin in the source, but that name
# is the one passed to REGISTER_OSGPLUGIN, which differs from the CMake target name
# for eleven plugins -- .osgt/.osgb/.osgx are registered as "osg2" but built as
# osgdb_osg, .gz as "GZ", pov as "Povray", and so on. A hand-written list across
# every plugin is a standing invitation to link the right archive under the wrong
# name, which links cleanly and then silently fails at runtime.
#
# Whole-archive linking sidesteps the mapping entirely: every member of each archive
# is kept, so the static proxies that REGISTER_OSGPLUGIN and REGISTER_OBJECT_WRAPPER
# create run their constructors and register themselves. It needs only CMake target
# names, which the build already knows, and it picks up the serializer and
# deprecated-wrapper libraries for free -- their LibraryWrapper.cpp files exist only
# to anchor archive members that whole-archive keeps anyway.
# $<LINK_LIBRARY:WHOLE_ARCHIVE,...> maps to -force_load on Apple and /WHOLEARCHIVE:
# on MSVC.
#
# The target list comes from SETUP_PLUGIN above, which appends every static plugin
# to a global property. That property is empty in a shared build, where plugins are
# MODULEs found at runtime, so this is inert there.
#
# Examples deliberately do not call this. They are built as a compile-and-link check
# on the static configuration, and plugins contribute to neither -- they matter only
# at runtime, for loading model and image files. Force-loading 88 archives into each
# of 162 examples would cost roughly 14 GB against 1.8 GB. osgconv and the
# tests/packageconsumer check already prove the plugin registration path.
#################################################################################################################

# Keeping every member of every archive exposes duplicate definitions that ordinary
# static linking never surfaces, because ordinarily the linker pulls only the members
# it needs and stops at the first definition of a symbol. These three pairs each
# define the same symbol twice:
#
#   osgdb_serializers_osgui / osgdb_serializers_osgga
#       Both register their Widget serializer as REGISTER_OBJECT_WRAPPER(Widget, ...),
#       which yields wrapper_serializer_Widget in both. The serialized class name
#       comes from the macro's CLASS argument (osgGA::Widget vs osgUI::Widget), so
#       only the C symbol collides.
#   osgdb_deprecated_osgvolume / osgdb_deprecated_osgterrain
#       Nine symbols. Both libraries have Layer, Locator and ImageLayer classes and
#       their dotosg wrappers are named after the class, unqualified.
#   osgdb_deprecated_osganimation / osgdb_deprecated_osg
#       readMatrix and writeMatrix. deprecated-dotosg/osgAnimation/Matrix.cpp is a
#       byte-for-byte copy of deprecated-dotosg/osg/Matrix.cpp.
SET(OSG_WHOLE_ARCHIVE_EXCLUDE
    osgdb_serializers_osgui
    osgdb_deprecated_osgvolume
    osgdb_deprecated_osganimation
)

# Linking every plugin means inheriting every plugin's third-party
# dependencies, so one badly built dependency breaks the whole executable rather
# than just its own format:
SET(OSG_WHOLE_ARCHIVE_EXCLUDE_PLUGINS "" CACHE STRING
    "Plugin targets to leave out of the whole-archive link of osgconv, osgviewer, osgarchive and osgfilecache, semicolon separated (e.g. osgdb_dicom). For working around a third-party dependency that cannot be linked on this machine; the plugin stays available to anything that links it directly.")

FUNCTION(OSG_LINK_ALL_STATIC_PLUGINS TARGET_TARGETNAME)
    IF(DYNAMIC_OPENSCENEGRAPH)
        RETURN()
    ENDIF()

    GET_PROPERTY(plugin_targets GLOBAL PROPERTY OSG_STATIC_PLUGIN_TARGETS)

    IF(NOT plugin_targets)
        MESSAGE(WARNING
            "${TARGET_TARGETNAME}: no static plugin targets were recorded, so it will not "
            "be able to read or write any file format. Is BUILD_OSG_PLUGINS off?")
        RETURN()
    ENDIF()

    LIST(REMOVE_DUPLICATES plugin_targets)
    LIST(SORT plugin_targets)
    SET(whole_archive ${plugin_targets})

    SET(link_normally "")
    FOREACH(excluded IN LISTS OSG_WHOLE_ARCHIVE_EXCLUDE)
        IF(excluded IN_LIST plugin_targets)
            LIST(APPEND link_normally ${excluded})
        ELSE()
            MESSAGE(WARNING
                "${TARGET_TARGETNAME}: ${excluded} is in OSG_WHOLE_ARCHIVE_EXCLUDE but was "
                "not built, so the exclusion does nothing here.")
        ENDIF()
        LIST(REMOVE_ITEM whole_archive ${excluded})
    ENDFOREACH()

    FOREACH(excluded IN LISTS OSG_WHOLE_ARCHIVE_EXCLUDE_PLUGINS)
        IF(NOT excluded IN_LIST plugin_targets)
            MESSAGE(WARNING
                "${TARGET_TARGETNAME}: OSG_WHOLE_ARCHIVE_EXCLUDE_PLUGINS names ${excluded}, "
                "which is not a plugin target in this build. Check the spelling -- the names "
                "are CMake targets such as osgdb_dicom.")
        ELSE()
            MESSAGE(STATUS
                "${TARGET_TARGETNAME}: excluding ${excluded} by request. That format will not "
                "be available; anything linking osg3::${excluded} directly is unaffected and "
                "will hit the same problem.")
        ENDIF()
        LIST(REMOVE_ITEM whole_archive ${excluded})
    ENDFOREACH()

    LIST(LENGTH whole_archive whole_archive_count)
    LIST(LENGTH plugin_targets plugin_count)
    STRING(REPLACE ";" "," whole_archive_list "${whole_archive}")

    TARGET_LINK_LIBRARIES(${TARGET_TARGETNAME}
        "$<LINK_LIBRARY:WHOLE_ARCHIVE,${whole_archive_list}>"
        ${link_normally}
    )

    MESSAGE(STATUS
        "${TARGET_TARGETNAME}: ${whole_archive_count} of ${plugin_count} static plugins "
        "linked with whole-archive")
ENDFUNCTION(OSG_LINK_ALL_STATIC_PLUGINS)

# Compiled into every windowed executable in a static build. See the file itself for
# why this is a source file rather than a USE_GRAPHICSWINDOW() call per target.
SET(OSG_STATIC_GRAPHICSWINDOW_SRC "${CMAKE_CURRENT_LIST_DIR}/OsgStaticGraphicsWindow.cpp")


#################################################################################################################
# this is the macro for example and application setup
###########################################################

MACRO(SETUP_EXE IS_COMMANDLINE_APP)
    #MESSAGE("in -->SETUP_EXE<-- ${TARGET_NAME}-->${TARGET_SRC} <--> ${TARGET_H}<--")
    IF(GLCORE_FOUND)
        INCLUDE_DIRECTORIES( ${GLCORE_INCLUDE_DIR} )
    ENDIF()

    IF(NOT TARGET_TARGETNAME)
            SET(TARGET_TARGETNAME "${TARGET_DEFAULT_PREFIX}${TARGET_NAME}")
    ENDIF(NOT TARGET_TARGETNAME)
    IF(NOT TARGET_LABEL)
            SET(TARGET_LABEL "${TARGET_DEFAULT_LABEL_PREFIX} ${TARGET_NAME}")
    ENDIF(NOT TARGET_LABEL)

    # A static build has no windowing system unless something references the
    # osgViewer archive member that registers one, so compile in the linker anchor
    # that does it. Commandline targets are excluded because they never open a
    # window, and the anchor would drag the platform window implementation into
    # osgversion for nothing. See CMakeModules/OsgStaticGraphicsWindow.cpp.
    IF(NOT DYNAMIC_OPENSCENEGRAPH AND NOT ${IS_COMMANDLINE_APP})
        SET(TARGET_SRC ${TARGET_SRC} ${OSG_STATIC_GRAPHICSWINDOW_SRC})
    ENDIF()

    IF(${IS_COMMANDLINE_APP})

        ADD_EXECUTABLE(${TARGET_TARGETNAME} ${TARGET_SRC} ${TARGET_H})

    ELSE(${IS_COMMANDLINE_APP})

        IF(APPLE)
            # SET(MACOSX_BUNDLE_LONG_VERSION_STRING "${OPENSCENEGRAPH_MAJOR_VERSION}.${OPENSCENEGRAPH_MINOR_VERSION}.${OPENSCENEGRAPH_PATCH_VERSION}")
            # Short Version is the "marketing version". It is the version
            # the user sees in an information panel.
            SET(MACOSX_BUNDLE_SHORT_VERSION_STRING "${OPENSCENEGRAPH_MAJOR_VERSION}.${OPENSCENEGRAPH_MINOR_VERSION}.${OPENSCENEGRAPH_PATCH_VERSION}")
            # Bundle version is the version the OS looks at.
            SET(MACOSX_BUNDLE_BUNDLE_VERSION "${OPENSCENEGRAPH_MAJOR_VERSION}.${OPENSCENEGRAPH_MINOR_VERSION}.${OPENSCENEGRAPH_PATCH_VERSION}")
            SET(MACOSX_BUNDLE_GUI_IDENTIFIER "org.openscenegraph.${TARGET_TARGETNAME}" )
            # replace underscore by hyphen
            STRING(REGEX REPLACE "_" "-" MACOSX_BUNDLE_GUI_IDENTIFIER ${MACOSX_BUNDLE_GUI_IDENTIFIER})
            SET(MACOSX_BUNDLE_BUNDLE_NAME "${TARGET_NAME}" )
            # SET(MACOSX_BUNDLE_ICON_FILE "myicon.icns")
            # SET(MACOSX_BUNDLE_COPYRIGHT "")
            # SET(MACOSX_BUNDLE_INFO_STRING "Info string, localized?")
        ENDIF(APPLE)

        IF(WIN32)
            IF (REQUIRE_WINMAIN_FLAG)
                SET(PLATFORM_SPECIFIC_CONTROL WIN32)
            ENDIF(REQUIRE_WINMAIN_FLAG)
        ENDIF(WIN32)

        IF(APPLE)
            IF(OSG_BUILD_APPLICATION_BUNDLES)
                SET(PLATFORM_SPECIFIC_CONTROL MACOSX_BUNDLE)
            ENDIF(OSG_BUILD_APPLICATION_BUNDLES)
        ENDIF(APPLE)

        ADD_EXECUTABLE(${TARGET_TARGETNAME} ${PLATFORM_SPECIFIC_CONTROL} ${TARGET_SRC} ${TARGET_H})

    ENDIF(${IS_COMMANDLINE_APP})

    SET_TARGET_PROPERTIES(${TARGET_TARGETNAME} PROPERTIES PROJECT_LABEL "${TARGET_LABEL}")
    SET_TARGET_PROPERTIES(${TARGET_TARGETNAME} PROPERTIES OUTPUT_NAME ${TARGET_NAME})
    SET_TARGET_PROPERTIES(${TARGET_TARGETNAME} PROPERTIES DEBUG_OUTPUT_NAME "${TARGET_NAME}${CMAKE_DEBUG_POSTFIX}")
    SET_TARGET_PROPERTIES(${TARGET_TARGETNAME} PROPERTIES RELEASE_OUTPUT_NAME "${TARGET_NAME}${CMAKE_RELEASE_POSTFIX}")
    SET_TARGET_PROPERTIES(${TARGET_TARGETNAME} PROPERTIES RELWITHDEBINFO_OUTPUT_NAME "${TARGET_NAME}${CMAKE_RELWITHDEBINFO_POSTFIX}")
    SET_TARGET_PROPERTIES(${TARGET_TARGETNAME} PROPERTIES MINSIZEREL_OUTPUT_NAME "${TARGET_NAME}${CMAKE_MINSIZEREL_POSTFIX}")

    IF(MSVC_IDE AND OSG_MSVC_VERSIONED_DLL)
        SET_OUTPUT_DIR_PROPERTY_260(${TARGET_TARGETNAME} "")        # Ensure the /Debug /Release are removed
    ENDIF(MSVC_IDE AND OSG_MSVC_VERSIONED_DLL)

    IF(APPLE)
        SET_TARGET_PROPERTIES(${TARGET_TARGETNAME} PROPERTIES XCODE_ATTRIBUTE_WARNING_CFLAGS "")
        IF(OSG_BUILD_PLATFORM_IPHONE)
            SET_TARGET_PROPERTIES(${TARGET_TARGETNAME} PROPERTIES XCODE_ATTRIBUTE_ENABLE_BITCODE ${IPHONE_ENABLE_BITCODE})
        ENDIF()
    ENDIF()

    SETUP_LINK_LIBRARIES()

ENDMACRO(SETUP_EXE)

# Takes optional second argument (is_commandline_app?) in ARGV1
MACRO(SETUP_APPLICATION APPLICATION_NAME)

        SET(TARGET_NAME ${APPLICATION_NAME} )

        IF(${ARGC} GREATER 1)
            SET(IS_COMMANDLINE_APP ${ARGV1})
        ELSE(${ARGC} GREATER 1)
            SET(IS_COMMANDLINE_APP 0)
        ENDIF(${ARGC} GREATER 1)

        SETUP_EXE(${IS_COMMANDLINE_APP})

        SET_TARGET_PROPERTIES(${TARGET_TARGETNAME} PROPERTIES FOLDER "Applications")

        IF(APPLE)
            INSTALL(TARGETS ${TARGET_TARGETNAME} RUNTIME DESTINATION bin BUNDLE DESTINATION bin)
        ELSE(APPLE)
            INSTALL(TARGETS ${TARGET_TARGETNAME} RUNTIME DESTINATION bin COMPONENT openscenegraph  )
            IF(MSVC)
                INSTALL(FILES $<TARGET_PDB_FILE:${TARGET_TARGETNAME}> DESTINATION bin COMPONENT openscenegraph OPTIONAL)
            ENDIF(MSVC)
        ENDIF(APPLE)

ENDMACRO(SETUP_APPLICATION)

MACRO(SETUP_COMMANDLINE_APPLICATION APPLICATION_NAME)

    SETUP_APPLICATION(${APPLICATION_NAME} 1)

ENDMACRO(SETUP_COMMANDLINE_APPLICATION)

# Takes optional second argument (is_commandline_app?) in ARGV1
MACRO(SETUP_EXAMPLE EXAMPLE_NAME)

        SET(TARGET_NAME ${EXAMPLE_NAME} )

        IF(${ARGC} GREATER 1)
            SET(IS_COMMANDLINE_APP ${ARGV1})
        ELSE(${ARGC} GREATER 1)
            SET(IS_COMMANDLINE_APP 0)
        ENDIF(${ARGC} GREATER 1)

        SETUP_EXE(${IS_COMMANDLINE_APP})

        SET_TARGET_PROPERTIES(${TARGET_TARGETNAME} PROPERTIES FOLDER "Examples")

        IF(APPLE)
            INSTALL(TARGETS ${TARGET_TARGETNAME} RUNTIME DESTINATION share/OpenSceneGraph/bin BUNDLE DESTINATION share/OpenSceneGraph/bin )
        ELSE(APPLE)
            INSTALL(TARGETS ${TARGET_TARGETNAME} RUNTIME DESTINATION share/OpenSceneGraph/bin COMPONENT openscenegraph-examples )
            IF(MSVC)
                INSTALL(FILES $<TARGET_PDB_FILE:${TARGET_TARGETNAME}> DESTINATION share/OpenSceneGraph/bin COMPONENT openscenegraph-examples OPTIONAL)
            ENDIF(MSVC)
        ENDIF(APPLE)

ENDMACRO(SETUP_EXAMPLE)


MACRO(SETUP_COMMANDLINE_EXAMPLE EXAMPLE_NAME)

    SETUP_EXAMPLE(${EXAMPLE_NAME} 1)

ENDMACRO(SETUP_COMMANDLINE_EXAMPLE)

# warning flags that third-party headers trip over (gdal, exr, fbx, pdf, gstreamer).
MACRO(REMOVE_CXX_FLAG flag)
  STRING(REPLACE "${flag}" "" CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS}")
ENDMACRO()

# Takes two optional arguments -- osg prefix and osg version
MACRO(HANDLE_MSVC_DLL)
        # The dll are versioned by prefixing the name with osg${OPENSCENEGRAPH_SOVERSION}-.
        # LIB_PREFIX: use "osg" by default, else whatever we've been given.
        IF(${ARGC} GREATER 0)
                SET(LIB_PREFIX ${ARGV0})
        ELSE(${ARGC} GREATER 0)
                SET(LIB_PREFIX osg)
        ENDIF(${ARGC} GREATER 0)

        # LIB_SOVERSION: use OSG's soversion by default, else whatever we've been given
        IF(${ARGC} GREATER 1)
                SET(LIB_SOVERSION ${ARGV1})
        ELSE(${ARGC} GREATER 1)
                SET(LIB_SOVERSION ${OPENSCENEGRAPH_SOVERSION})
        ENDIF(${ARGC} GREATER 1)

        SET_OUTPUT_DIR_PROPERTY_260(${LIB_NAME} "")        # Ensure the /Debug /Release are removed
        SET_TARGET_PROPERTIES(${LIB_NAME} PROPERTIES PREFIX "${LIB_PREFIX}${LIB_SOVERSION}-")
ENDMACRO(HANDLE_MSVC_DLL)
