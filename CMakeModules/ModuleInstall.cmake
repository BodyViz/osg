# INSTALL and SOURCE_GROUP commands for OSG/OT/Producer Modules

# Required Vars:
# ${LIB_NAME}
# ${TARGET_H}

SET(HEADERS_GROUP "Header Files")

SOURCE_GROUP(
    ${HEADERS_GROUP}
    FILES ${TARGET_H}
)

IF(MSVC AND OSG_MSVC_VERSIONED_DLL)
    HANDLE_MSVC_DLL()
ENDIF()


# One export set for the whole project; the root CMakeLists turns it into
# OpenSceneGraphTargets.cmake. Nothing here needs to describe the dependencies
# between OSG libraries -- install(EXPORT) records them from the actual link
# graph.
INSTALL(
    TARGETS ${LIB_NAME}
    EXPORT  OpenSceneGraphTargets
    RUNTIME DESTINATION ${INSTALL_BINDIR} COMPONENT libopenscenegraph
    LIBRARY DESTINATION ${INSTALL_LIBDIR} COMPONENT libopenscenegraph
    ARCHIVE DESTINATION ${INSTALL_ARCHIVEDIR} COMPONENT libopenscenegraph-dev
)

IF(MSVC AND DYNAMIC_OPENSCENEGRAPH)
        # $<TARGET_PDB_FILE:> knows where the linker actually put the pdb, for
        # every generator and configuration. OPTIONAL because a configuration
        # built without debug info produces none.
    INSTALL(FILES $<TARGET_PDB_FILE:${LIB_NAME}> DESTINATION ${INSTALL_BINDIR} COMPONENT libopenscenegraph OPTIONAL)
ENDIF(MSVC AND DYNAMIC_OPENSCENEGRAPH)

IF(NOT OSG_COMPILE_FRAMEWORKS)
    INSTALL (
        FILES        ${TARGET_H}
        DESTINATION ${INSTALL_INCDIR}/${LIB_NAME}
        COMPONENT libopenscenegraph-dev
    )
ELSE()
    SET_TARGET_PROPERTIES(${LIB_NAME} PROPERTIES
         FRAMEWORK TRUE
         FRAMEWORK_VERSION ${OPENSCENEGRAPH_SOVERSION}
         PUBLIC_HEADER  "${TARGET_H}"
         INSTALL_NAME_DIR "${OSG_COMPILE_FRAMEWORKS_INSTALL_NAME_DIR}"
         BUILD_WITH_INSTALL_RPATH TRUE
         INSTALL_RPATH "${OSG_COMPILE_FRAMEWORKS_INSTALL_NAME_DIR}"
    )
    # MESSAGE("${OSG_COMPILE_FRAMEWORKS_INSTALL_NAME_DIR}")
ENDIF()


# Install pkgconfig file for this component
SET(COMPONENT_PKGCONFIG_REQUIRES)
FOREACH(component ${TARGET_LIBRARIES})
    IF(${component} STREQUAL "OpenThreads")
        # Skip OpenThreads because that's handled separately
        CONTINUE()
    ENDIF()
    SET(COMPONENT_PKGCONFIG_REQUIRES "${COMPONENT_PKGCONFIG_REQUIRES} openscenegraph-${component}")
ENDFOREACH()

SET(PKGCONFIG_INPUT_FILE  "${PROJECT_SOURCE_DIR}/packaging/pkgconfig/component.pc.in")
SET(PKGCONFIG_OUTPUT_FILE "${PROJECT_BINARY_DIR}/packaging/pkgconfig/openscenegraph-${LIB_NAME}.pc")
CONFIGURE_FILE(
    ${PKGCONFIG_INPUT_FILE}
    ${PKGCONFIG_OUTPUT_FILE}
    @ONLY
)
INSTALL(
    FILES ${PKGCONFIG_OUTPUT_FILE}
    DESTINATION ${INSTALL_PKGCONFIGDIR}
    COMPONENT libopenscenegraph-dev
)
