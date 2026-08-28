/* Verifies an INSTALLED OpenSceneGraph package from outside the build tree.
 *
 * This is the acceptance test for the whole packaging effort: it proves that
 * find_package(OpenSceneGraph CONFIG) works, that osg3:: targets carry what a
 * consumer needs, that the plugins in the package actually register themselves,
 * and that reading and writing files works from a program that knows nothing
 * about OpenSceneGraph's own build.
 *
 * It deliberately never opens a window, so it runs anywhere, and it exits
 * non-zero on the first thing that is wrong.
 */

#include <osg/Geode>
#include <osg/Geometry>
#include <osg/Group>
#include <osg/Image>
#include <osg/MatrixTransform>
#include <osg/Version>
#include <osgDB/ReadFile>
#include <osgDB/Registry>
#include <osgDB/WriteFile>

#include <cstring>
#include <iostream>
#include <string>
#include <vector>

// CONSUMER_STATIC_PLUGINS is defined by CMakeLists.txt when the package turned
// out to be a static one -- detected by whether it exports plugin targets at all.
// In a shared package the plugins are loaded from disk and referencing osgdb_*
// here would be an undefined symbol, so the whole block has to go.
#ifdef CONSUMER_STATIC_PLUGINS
    USE_OSGPLUGIN(osg2)                     // .osgt .osgb .osgx -- not "osg"
    USE_SERIALIZER_WRAPPER_LIBRARY(osg)
#   ifdef HAVE_PNG
        USE_OSGPLUGIN(png)
#   endif
#   ifdef HAVE_JPEG
        USE_OSGPLUGIN(jpeg)
#   endif
#   ifdef HAVE_TIFF
        USE_OSGPLUGIN(tiff)
#   endif
#   ifdef HAVE_GIF
        USE_OSGPLUGIN(gif)
#   endif
#   ifdef HAVE_JP2
        USE_OSGPLUGIN(jp2)
#   endif
#   ifdef HAVE_FREETYPE
        USE_OSGPLUGIN(freetype)
#   endif
#endif

// Two levels, so the macro argument is expanded before being stringified.
#define OSGPC_STR2(x) #x
#define OSGPC_STR(x) OSGPC_STR2(x)

namespace
{
int failures = 0;

void check(bool ok, const std::string& what)
{
    std::cout << (ok ? "  ok    " : "  FAIL  ") << what << "\n";
    if (!ok) ++failures;
}

// Registration is the part most likely to be silently broken, because the name
// USE_OSGPLUGIN needs is the one REGISTER_OSGPLUGIN used, not the target name.
void checkRegistered(const char* ext)
{
    check(osgDB::Registry::instance()->getReaderWriterForExtension(ext) != nullptr,
          std::string("a ReaderWriter is registered for .") + ext);
}

osg::ref_ptr<osg::Node> makeScene()
{
    osg::ref_ptr<osg::Vec3Array> verts = new osg::Vec3Array;
    verts->push_back(osg::Vec3(0, 0, 0));
    verts->push_back(osg::Vec3(1, 0, 0));
    verts->push_back(osg::Vec3(0, 1, 0));

    osg::ref_ptr<osg::Geometry> geom = new osg::Geometry;
    geom->setVertexArray(verts.get());
    geom->addPrimitiveSet(new osg::DrawArrays(GL_TRIANGLES, 0, 3));

    osg::ref_ptr<osg::Geode> geode = new osg::Geode;
    geode->addDrawable(geom.get());

    osg::ref_ptr<osg::MatrixTransform> xform = new osg::MatrixTransform;
    xform->setMatrix(osg::Matrix::translate(1.0, 2.0, 3.0));
    xform->addChild(geode.get());

    osg::ref_ptr<osg::Group> root = new osg::Group;
    root->setName("consumer_root");
    root->addChild(xform.get());
    return root;
}

void roundTripNode(const std::string& ext)
{
    const std::string path = "consumer." + ext;
    osg::ref_ptr<osg::Node> scene = makeScene();
    if (!osgDB::writeNodeFile(*scene, path))       { check(false, "write " + path); return; }
    if (!osgDB::readNodeFile(path))                { check(false, "read back " + path); return; }
    check(true, "round-tripped " + path);
}

void roundTripImage(const std::string& ext)
{
    const std::string path = "consumer." + ext;
    osg::ref_ptr<osg::Image> image = new osg::Image;
    image->allocateImage(8, 8, 1, GL_RGB, GL_UNSIGNED_BYTE);
    std::memset(image->data(), 0x40, image->getTotalSizeInBytes());
    if (!osgDB::writeImageFile(*image, path))      { check(false, "write " + path); return; }
    if (!osgDB::readImageFile(path))               { check(false, "read back " + path); return; }
    check(true, "round-tripped " + path);
}
} // namespace

int main()
{
    std::cout << "OpenSceneGraph package consumer test\n"
              << "  linked against OSG " << osgGetVersion()
              << ", SO version " << osgGetSOVersion() << "\n";

#ifdef OSG_LIBRARY_STATIC
    std::cout << "  OSG_LIBRARY_STATIC is defined (arrived from the imported target)\n";
#else
    std::cout << "  OSG_LIBRARY_STATIC is not defined -- treating this as a shared package\n";
#endif
    std::cout << "\n";

    // Three sources have to agree, and each can go stale independently: the
    // installed headers, the library that was actually linked, and the version
    // the package config declared. A stale header left over from an older
    // install is exactly the kind of thing this catches.
    const std::string headerVersion =
        OSGPC_STR(OPENSCENEGRAPH_MAJOR_VERSION) "."
        OSGPC_STR(OPENSCENEGRAPH_MINOR_VERSION) "."
        OSGPC_STR(OPENSCENEGRAPH_PATCH_VERSION);
    const std::string runtimeVersion = osgGetVersion();

    check(runtimeVersion.rfind(headerVersion, 0) == 0,
          "installed headers (" + headerVersion + ") match the linked library ("
          + runtimeVersion + ")");
    check(headerVersion == std::string(CONSUMER_EXPECTED_VERSION),
          "headers match the version the package config declared ("
          CONSUMER_EXPECTED_VERSION ")");

    checkRegistered("osgt");
    checkRegistered("osgb");
#ifdef HAVE_PNG
    checkRegistered("png");
#endif
#ifdef HAVE_JPEG
    checkRegistered("jpg");
#endif
#ifdef HAVE_TIFF
    checkRegistered("tif");
#endif
#ifdef HAVE_GIF
    checkRegistered("gif");
#endif
#ifdef HAVE_JP2
    checkRegistered("jp2");
#endif
#ifdef HAVE_FREETYPE
    checkRegistered("ttf");
#endif

    roundTripNode("osgt");
    roundTripNode("osgb");
#ifdef HAVE_PNG
    roundTripImage("png");
#endif
#ifdef HAVE_TIFF
    roundTripImage("tif");
#endif
#ifdef HAVE_JP2
    roundTripImage("jp2");
#endif

    std::cout << "\n" << (failures ? "PACKAGE CONSUMER FAILED" : "PACKAGE CONSUMER OK")
              << " (" << failures << " failure(s))\n";
    return failures ? 1 : 0;
}
