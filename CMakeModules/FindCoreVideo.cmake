# Locate Apple CoreVideo (next-generation QuickTime)
# This module defines
# COREVIDEO_LIBRARY
# COREVIDEO_FOUND, if false, do not try to link to gdal 
# COREVIDEO_INCLUDE_DIR, where to find the headers
#
# $COREVIDEO_DIR is an environment variable that would
# correspond to the ./configure --prefix=$COREVIDEO_DIR
#
# Created by Eric Wing. 

# CoreVideo on OS X looks different than CoreVideo for Windows,
# so I am going to case the two.

IF(APPLE)
  FIND_PATH(COREVIDEO_INCLUDE_DIR CoreVideo/CoreVideo.h)
  FIND_LIBRARY(COREVIDEO_LIBRARY CoreVideo)
ENDIF()


SET(COREVIDEO_FOUND "NO")
IF(COREVIDEO_LIBRARY AND COREVIDEO_INCLUDE_DIR)
  SET(COREVIDEO_FOUND "YES")
ENDIF()

# Link the framework by flag rather than by FIND_LIBRARY result. The probe above
# stays as the existence test, but its value is an absolute path inside the
# active SDK, and install(EXPORT) copies raw paths into the exported link
# interface verbatim -- which would pin the installed package to one Xcode on one
# machine. See the same treatment of COCOA_LIBRARY in the root CMakeLists.
IF(COREVIDEO_FOUND)
    SET(COREVIDEO_LIBRARY "-framework CoreVideo")
ENDIF()


