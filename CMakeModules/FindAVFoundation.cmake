# Locate Apple AVFoundation (next-generation QTKit)
# This module defines
# AV_FOUNDATION_LIBRARY
# AV_FOUNDATION_FOUND, if false, do not try to link to gdal
#
# $AV_FOUNDATION_DIR is an environment variable that would
# correspond to the ./configure --prefix=$AV_FOUNDATION_DIR
#
# Created by Stephan Maximilian Huber


IF(APPLE)
  FIND_LIBRARY(AV_FOUNDATION_LIBRARY AVFoundation)
ENDIF()

SET(AV_FOUNDATION_FOUND "NO")
IF(AV_FOUNDATION_LIBRARY)
  SET(AV_FOUNDATION_FOUND "YES")
ENDIF()


IF(OSG_BUILD_PLATFORM_IPHONE OR OSG_BUILD_PLATFORM_IPHONE_SIMULATOR)
    # AVFoundation exists ON iOS, too -- good support for SDK 6.0 and greater
    IF(${IPHONE_SDKVER} LESS "6.0")
        SET(AV_FOUNDATION_FOUND "NO")
    ELSE()
        SET(AV_FOUNDATION_FOUND "YES")
    ENDIF()
ENDIF()

# Link the framework by flag rather than by FIND_LIBRARY result. The probe above
# stays as the existence test, but its value is an absolute path inside the
# active SDK, and install(EXPORT) copies raw paths into the exported link
# interface verbatim -- which would pin the installed package to one Xcode on one
# machine. See the same treatment of COCOA_LIBRARY in the root CMakeLists.
IF(AV_FOUNDATION_FOUND)
    SET(AV_FOUNDATION_LIBRARY "-framework AVFoundation")
ENDIF()
