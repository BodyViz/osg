#include <osg/DrawMeshTasksIndirect>
#include <osgDB/ObjectWrapper>
#include <osgDB/InputStream>
#include <osgDB/OutputStream>

#define GL_INTPTR_SERIALIZER(TYPE,XXX) \
static bool check##XXX( const TYPE& node )\
{    return node.get##XXX()>0;}\
static bool read##XXX( osgDB::InputStream& is, TYPE& node )\
{\
    long value = 0; is >> value;    node.set##XXX(value);    return true;\
}\
static bool write##XXX( osgDB::OutputStream& os, const TYPE& node )\
{\
    long value = static_cast<long>(node.get##XXX());    os << value << std::endl;    return true;\
}

GL_INTPTR_SERIALIZER(osg::DrawMeshTasksIndirect,Offset)

REGISTER_OBJECT_WRAPPER( DrawMeshTasksIndirect,
                         new osg::DrawMeshTasksIndirect,
                         osg::DrawMeshTasksIndirect,
                         "osg::Object osg::Node osg::Drawable osg::DrawMeshTasksIndirect" )
{
    ADD_USER_SERIALIZER(Offset);
}
