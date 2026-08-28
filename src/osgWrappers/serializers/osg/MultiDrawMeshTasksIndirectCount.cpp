#include <osg/MultiDrawMeshTasksIndirectCount>
#include <osgDB/ObjectWrapper>
#include <osgDB/InputStream>
#include <osgDB/OutputStream>

// See DrawMeshTasksIndirect.cpp for why GLintptr is not serialized directly.
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

GL_INTPTR_SERIALIZER(osg::MultiDrawMeshTasksIndirectCount,Offset)
GL_INTPTR_SERIALIZER(osg::MultiDrawMeshTasksIndirectCount,DrawCount)

REGISTER_OBJECT_WRAPPER( MultiDrawMeshTasksIndirectCount,
                         new osg::MultiDrawMeshTasksIndirectCount,
                         osg::MultiDrawMeshTasksIndirectCount,
                         "osg::Object osg::Node osg::Drawable osg::MultiDrawMeshTasksIndirectCount" )
{
    ADD_USER_SERIALIZER(Offset);
    ADD_USER_SERIALIZER(DrawCount);

    wrapper->addSerializer( new osgDB::PropByValSerializer< MyClass, GLsizei >( \
        "MaxDrawCount", 0, &MyClass::getMaxDrawCount, &MyClass::setMaxDrawCount), osgDB::BaseSerializer::RW_INT );

    wrapper->addSerializer( new osgDB::PropByValSerializer< MyClass, GLsizei>( \
        "Stride", 0, &MyClass::getStride, &MyClass::setStride), osgDB::BaseSerializer::RW_INT );
}
