# Package consumer test

Verifies an **installed** OpenSceneGraph package from outside the build tree, the
way a real application would use it. This is the acceptance test for the
packaging work: `find_package(OpenSceneGraph CONFIG)`, the `osg3::` targets,
plugin registration, and reading and writing files.

It never opens a window, so it runs anywhere, and it exits non-zero on the first
thing that is wrong.

**This is deliberately not part of the OpenSceneGraph build.**
`tests/CMakeLists.txt` does not `add_subdirectory()` it. Configuring it
separately against an install prefix is the whole point — wiring it into the main
build would test the build tree and prove nothing about the installed package.

## Running it

Two things go on `CMAKE_PREFIX_PATH`: the OpenSceneGraph install prefix, **and**
the third-party dependency prefixes. The second part is not optional — the
package config calls `find_dependency()` for PNG, GIFLIB, Jasper and the rest, and
those have to be findable on the consumer's machine. That is the cost of the
package being relocatable rather than having paths baked into it.

### Windows

`cd` into **this directory** first — `tests/packageconsumer`, not `tests`. The
parent `tests/` is part of the OpenSceneGraph build and has no `project()` of its
own; configuring it directly now fails with a message saying so.

**PowerShell.** No variables, one line, so there is no shell-syntax trap:

```powershell
cmake -S . -B build -G "Visual Studio 17 2022" -A x64 -DCMAKE_PREFIX_PATH="C:/dev/libs/vs_2022/osg-3.7.1;C:/dev/libs/vs_2022/osg-3rdparty/freetype-2.14.3;C:/dev/libs/vs_2022/osg-3rdparty/libpng-1.6.58;C:/dev/libs/vs_2022/osg-3rdparty/libjpeg-turbo-3.2.0;C:/dev/libs/vs_2022/osg-3rdparty/tiff-4.7.2;C:/dev/libs/vs_2022/osg-3rdparty/giflib-6.1.3;C:/dev/libs/vs_2022/osg-3rdparty/jasper-4.2.9;C:/dev/libs/vs_2022/osg-3rdparty/zlib-1.3.2;C:/dev/libs/vs_2022/osg-3rdparty/curl-8.21.0;C:/dev/libs/vs_2022/dcmtk-3.7.0"

cmake --build build --config Release
cmake --build build --config Debug
ctest --test-dir build -C Release
ctest --test-dir build -C Debug
```

If you would rather use a variable, PowerShell spells it `$DEPS =
"C:/dev/libs/vs_2022/osg-3rdparty"` and interpolates it as `$DEPS/...` inside a
double-quoted string. `set VAR=x` and `%VAR%` are cmd.exe syntax and expand to
nothing in PowerShell, which silently produces a `CMAKE_PREFIX_PATH` full of
literal percent signs.

Both configurations matter and test different things: the Debug run is the one
that would catch a `/MD` versus `/MDd` mismatch in a dependency, since that stays
invisible until something links it.

### macOS

```
OSG=$HOME/Libraries/osg-3.7.1
DEPS=$HOME/Libraries/osg-3rdparty

cmake -S . -B build-release -G Ninja -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_OSX_ARCHITECTURES=x86_64 -DCMAKE_OSX_DEPLOYMENT_TARGET=13.0 \
  -DCMAKE_PREFIX_PATH="$OSG;$DEPS/freetype-2.14.3;$DEPS/libpng-1.6.58;$DEPS/libjpeg-turbo-3.2.0;$DEPS/tiff-4.7.2;$DEPS/giflib-6.1.3;$DEPS/jasper-4.2.9;$HOME/Code/Libraries/macos/dcmtk-3.7.0"

cmake --build build-release && ctest --test-dir build-release
```

## Reading the output

Configure time tells you what the package contains:

```
-- Found OpenSceneGraph 3.7.1
-- Static package: linking plugins explicitly
--   plugins found:   osgdb_png;osgdb_jpeg;osgdb_tiff;osgdb_gif;osgdb_jp2;osgdb_freetype
```

A plugin listed as absent means the install does not have it — because its
dependency was not found when OpenSceneGraph was built. That is information, not
a failure; the test simply skips what is not there.

Run time should end with:

```
PACKAGE CONSUMER OK (0 failure(s))
```

## What each check is for

- **Three-way version agreement** — installed headers, the linked library, and
  the version the package config declared. Catches a stale header left behind by
  an older install.
- **`OSG_LIBRARY_STATIC`** — reported, not asserted, because it should arrive
  from the imported target rather than from a header. On Windows its absence in a
  static build means `__declspec(dllimport)` and a link failure.
- **Registration per extension** — the one most likely to be silently broken.
  `USE_OSGPLUGIN` needs the name `REGISTER_OSGPLUGIN` used, which differs from
  the target name for eleven plugins: `.osgt` is registered as `osg2` but built
  as `osgdb_osg`. Linking the right archive under the wrong name links cleanly
  and then fails at runtime.
- **Round-trips** — that the plugins actually work end to end, not merely that
  they registered.

## Static and shared

Whether the package is static is discovered, not assumed: plugins are only
exported as linkable targets by a static build. In a shared build they are
`MODULE` libraries loaded from disk, so the plugin block drops out of both the
CMake and the C++ and the test still runs. That makes this usable for verifying a
shared build too.
