SET(TARGET_SRC osgfilecache.cpp )
SET(TARGET_ADDED_LIBRARIES osgTerrain )

SETUP_APPLICATION(osgfilecache)

# Static builds need every format plugin linked in and referenced, or the linker
# discards the archive members that register them. See OSG_LINK_ALL_STATIC_PLUGINS
# in CMakeModules/OsgMacroUtils.cmake.
OSG_LINK_ALL_STATIC_PLUGINS(${TARGET_TARGETNAME})
