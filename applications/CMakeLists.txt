PROJECT(OSG_APPLICATIONS)

SET(OSGCORE_BUNDLED TRUE)

IF(NOT OSGCORE_BUNDLED)
    FIND_PACKAGE(OSGCORE)
    IF(OSGCORE_FOUND)
        INCLUDE(${OSGCORE_USE_FILE})
    ELSE()
        MESSAGE(ERROR "OSGCORE neeeded but NOT FOUND")
    ENDIF()
    SET(CMAKE_MODULE_PATH  ${PROJECT_SOURCE_DIR}/../../Macros)
ENDIF()
SET(OPENSCENEGRAPH_APPLICATION_DIR ${PROJECT_SOURCE_DIR})


SET(TARGET_DEFAULT_PREFIX "application_")
SET(TARGET_DEFAULT_LABEL_PREFIX "Applications")
SET(TARGET_COMMON_LIBRARIES
  OpenThreads
	osg
	osgDB
	osgUtil
	osgGA
	osgViewer
	osgText
)

IF(NOT DYNAMIC_OPENSCENEGRAPH)
    # need to define this on win32 or linker cries about _declspecs
    ADD_DEFINITIONS(-DOSG_LIBRARY_STATIC)
ENDIF()

# The four that read files each call OSG_LINK_ALL_STATIC_PLUGINS,
# which is what gives a static build any format support
# at all -- see CMakeModules/OsgMacroUtils.cmake.
#
# present3D stays out, as it was upstream: it needs poppler and ffmpeg, and nothing
# in this tree builds either.
ADD_SUBDIRECTORY(osgversion)
ADD_SUBDIRECTORY(osgviewer)
ADD_SUBDIRECTORY(osgarchive)
ADD_SUBDIRECTORY(osgconv)
ADD_SUBDIRECTORY(osgfilecache)
# ADD_SUBDIRECTORY(present3D)
