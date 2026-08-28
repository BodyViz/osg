# Locate Apple QuartzCore
# This module defines
# QUARTZCORE_LIBRARY
# QUARTZCORE_FOUND, if false, do not try to link to QUARTZCORE 
# QUARTZCORE_INCLUDE_DIR, where to find the headers
#
# $QUARTZCORE_DIR is an environment variable that would
# correspond to the ./configure --prefix=$QUARTZCORE_DIR
#
# Created by Stephan Maximilian Huber. 


IF(APPLE)
  FIND_PATH(QUARTZCORE_INCLUDE_DIR QuartzCore/QuartzCore.h)
  FIND_LIBRARY(QUARTZCORE_LIBRARY QuartzCore)
ENDIF()


SET(QUARTZCORE_FOUND "NO")
IF(QUARTZCORE_LIBRARY AND QUARTZCORE_INCLUDE_DIR)
  SET(QUARTZCORE_FOUND "YES")
ENDIF()

# Link the framework by flag rather than by FIND_LIBRARY result. The probe above
# stays as the existence test, but its value is an absolute path inside the
# active SDK, and install(EXPORT) copies raw paths into the exported link
# interface verbatim -- which would pin the installed package to one Xcode on one
# machine. See the same treatment of COCOA_LIBRARY in the root CMakeLists.
IF(QUARTZCORE_FOUND)
    SET(QUARTZCORE_LIBRARY "-framework QuartzCore")
ENDIF()


