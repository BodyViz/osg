IF(APPLE)
    IF(NOT OSG_BUILD_PLATFORM_IPHONE)
        SET(CMAKE_MODULE_LINKER_FLAGS "${CMAKE_MODULE_LINKER_FLAGS} -Wl,-dylib_file,/System/Library/Frameworks/OpenGL.framework/Versions/A/Libraries/libGL.dylib:/System/Library/Frameworks/OpenGL.framework/Versions/A/Libraries/libGL.dylib")
    ENDIF()
ENDIF()

SET(TARGET_SRC
    FreeTypeFont.cpp
    FreeTypeLibrary.cpp
    ReaderWriterFreeType.cpp
)

SET(TARGET_H
    FreeTypeFont.h
    FreeTypeLibrary.h
)

SET(TARGET_ADDED_LIBRARIES osgText )

SET(TARGET_EXTERNAL_LIBRARIES Freetype::Freetype)
OSG_ADD_PACKAGE_DEPENDENCY(Freetype)

IF(ZLIB_FOUND)
    SET(TARGET_EXTERNAL_LIBRARIES ${TARGET_EXTERNAL_LIBRARIES} ZLIB::ZLIB)
    OSG_ADD_PACKAGE_DEPENDENCY(ZLIB)
ENDIF()

#### end var setup  ###
SETUP_PLUGIN(freetype)
