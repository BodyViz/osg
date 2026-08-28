# This file should only be included when WIN32

SET(LIB_NAME OpenThreads)
SET(LIB_PUBLIC_HEADERS ${OpenThreads_PUBLIC_HEADERS})

ADD_DEFINITIONS(-DWIN32_LEAN_AND_MEAN)
IF(NOT OSG_DETERMINE_WIN_VERSION)
    ADD_DEFINITIONS(-D_WIN32_WINNT=0x0400)
ENDIF(NOT OSG_DETERMINE_WIN_VERSION)
SOURCE_GROUP("Header Files" FILES ${LIB_PUBLIC_HEADERS})
SET_SOURCE_FILES_PROPERTIES(${LIB_PUBLIC_HEADERS} PROPERTIES HEADER_FILE_ONLY ON)

ADD_LIBRARY(${LIB_NAME}
    ${OPENTHREADS_USER_DEFINED_DYNAMIC_OR_STATIC}
    ${LIB_PUBLIC_HEADERS}
    HandleHolder.h
    Win32BarrierPrivateData.h
    WIN32Condition.cpp
    Win32ConditionPrivateData.h
    Win32Mutex.cpp
    Win32MutexPrivateData.h
    Win32Thread.cpp
    Win32ThreadBarrier.cpp
    Win32ThreadPrivateData.h
    ../common/Version.cpp
    ../common/Atomic.cpp
    ${OPENTHREADS_VERSIONINFO_RC}
)

TARGET_INCLUDE_DIRECTORIES(${LIB_NAME}
    PUBLIC
        $<BUILD_INTERFACE:${PROJECT_SOURCE_DIR}/include>
        $<BUILD_INTERFACE:${PROJECT_BINARY_DIR}/include>
        $<INSTALL_INTERFACE:${INSTALL_INCDIR}>
)

SET_TARGET_PROPERTIES(${LIB_NAME} PROPERTIES FOLDER "OSG Core")
IF(OPENTHREADS_SONAMES)
  SET_TARGET_PROPERTIES(${LIB_NAME} PROPERTIES VERSION ${OPENTHREADS_VERSION} SOVERSION ${OPENTHREADS_SOVERSION})
ENDIF()

# Since we're building different platforms binaries in 
# their respective directories, we need to set the 
# link directory so it can find this location.
LINK_DIRECTORIES(
    ${CMAKE_CURRENT_BINARY_DIR}
)

IF(MSVC AND OSG_MSVC_VERSIONED_DLL)
    HANDLE_MSVC_DLL(ot ${OPENTHREADS_SOVERSION})
ENDIF()

# Same single export set as the OSG libraries -- see CMakeModules/ModuleInstall.cmake.
INSTALL(
    TARGETS OpenThreads
    EXPORT  OpenSceneGraphTargets
    ARCHIVE DESTINATION ${INSTALL_ARCHIVEDIR} COMPONENT libopenthreads-dev
    LIBRARY DESTINATION ${INSTALL_LIBDIR} COMPONENT libopenthreads
    RUNTIME DESTINATION ${INSTALL_BINDIR} COMPONENT libopenthreads
)

INSTALL(
    FILES ${OpenThreads_PUBLIC_HEADERS}
    DESTINATION ${INSTALL_INCDIR}/OpenThreads
    COMPONENT libopenthreads-dev
)

IF(MSVC AND DYNAMIC_OPENTHREADS)
        # $<TARGET_PDB_FILE:> knows where the linker actually put the pdb, for
        # every generator and configuration. OPTIONAL because a configuration
        # built without debug info produces none.
    INSTALL(FILES $<TARGET_PDB_FILE:${LIB_NAME}> DESTINATION ${INSTALL_BINDIR} COMPONENT libopenthreads OPTIONAL)
ENDIF(MSVC AND DYNAMIC_OPENTHREADS)

#commented out# INCLUDE(ModuleInstall OPTIONAL)
