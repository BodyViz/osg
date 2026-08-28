SET(TARGET_SRC
    osgdeferred.cpp
)

SET(TARGET_H
    osgdeferred.h
)

SET(TARGET_ADDED_LIBRARIES osgShadow)

# png and jpeg are optional, and are gated on both sides the way osgstaticviewer
# gates freetype, so the example still links on a build without them.
IF(NOT DYNAMIC_OPENSCENEGRAPH)
    SET(TARGET_ADDED_LIBRARIES ${TARGET_ADDED_LIBRARIES}
        osgdb_osg
        osgdb_glsl
        osgdb_serializers_osg
    )
    IF(PNG_FOUND)
        ADD_DEFINITIONS(-DUSE_PNG)
        SET(TARGET_ADDED_LIBRARIES ${TARGET_ADDED_LIBRARIES} osgdb_png)
    ENDIF()
    IF(JPEG_FOUND)
        ADD_DEFINITIONS(-DUSE_JPEG)
        SET(TARGET_ADDED_LIBRARIES ${TARGET_ADDED_LIBRARIES} osgdb_jpeg)
    ENDIF()
ENDIF()

#### end var setup  ###
SETUP_EXAMPLE(osgdeferred)
