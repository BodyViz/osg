// Linker anchor that gives a static build its windowing system.
//
// Nothing pulls a GraphicsWindow implementation out of libosgViewer unless a
// symbol in it is referenced, and in a static build the linker keeps only the
// archive members it needs. graphicswindow_<Platform>() exists purely to be that
// reference: it has an empty body (see src/osgViewer/GraphicsWindowWin32.cpp) and
// sits in the same translation unit as the implementation's registration proxy, so
// declaring it is enough to make the linker keep that member and let the proxy
// register itself.
//
// Added to TARGET_SRC by SETUP_EXE in OsgMacroUtils.cmake, for static builds of
// non-commandline targets only.

#include <osgViewer/GraphicsWindow>

USE_GRAPHICSWINDOW()
