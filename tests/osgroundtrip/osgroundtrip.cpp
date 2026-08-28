/* OpenSceneGraph round-trip test.
 *
 * Writes a known scene or image through one plugin, reads it back and checks
 * what survived. The point is not format fidelity -- it is that the plugin is
 * registered and its read and write paths both work.
 *
 * That matters most for static builds. USE_OSGPLUGIN(x) references osgdb_x,
 * where x is the name given to REGISTER_OSGPLUGIN in the plugin's source, while
 * the CMake target is named after the plugin's directory. For eleven plugins
 * those differ -- .osgt/.osgb/.osgx are registered as "osg2" but built as
 * osgdb_osg, for instance -- so linking the right archive and naming the wrong
 * registration gives a clean link and a silent runtime failure. Nothing but an
 * actual read/write cycle catches that.
 *
 * Usage:  osgroundtrip <node|image|imagef> <extension> <exact|structural>
 *
 *   imagef  same as image but with a floating point source image, for formats
 *           like .hdr whose writer rejects 8-bit data outright.
 *
 *   structural  the write produced a non-empty file and the read produced
 *               something usable. All a lossy or hierarchy-flattening format
 *               can promise.
 *   exact       additionally, the contents match what went in.
 */

#include <osg/Geode>
#include <osg/Geometry>
#include <osg/Group>
#include <osg/Image>
#include <osg/MatrixTransform>
#include <osg/Material>
#include <osg/Notify>

#include <osgDB/ReadFile>
#include <osgDB/Registry>
#include <osgDB/WriteFile>

#include <cstring>
#include <fstream>
#include <iostream>
#include <string>

// In a static build the plugins have to be linked in and named explicitly; in a
// shared build they are MODULEs that are not linked at all, so referencing
// osgdb_* here would be an undefined symbol. OSG_LIBRARY_STATIC arrives as a
// usage requirement of the osg target. The HAVE_* defines come from
// tests/CMakeLists.txt, which sets one per plugin target that actually exists,
// so a plugin skipped for a missing dependency drops out of both the link and
// the test list together.
#ifdef OSG_LIBRARY_STATIC

#ifdef HAVE_OSGDB_OSG
    USE_OSGPLUGIN(osg2)                 // .osgt .osgb .osgx -- note: not "osg"
    USE_SERIALIZER_WRAPPER_LIBRARY(osg)
#endif
#ifdef HAVE_OSGDB_IVE
    USE_OSGPLUGIN(ive)
#endif
#ifdef HAVE_OSGDB_OBJ
    USE_OSGPLUGIN(obj)
#endif
#ifdef HAVE_OSGDB_STL
    USE_OSGPLUGIN(stl)
#endif
#ifdef HAVE_OSGDB_DXF
    USE_OSGPLUGIN(dxf)
#endif
#ifdef HAVE_OSGDB_3DS
    USE_OSGPLUGIN(3ds)
#endif
#ifdef HAVE_OSGDB_AC
    USE_OSGPLUGIN(ac)
#endif

#ifdef HAVE_OSGDB_BMP
    USE_OSGPLUGIN(bmp)
#endif
#ifdef HAVE_OSGDB_DDS
    USE_OSGPLUGIN(dds)
#endif
#ifdef HAVE_OSGDB_HDR
    USE_OSGPLUGIN(hdr)
#endif
#ifdef HAVE_OSGDB_PNM
    USE_OSGPLUGIN(pnm)
#endif
#ifdef HAVE_OSGDB_RGB
    USE_OSGPLUGIN(rgb)
#endif
#ifdef HAVE_OSGDB_TGA
    USE_OSGPLUGIN(tga)
#endif
#ifdef HAVE_OSGDB_PNG
    USE_OSGPLUGIN(png)
#endif
#ifdef HAVE_OSGDB_JPEG
    USE_OSGPLUGIN(jpeg)
#endif
#ifdef HAVE_OSGDB_TIFF
    USE_OSGPLUGIN(tiff)
#endif
#ifdef HAVE_OSGDB_JP2
    USE_OSGPLUGIN(jp2)
#endif

#endif // OSG_LIBRARY_STATIC


