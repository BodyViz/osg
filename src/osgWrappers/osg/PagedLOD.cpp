// ***************************************************************************
//
//   Generated automatically by genwrapper.
//   Please DO NOT EDIT this file!
//
// ***************************************************************************

#include <osgIntrospection/ReflectionMacros>
#include <osgIntrospection/TypedMethodInfo>
#include <osgIntrospection/StaticMethodInfo>
#include <osgIntrospection/Attributes>

#include <osg/CopyOp>
#include <osg/Group>
#include <osg/Node>
#include <osg/NodeVisitor>
#include <osg/Object>
#include <osg/PagedLOD>
#include <osg/Referenced>

// Must undefine IN and OUT macros defined in Windows headers
#ifdef IN
#undef IN
#endif
#ifdef OUT
#undef OUT
#endif

TYPE_NAME_ALIAS(std::vector< osg::PagedLOD::PerRangeData >, osg::PagedLOD::PerRangeDataList)

BEGIN_OBJECT_REFLECTOR(osg::PagedLOD)
	I_DeclaringFile("osg/PagedLOD");
	I_BaseType(osg::LOD);
	I_Constructor0(____PagedLOD,
	               "",
	               "");
	I_ConstructorWithDefaults2(IN, const osg::PagedLOD &, x, , IN, const osg::CopyOp &, copyop, osg::CopyOp::SHALLOW_COPY,
	                           ____PagedLOD__C5_PagedLOD_R1__C5_CopyOp_R1,
	                           "Copy constructor using CopyOp to manage deep vs shallow copy. ",
	                           "");
	I_Method0(osg::Object *, cloneType,
	          Properties::VIRTUAL,
	          __osg_Object_P1__cloneType,
	          "clone an object of the same type as the node. ",
	          "");
	I_Method1(osg::Object *, clone, IN, const osg::CopyOp &, copyop,
	          Properties::VIRTUAL,
	          __osg_Object_P1__clone__C5_osg_CopyOp_R1,
	          "return a clone of a node, with Object* return type. ",
	          "");
	I_Method1(bool, isSameKindAs, IN, const osg::Object *, obj,
	          Properties::VIRTUAL,
	          __bool__isSameKindAs__C5_osg_Object_P1,
	          "return true if this and obj are of the same kind of object. ",
	          "");
	I_Method0(const char *, className,
	          Properties::VIRTUAL,
	          __C5_char_P1__className,
	          "return the name of the node's class type. ",
	          "");
	I_Method0(const char *, libraryName,
	          Properties::VIRTUAL,
	          __C5_char_P1__libraryName,
	          "return the name of the node's library. ",
	          "");
	I_Method1(void, accept, IN, osg::NodeVisitor &, nv,
	          Properties::VIRTUAL,
	          __void__accept__osg_NodeVisitor_R1,
	          "Visitor Pattern : calls the apply method of a NodeVisitor with this node's type. ",
	          "");
	I_Method1(void, traverse, IN, osg::NodeVisitor &, nv,
	          Properties::VIRTUAL,
	          __void__traverse__NodeVisitor_R1,
	          "Traverse downwards : calls children's accept method with NodeVisitor. ",
	          "");
	I_Method1(bool, addChild, IN, osg::Node *, child,
	          Properties::VIRTUAL,
	          __bool__addChild__Node_P1,
	          "Add Node to Group. ",
	          "If node is not NULL and is not contained in Group then increment its reference count, add it to the child list and dirty the bounding sphere to force it to recompute on next getBound() and return true for success. Otherwise return false. Scene nodes can't be added as child nodes. ");
	I_Method3(bool, addChild, IN, osg::Node *, child, IN, float, min, IN, float, max,
	          Properties::VIRTUAL,
	          __bool__addChild__Node_P1__float__float,
	          "",
	          "");
	I_MethodWithDefaults6(bool, addChild, IN, osg::Node *, child, , IN, float, min, , IN, float, max, , IN, const std::string &, filename, , IN, float, priorityOffset, 0.0f, IN, float, priorityScale, 1.0f,
	                      Properties::VIRTUAL,
	                      __bool__addChild__Node_P1__float__float__C5_std_string_R1__float__float,
	                      "",
	                      "");
	I_MethodWithDefaults2(bool, removeChildren, IN, unsigned int, pos, , IN, unsigned int, numChildrenToRemove, 1,
	                      Properties::VIRTUAL,
	                      __bool__removeChildren__unsigned_int__unsigned_int,
	                      "Remove children from Group. ",
	                      "Note, must be override by subclasses of Group which add per child attributes. ");
	I_Method1(void, setDatabasePath, IN, const std::string &, path,
	          Properties::NON_VIRTUAL,
	          __void__setDatabasePath__C5_std_string_R1,
	          "Set the database path to prepend to children's filenames. ",
	          "");
	I_Method0(const std::string &, getDatabasePath,
	          Properties::NON_VIRTUAL,
	          __C5_std_string_R1__getDatabasePath,
	          "Get the database path used to prepend to children's filenames. ",
	          "");
	I_Method2(void, setFileName, IN, unsigned int, childNo, IN, const std::string &, filename,
	          Properties::NON_VIRTUAL,
	          __void__setFileName__unsigned_int__C5_std_string_R1,
	          "",
	          "");
	I_Method1(const std::string &, getFileName, IN, unsigned int, childNo,
	          Properties::NON_VIRTUAL,
	          __C5_std_string_R1__getFileName__unsigned_int,
	          "",
	          "");
	I_Method0(unsigned int, getNumFileNames,
	          Properties::NON_VIRTUAL,
	          __unsigned_int__getNumFileNames,
	          "",
	          "");
	I_Method2(void, setPriorityOffset, IN, unsigned int, childNo, IN, float, priorityOffset,
	          Properties::NON_VIRTUAL,
	          __void__setPriorityOffset__unsigned_int__float,
	          "",
	          "");
	I_Method1(float, getPriorityOffset, IN, unsigned int, childNo,
	          Properties::NON_VIRTUAL,
	          __float__getPriorityOffset__unsigned_int,
	          "",
	          "");
	I_Method0(unsigned int, getNumPriorityOffsets,
	          Properties::NON_VIRTUAL,
	          __unsigned_int__getNumPriorityOffsets,
	          "",
	          "");
	I_Method2(void, setPriorityScale, IN, unsigned int, childNo, IN, float, priorityScale,
	          Properties::NON_VIRTUAL,
	          __void__setPriorityScale__unsigned_int__float,
	          "",
	          "");
	I_Method1(float, getPriorityScale, IN, unsigned int, childNo,
	          Properties::NON_VIRTUAL,
	          __float__getPriorityScale__unsigned_int,
	          "",
	          "");
	I_Method0(unsigned int, getNumPriorityScales,
	          Properties::NON_VIRTUAL,
	          __unsigned_int__getNumPriorityScales,
	          "",
	          "");
	I_Method2(void, setTimeStamp, IN, unsigned int, childNo, IN, double, timeStamp,
	          Properties::NON_VIRTUAL,
	          __void__setTimeStamp__unsigned_int__double,
	          "",
	          "");
	I_Method1(double, getTimeStamp, IN, unsigned int, childNo,
	          Properties::NON_VIRTUAL,
	          __double__getTimeStamp__unsigned_int,
	          "",
	          "");
	I_Method0(unsigned int, getNumTimeStamps,
	          Properties::NON_VIRTUAL,
	          __unsigned_int__getNumTimeStamps,
	          "",
	          "");
	I_Method2(void, setFrameNumber, IN, unsigned int, childNo, IN, int, frameNumber,
	          Properties::NON_VIRTUAL,
	          __void__setFrameNumber__unsigned_int__int,
	          "",
	          "");
	I_Method1(double, getFrameNumber, IN, unsigned int, childNo,
	          Properties::NON_VIRTUAL,
	          __double__getFrameNumber__unsigned_int,
	          "",
	          "");
	I_Method0(unsigned int, getNumFrameNumbers,
	          Properties::NON_VIRTUAL,
	          __unsigned_int__getNumFrameNumbers,
	          "",
	          "");
	I_Method1(osg::ref_ptr< osg::Referenced > &, getDatabaseRequest, IN, unsigned int, childNo,
	          Properties::NON_VIRTUAL,
	          __osg_ref_ptrT1_osg_Referenced__R1__getDatabaseRequest__unsigned_int,
	          "Return the DatabaseRequest object used by the DatabasePager to keep track of file load requests being carried on behalf of the DatabasePager. ",
	          "Note, in normal OSG usage you should not set this value yourself, as this will be managed by the osgDB::DatabasePager. ");
	I_Method1(const osg::ref_ptr< osg::Referenced > &, getDatabaseRequest, IN, unsigned int, childNo,
	          Properties::NON_VIRTUAL,
	          __C5_osg_ref_ptrT1_osg_Referenced__R1__getDatabaseRequest__unsigned_int,
	          "Return the const DatabaseRequest object. ",
	          "");
	I_Method1(void, setFrameNumberOfLastTraversal, IN, int, frameNumber,
	          Properties::NON_VIRTUAL,
	          __void__setFrameNumberOfLastTraversal__int,
	          "Set the frame number of the last time that this PageLOD node was traversed. ",
	          "Note, this frame number is automatically set by the traverse() method for all traversals (update, cull etc.). ");
	I_Method0(int, getFrameNumberOfLastTraversal,
	          Properties::NON_VIRTUAL,
	          __int__getFrameNumberOfLastTraversal,
	          "Get the frame number of the last time that this PageLOD node was traversed. ",
	          "");
	I_Method1(void, setNumChildrenThatCannotBeExpired, IN, unsigned int, num,
	          Properties::NON_VIRTUAL,
	          __void__setNumChildrenThatCannotBeExpired__unsigned_int,
	          "Set the number of children that the PagedLOD must keep around, even if they are older than their expiry time. ",
	          "");
	I_Method0(unsigned int, getNumChildrenThatCannotBeExpired,
	          Properties::NON_VIRTUAL,
	          __unsigned_int__getNumChildrenThatCannotBeExpired,
	          "Get the number of children that the PagedLOD must keep around, even if they are older than their expiry time. ",
	          "");
	I_Method3(bool, removeExpiredChildren, IN, double, expiryTime, IN, int, expiryFrame, IN, osg::NodeList &, removedChildren,
	          Properties::VIRTUAL,
	          __bool__removeExpiredChildren__double__int__NodeList_R1,
	          "Remove the children from the PagedLOD which haven't been visited since specified expiry time and expiry frame number. ",
	          "The removed children are added to the removeChildren list passed into the method, this allows the children to be deleted later at the caller's discretion. Return true if children are removed, false otherwise. ");
	I_ProtectedMethod1(void, expandPerRangeDataTo, IN, unsigned int, pos,
	                   Properties::NON_VIRTUAL,
	                   Properties::NON_CONST,
	                   __void__expandPerRangeDataTo__unsigned_int,
	                   "",
	                   "");
	I_SimpleProperty(const std::string &, DatabasePath, 
	                 __C5_std_string_R1__getDatabasePath, 
	                 __void__setDatabasePath__C5_std_string_R1);
	I_ArrayProperty(const std::string &, FileName, 
	                __C5_std_string_R1__getFileName__unsigned_int, 
	                __void__setFileName__unsigned_int__C5_std_string_R1, 
	                __unsigned_int__getNumFileNames, 
	                0, 
	                0, 
	                0);
	I_ArrayProperty(double, FrameNumber, 
	                __double__getFrameNumber__unsigned_int, 
	                0, 
	                __unsigned_int__getNumFrameNumbers, 
	                0, 
	                0, 
	                0);
	I_SimpleProperty(int, FrameNumberOfLastTraversal, 
	                 __int__getFrameNumberOfLastTraversal, 
	                 __void__setFrameNumberOfLastTraversal__int);
	I_SimpleProperty(unsigned int, NumChildrenThatCannotBeExpired, 
	                 0, 
	                 __void__setNumChildrenThatCannotBeExpired__unsigned_int);
	I_ArrayProperty(float, PriorityOffset, 
	                __float__getPriorityOffset__unsigned_int, 
	                __void__setPriorityOffset__unsigned_int__float, 
	                __unsigned_int__getNumPriorityOffsets, 
	                0, 
	                0, 
	                0);
	I_ArrayProperty(float, PriorityScale, 
	                __float__getPriorityScale__unsigned_int, 
	                __void__setPriorityScale__unsigned_int__float, 
	                __unsigned_int__getNumPriorityScales, 
	                0, 
	                0, 
	                0);
	I_ArrayProperty(double, TimeStamp, 
	                __double__getTimeStamp__unsigned_int, 
	                __void__setTimeStamp__unsigned_int__double, 
	                __unsigned_int__getNumTimeStamps, 
	                0, 
	                0, 
	                0);
END_REFLECTOR

BEGIN_VALUE_REFLECTOR(osg::PagedLOD::PerRangeData)
	I_DeclaringFile("osg/PagedLOD");
	I_Constructor0(____PerRangeData,
	               "",
	               "");
	I_Constructor1(IN, const osg::PagedLOD::PerRangeData &, prd,
	               Properties::NON_EXPLICIT,
	               ____PerRangeData__C5_PerRangeData_R1,
	               "",
	               "");
	I_PublicMemberProperty(std::string, _filename);
	I_PublicMemberProperty(float, _priorityOffset);
	I_PublicMemberProperty(float, _priorityScale);
	I_PublicMemberProperty(double, _timeStamp);
	I_PublicMemberProperty(int, _frameNumber);
	I_PublicMemberProperty(osg::ref_ptr< osg::Referenced >, _databaseRequest);
END_REFLECTOR

STD_VECTOR_REFLECTOR(std::vector< osg::PagedLOD::PerRangeData >)

