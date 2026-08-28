#---------------------------------------------------
# OSG CMAKE SUPPORT
# (C) by Michael Wagner, mtw@shared-reality.com 2005
# (C) Eric Wing, Luigi Calori and Robert Osfield 2006-2007
#---------------------------------------------------

PROJECT(OSG_PLUGINS_MASTER)

IF(NOT DYNAMIC_OPENSCENEGRAPH)
    ADD_DEFINITIONS(-DOSG_LIBRARY_STATIC)
ENDIF()

SET(CMAKE_SHARED_MODULE_PREFIX ${OSG_PLUGIN_PREFIX})

SET(TARGET_DEFAULT_PREFIX "osgdb_deprecated_")
SET(TARGET_DEFAULT_LABEL_PREFIX "Plugins osg deprecated")
SET(TARGET_COMMON_LIBRARIES
    OpenThreads
    osg
    osgDB
    osgUtil
)

ADD_SUBDIRECTORY(osg)
ADD_SUBDIRECTORY(osgParticle)
ADD_SUBDIRECTORY(osgAnimation)
ADD_SUBDIRECTORY(osgFX)
ADD_SUBDIRECTORY(osgSim)
ADD_SUBDIRECTORY(osgText)
ADD_SUBDIRECTORY(osgViewer)
ADD_SUBDIRECTORY(osgShadow)
ADD_SUBDIRECTORY(osgTerrain)
ADD_SUBDIRECTORY(osgVolume)
ADD_SUBDIRECTORY(osgWidget)