namespace
{

int fail(const std::string& what)
{
    std::cout << "FAILED: " << what << std::endl;
    return 1;
}

std::streamsize fileSize(const std::string& path)
{
    std::ifstream in(path.c_str(), std::ios::binary | std::ios::ate);
    if (!in) return -1;
    // tellg() returns pos_type, which converts to streamsize both ways -- a
    // conditional mixing the two is ambiguous, so convert explicitly.
    return static_cast<std::streamsize>(in.tellg());
}


// ---------------------------------------------------------------- node scenes

// Group -> MatrixTransform -> Geode -> Geometry, a unit cube. Deliberately
// ordinary: every node type here is one that any general-purpose plugin has to
// handle, and all four live in the osg serializer library.
osg::ref_ptr<osg::Node> makeScene()
{
    static const float c[8][3] = {
        {0,0,0},{1,0,0},{1,1,0},{0,1,0},{0,0,1},{1,0,1},{1,1,1},{0,1,1}
    };
    static const unsigned int idx[36] = {
        0,1,2, 0,2,3,  4,6,5, 4,7,6,  0,4,5, 0,5,1,
        3,2,6, 3,6,7,  0,3,7, 0,7,4,  1,5,6, 1,6,2
    };

    osg::ref_ptr<osg::Vec3Array> verts   = new osg::Vec3Array;
    osg::ref_ptr<osg::Vec3Array> normals = new osg::Vec3Array;
    for (unsigned int i = 0; i < 8; ++i)
    {
        verts->push_back(osg::Vec3(c[i][0], c[i][1], c[i][2]));
        osg::Vec3 n(c[i][0] - 0.5f, c[i][1] - 0.5f, c[i][2] - 0.5f);
        n.normalize();
        normals->push_back(n);
    }

    osg::ref_ptr<osg::DrawElementsUInt> tris = new osg::DrawElementsUInt(GL_TRIANGLES);
    for (unsigned int i = 0; i < 36; ++i) tris->push_back(idx[i]);

    osg::ref_ptr<osg::Geometry> geom = new osg::Geometry;
    geom->setName("cube_geometry");
    geom->setVertexArray(verts.get());
    geom->setNormalArray(normals.get(), osg::Array::BIND_PER_VERTEX);
    geom->addPrimitiveSet(tris.get());

    // A material is not decoration, and it has to sit on the drawable rather
    // than the geode. The ac3d writer looks for one via Drawable::getStateSet
    // (Geode.cpp:680) and emits a MATERIAL header plus a per-surface "mat" line
    // only when it finds it -- and its own reader treats a surface with no mat
    // line as a fatal parse error (ac3d.cpp:1304). On a geode StateSet the
    // writer misses it and produces a file it cannot read back.
    osg::ref_ptr<osg::Material> material = new osg::Material;
    material->setAmbient(osg::Material::FRONT_AND_BACK, osg::Vec4(0.2f, 0.2f, 0.2f, 1.0f));
    material->setDiffuse(osg::Material::FRONT_AND_BACK, osg::Vec4(0.8f, 0.6f, 0.4f, 1.0f));
    geom->getOrCreateStateSet()->setAttributeAndModes(material.get(), osg::StateAttribute::ON);

    osg::ref_ptr<osg::Geode> geode = new osg::Geode;
    geode->setName("cube_geode");
    geode->addDrawable(geom.get());

    osg::ref_ptr<osg::MatrixTransform> xform = new osg::MatrixTransform;
    xform->setName("cube_xform");
    xform->setMatrix(osg::Matrix::translate(1.0, 2.0, 3.0));
    xform->addChild(geode.get());

    osg::ref_ptr<osg::Group> root = new osg::Group;
    root->setName("root");
    root->addChild(xform.get());
    return root;
}

struct Counts
{
    unsigned int geometries;
    unsigned int vertices;
    unsigned int primitiveSets;
    unsigned int transforms;

    Counts() : geometries(0), vertices(0), primitiveSets(0), transforms(0) {}
};

class Counter : public osg::NodeVisitor
{
public:
    Counter() : osg::NodeVisitor(osg::NodeVisitor::TRAVERSE_ALL_CHILDREN) {}

    void apply(osg::Transform& node) override
    {
        ++counts.transforms;
        traverse(node);
    }

    void apply(osg::Geometry& geom) override
    {
        ++counts.geometries;
        if (const osg::Array* v = geom.getVertexArray())
            counts.vertices += static_cast<unsigned int>(v->getNumElements());
        counts.primitiveSets += static_cast<unsigned int>(geom.getNumPrimitiveSets());
    }

