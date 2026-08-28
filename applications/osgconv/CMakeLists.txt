SET(TARGET_SRC
    OrientationConverter.cpp
    osgconv.cpp
)
SET(TARGET_H
    OrientationConverter.h
)

SETUP_APPLICATION(osgconv)

# A static osgconv has to have every format plugin linked in and referenced, or the
# linker discards the archive members that do the registering and it can convert
# nothing. See OSG_LINK_ALL_STATIC_PLUGINS in CMakeModules/OsgMacroUtils.cmake for
# how that works and what the three excluded archives cost.
OSG_LINK_ALL_STATIC_PLUGINS(${TARGET_TARGETNAME})