    Counts counts;
};

Counts count(osg::Node& node)
{
    Counter counter;
    node.accept(counter);
    return counter.counts;
}

int roundTripNode(const std::string& ext, bool exact)
{
    const std::string path = "roundtrip_node." + ext;

    osg::ref_ptr<osg::Node> original = makeScene();
    const Counts before = count(*original);

    if (!osgDB::writeNodeFile(*original, path))
        return fail("osgDB::writeNodeFile refused to write " + path +
                    " -- is the plugin registered under the name USE_OSGPLUGIN uses?");

    const std::streamsize size = fileSize(path);
    if (size <= 0)
        return fail("wrote " + path + " but it is empty or missing");

    osg::ref_ptr<osg::Node> reloaded = osgDB::readNodeFile(path);
    if (!reloaded)
        return fail("osgDB::readNodeFile could not read back " + path);

    const Counts after = count(*reloaded);

    // Every format has to manage this much or the plugin is not working.
    if (after.geometries == 0) return fail("read back no geometry from " + path);
    if (after.vertices == 0)   return fail("read back no vertices from " + path);

    if (exact)
    {
        if (after.geometries != before.geometries)
            return fail("geometry count changed: wrote " + std::to_string(before.geometries) +
                        ", read " + std::to_string(after.geometries));
        if (after.vertices != before.vertices)
            return fail("vertex count changed: wrote " + std::to_string(before.vertices) +
                        ", read " + std::to_string(after.vertices));
        if (after.primitiveSets != before.primitiveSets)
            return fail("primitive set count changed: wrote " + std::to_string(before.primitiveSets) +
                        ", read " + std::to_string(after.primitiveSets));
        if (after.transforms != before.transforms)
            return fail("transform count changed: wrote " + std::to_string(before.transforms) +
                        ", read " + std::to_string(after.transforms));
    }

    std::cout << "ok  node ." << ext << "  " << size << " bytes, "
              << after.geometries << " geometry/" << after.vertices << " verts/"
              << after.primitiveSets << " primsets/" << after.transforms << " transforms"
              << (exact ? "  [exact]" : "  [structural]") << std::endl;
    return 0;
}


// --------------------------------------------------------------------- images

osg::ref_ptr<osg::Image> makeImage()
{
    osg::ref_ptr<osg::Image> image = new osg::Image;
    image->setFileName("roundtrip");
    image->allocateImage(16, 16, 1, GL_RGB, GL_UNSIGNED_BYTE);

    for (int t = 0; t < 16; ++t)
    {
        unsigned char* row = image->data(0, t);
        for (int s = 0; s < 16; ++s)
        {
            row[s * 3 + 0] = static_cast<unsigned char>(s * 16);
            row[s * 3 + 1] = static_cast<unsigned char>(t * 16);
            row[s * 3 + 2] = static_cast<unsigned char>((s ^ t) * 16);
        }
    }
    return image;
}

// Radiance .hdr is a floating point format and its writer rejects anything whose
// internal texture format is not GL_RGB32F_ARB, so the 8-bit image above cannot
// be written to it at all. Formats in that family get this one instead.
osg::ref_ptr<osg::Image> makeFloatImage()
{
    osg::ref_ptr<osg::Image> image = new osg::Image;
    image->setFileName("roundtrip");
    image->allocateImage(16, 16, 1, GL_RGB, GL_FLOAT);
    image->setInternalTextureFormat(GL_RGB32F_ARB);

    for (int t = 0; t < 16; ++t)
    {
        float* row = reinterpret_cast<float*>(image->data(0, t));
        for (int s = 0; s < 16; ++s)
        {
            row[s * 3 + 0] = static_cast<float>(s) / 15.0f;
            row[s * 3 + 1] = static_cast<float>(t) / 15.0f;
            row[s * 3 + 2] = static_cast<float>(s ^ t) / 15.0f;
        }
    }
    return image;
}

int roundTripImage(const std::string& ext, bool exact, bool useFloat)
{
    const std::string path = "roundtrip_image." + ext;

    osg::ref_ptr<osg::Image> original = useFloat ? makeFloatImage() : makeImage();

    if (!osgDB::writeImageFile(*original, path))
        return fail("osgDB::writeImageFile refused to write " + path +
                    " -- is the plugin registered under the name USE_OSGPLUGIN uses?");

    const std::streamsize size = fileSize(path);
    if (size <= 0)
        return fail("wrote " + path + " but it is empty or missing");

    osg::ref_ptr<osg::Image> reloaded = osgDB::readImageFile(path);
    if (!reloaded)
        return fail("osgDB::readImageFile could not read back " + path);

    if (reloaded->s() != original->s() || reloaded->t() != original->t())
        return fail("dimensions changed: wrote 16x16, read " +
                    std::to_string(reloaded->s()) + "x" + std::to_string(reloaded->t()));

    if (exact)
    {
        if (reloaded->getPixelFormat() != original->getPixelFormat())
            return fail("pixel format changed");
        if (reloaded->getDataType() != original->getDataType())
            return fail("data type changed");
        if (reloaded->getTotalSizeInBytes() != original->getTotalSizeInBytes())
            return fail("image size in bytes changed");
        if (std::memcmp(reloaded->data(), original->data(),
                        original->getTotalSizeInBytes()) != 0)
            return fail("pixel data changed");
    }

    std::cout << "ok  image ." << ext << "  " << size << " bytes, "
              << reloaded->s() << "x" << reloaded->t()
              << (exact ? "  [exact]" : "  [structural]") << std::endl;
    return 0;
}

} // namespace


int main(int argc, char** argv)
{
    if (argc != 4)
    {
        std::cout << "usage: " << argv[0]
                  << " <node|image|imagef> <extension> <exact|structural>" << std::endl;
        return 2;
    }

    const std::string kind(argv[1]);
    const std::string ext(argv[2]);
    const std::string fidelity(argv[3]);

    if (fidelity != "exact" && fidelity != "structural")
        return fail("fidelity must be 'exact' or 'structural', got '" + fidelity + "'");
    const bool exact = (fidelity == "exact");

    // A plugin that declines the file reports it through osgDB's notify stream,
    // which is quiet by default. Turn it up so a failure says why.
    osg::setNotifyLevel(osg::WARN);

    if (kind == "node")   return roundTripNode(ext, exact);
    if (kind == "image")  return roundTripImage(ext, exact, false);
    if (kind == "imagef") return roundTripImage(ext, exact, true);

    return fail("kind must be 'node', 'image' or 'imagef', got '" + kind + "'");
}
