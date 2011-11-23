/*
	Copyright (C) 2011 Quentin Mathe

	Author:  Quentin Mathe <quentin.math@gmail.com>
	Date:  July 2011
	License: Modified BSD (see COPYING)
 */

#import <EtoileFoundation/Macros.h>
#import <EtoileFoundation/ETCollection.h>
#import <EtoileFoundation/NSObject+Model.h>
#import "ETUIObject.h"
#import "ETCompatibility.h"


@implementation ETUIObject

#ifdef OBJECTMERGING

// FIXME: We probably shouldn't need to override the awake methods below.
// The problem boils down to preventing the COObject implementation to 
// instantiate multivalued collections behind our back. Perhaps rework 
// ETLayoutItemGroup to let ETUIObject or COObject handle that.

- (void) awakeFromInsert
{

}

- (void) awakeFromFetch
{

}

- (id) basicCopyWithZone: (NSZone *)aZone
{
	return [super copyWithZone: aZone];
}

#else

- (id) basicInit
{
	SUPERINIT;
	// TODO: Examine common use cases and see whether we should pass a 
	// capacity hint to improve performances.
	_variableStorage = [[NSMapTable alloc] init];
	return self;
}

- (id) init
{
	return [self basicInit];
}

- (void) dealloc
{
	DESTROY(_variableStorage);
    [super dealloc];
}

#endif

/** Calls -copyWithCopier:.

The zone argument is currently ignored. */
- (id) copyWithZone: (NSZone *)aZone
{
	// NOTE: If the zone matters in some code, implement -[ETCopier setZone:]
	return [self copyWithCopier: [ETCopier copier]];
}

/** <override-dummy />

Returns a copy of the receiver.

You must pass a non-null isAliasedCopy pointer. On return, the boolean value 
will identicate whether a new object was allocated or an alias was returned.<br />
When copying a object graph, if a ETUIObject instance has been copied at least 
one time, then subsequent -copyWithZone: invocations return this copy rather 
than allocating a new object, and isAliasedCopy is set to YES. 

This method is ETUIObject designated copier. Subclasses that want to extend 
the copying support must invoke it instead of -copyWithZone:.

A subclass can provide a new designated copier API, but the implementation must 
invoke -copyWithZone:isAliasedCopy: on the superclass.<br />
Designated copier overriding rules are identical to the designated initializer 
rules.

All ETUIObject subclasses must write their copier method in a way that 
precisely matches the template shown below:

<example>
// isAliasedCopy is the argument the copy method receives
id newObject = [super copyWithZone: aZone isAliasedCopy: isAliasedCopy];

if (*isAliasedCopy)
	return newObject;

[self beginCopy];
// Code
[self endCopy];

return newObject;
</example>

You must insert no code before -beginCopy and after -endCopy.

Between -beginCopy and -endCopy, you can use -currentCopyNode and 
-objectReferencesForCopy. */
- (id) copyWithCopier: (ETCopier *)aCopier
{
	/* Return aliased copy */

	id refInCopy = [aCopier lookUpAliasedCopyForObject: self];


	if (refInCopy != nil)
		return refInCopy;

	/* Or create a copy */

	ETUIObject *newObject = [aCopier allocCopyForObject: self];
	NSInvocation *initInvocation = [self initInvocationForCopyWithZone: [aCopier zone]];

	[aCopier beginCopyFromObject: self toObject: newObject];

	if (nil != initInvocation)
	{
		[initInvocation invokeWithTarget: newObject];
		[initInvocation getReturnValue: &newObject];
	}

	[aCopier endCopy];

	return newObject;
}

/** This method is only exposed to be used internally by EtoileUI.

Returns whether copying this object makes it the current copy node. See 
-currentCopyNode.

By default, returns NO.

Overriden by ETLayoutItem to return YES. */
- (BOOL) isCopyNode
{
	return NO;
}

static ETCopier *copier = nil;

- (NSMapTable *) objectReferencesForCopy
{
	ETAssert(copier != nil);
	return [copier objectReferencesForCopy];
}

- (NSString *) description
{
	return [self primitiveDescription];
}

/** <override-dummy />
Returns whether the receiver can be shared between several owners.

By default, returns NO.

Can be overriden to return YES, a computed value or an ivar value. For example, 
see -[ETStyle setIsShared:]. */
- (BOOL) isShared
{
	return NO;
}

/** <override-dummy />
Returns the initializer invocation used by -copyWithZone: to create a new 
instance. 

This method returns nil. You can override it to return a custom invocation and 
in this way shares complex initialization logic between -copyWithZone: and 
the designated initializer in a subclass.
 
e.g. if you return an invocation like -initWithWindow: aWindow. 
-copyWithZone: will automatically set the target to be the copy allocated with 
<code>[[[self class] allocWithZone: aZone]</code> and then initializes the copy 
by invoking the invocation. */
- (NSInvocation *) initInvocationForCopyWithZone: (NSZone *)aZone
{
	return nil;
}

/** Returns a dictionary representation of every property/value pairs not stored 
in ivars.
 
Unless you write a subclass or reflection code, you should never need this 
method, but use the property accessors or Property Value Coding methods to read 
and write the receiver properties. */
- (NSMapTable *) variableStorage
{
	return _variableStorage;
}

/** <override-never />
Does nothing by default.

If built with CoreObject support, commits changes in the editing context related 
to the receiver root object.

Will be called by ETActionHandler methods that make changes in response to the 
user interaction. */
- (void) commit
{
#ifdef OBJECTMERGING
	if ([self isPersistent] == NO)
		return;

	COObject *rootObject = [self rootObject];
	ETAssert(rootObject != nil);
	ETAssert([rootObject editingContext] != nil);
	[[rootObject editingContext] commit];
#endif
}

#ifndef OBJECTMERGING

- (id) commitTrack
{
	return nil;
}

- (BOOL) isRoot
{
	return NO;
}

- (void) willChangeValueForProperty: (NSString *)aKey
{
	[self willChangeValueForKey: aKey];
}

- (void) didChangeValueForProperty: (NSString *)aKey
{
	[self didChangeValueForKey: aKey];
}

#endif

@end


@implementation ETCopier

+ (id) copier
{
	return AUTORELEASE([[self alloc] init]);
}

+ (id) copierWithNewRoot
{
	return AUTORELEASE([[self alloc] initWithDestinationRootObject: @"Unknow new root object"]);
}

+ (id) copierWithDestinationRootObject: (id)aRootObject
{
	return AUTORELEASE([[self alloc] initWithDestinationRootObject: aRootObject]);
}

- (id) initWithDestinationRootObject: (id)aRootObject
{
	SUPERINIT;
	ASSIGN(destinationRootObject, aRootObject);
	currentNewNodeStack = [[NSMutableArray alloc] init];
	currentNodeStack = [[NSMutableArray alloc] init];
	currentObjectStack = [[NSMutableArray alloc] init];
	currentAliasedCopies = [[NSMutableSet alloc] init];
	ASSIGN(objectRefsForCopy, [NSMapTable mapTableWithStrongToStrongObjects]);
	return self;
}

- (id) init
{
	return [self initWithDestinationRootObject: nil];
}

- (void) dealloc
{
	DESTROY(destinationRootObject);
	DESTROY(sourceRootObject);
	DESTROY(currentNewNodeStack);
	DESTROY(currentNodeStack);
	DESTROY(currentObjectStack);
	DESTROY(lastCopiedObject);
	DESTROY(currentAliasedCopies);
	DESTROY(objectRefsForCopy);
	[super dealloc];
}

- (id) allocCopyForObject: (id)anObject
{
	BOOL wasCopierUsedPreviously = ([objectRefsForCopy objectForKey: anObject] != nil);

	if (wasCopierUsedPreviously)
	{
		[NSException raise: NSGenericException 
		            format: @"Copier %@ has been used previously and cannot be reused", self];
	}

	// FIXME: Shouldn't require ETUIObject
#ifdef OBJECTMERGING
	ETUIObject *newObject = [anObject basicCopyWithZone: [self zone]];
#else
	/* -basicInit creates the variable storage map table */
	ETUIObject *newObject = [[[anObject class] allocWithZone: [self zone]] basicInit];
#endif
	[objectRefsForCopy setObject: newObject forKey: anObject];
	return newObject;
}

/** Returns a reference in the object graph copy if the object has been copied 
previously, otherwise returns nil.

After invoking -lookUpAliasedCopyForObject:, -isAliasedCopy can be used to check 
whether the last copied object is a aliased copy that was returned by this method. */
- (id) lookUpAliasedCopyForObject: (id)anObject
{
	id newObject = [objectRefsForCopy objectForKey: anObject];

	if (newObject != nil)
	{
		[currentAliasedCopies addObject: newObject];
	}
	return newObject;
}

- (id) lastCopiedObject
{
	return ([currentObjectStack isEmpty] ? lastCopiedObject : [currentObjectStack lastObject]);
}

/** Returns whether the last copied object is a reference alias on a previously 
made copy of the same object. */
- (BOOL) isAliasedCopy
{
	return [currentAliasedCopies containsObject: [self lastCopiedObject]];
}

- (void) beginCopyFromObject: (id)anObject toObject: (id)newObject
{
	BOOL sourceRootObjectMismatch = ([currentObjectStack count] == 0 
		&& sourceRootObject != nil && sourceRootObject != anObject);

	if (sourceRootObjectMismatch)
	{
		[NSException raise: NSGenericException 
		            format: @"First copied object %@ doesn't match the source root object %@ of %@", 
		                    anObject, sourceRootObject, self];
	}
	// FIXME: ETAssert(sourceRootObject != nil);
	
	copier = self;
	[currentObjectStack addObject: anObject];
	ASSIGN(lastCopiedObject, anObject);

	if ([anObject isCopyNode])
	{
		[currentNewNodeStack addObject: newObject];
		[currentNodeStack addObject: anObject];
	}
}

- (void) endCopy
{
	if ([[currentObjectStack lastObject] isCopyNode])
	{
		[currentNewNodeStack removeLastObject];
		[currentNodeStack removeLastObject];
	}
	[currentObjectStack removeLastObject];
	ASSIGN(lastCopiedObject, [currentObjectStack lastObject]);

	BOOL isCopyFinished = (0 == [currentObjectStack count]);

	if (isCopyFinished)
	{
		ETAssert([currentNewNodeStack isEmpty] && [currentNodeStack isEmpty]);
		copier = nil;
	}
}

- (BOOL) isNewRoot
{
	return (destinationRootObject != nil);
}

/** Returns the node whose copy is underway.

In EtoileUI, returns the last layout item on which a copy method was invoked.

For example, can be called in a ETStyle subclass designated copier to get the 
item that transitively refers to this style object.

See also -currentNewNode. */
- (id) currentNode
{
	return [currentNodeStack lastObject];
}

/** Returns the node copy whose creation is underway.

This method is symetric to -currentNode. Every time -currentNode changes, 
-currentNewNode changes too. */
- (id) currentNewNode
{
	return [currentNewNodeStack lastObject];
}

/** Returns the object that represents the entry point in the object graph we copy. */
- (id) sourceRootObject
{
	return sourceRootObject;
}

/** Sets the object that represents the entry point in the object graph we copy. */
- (void) setSourceRootObject: (id)aRootObject
{
	ASSIGN(sourceRootObject, aRootObject);
}

/** Returns the object that represents the entry point in the object graph copy. */
- (id) destinationRootObject
{
	return destinationRootObject;
}

/** Returns a context which binds objects/values in the original object graph to 
their new equivalent objects/values in the resulting copy. 

This context is a key/value table which allows to retrieve arbitrary objects 
(usually they are controller) that were copied by an ancestor layout item in the 
deep copy underway.
e.g. In an item copy, you can correct a reference to a controller that belongs 
to an ancestor item like that: 
<example>
id controllerInItemCopy = [[copier objectReferencesForCopy] objectForKey: [self target]];

if (controllerInItemCopy != nil)
{
	ASSIGN(itemCopy->_target, controllerInItemCopy);
}
else
{
	ASSIGN(itemCopy->_target, _target);
}
</example> */
- (NSMapTable *) objectReferencesForCopy
{
	return objectRefsForCopy;
}

- (id) objectReferenceInCopyForObject: (id)anObject
{
	id newObject = [objectRefsForCopy objectForKey: anObject];
	return (newObject != nil ? newObject : anObject);
}

/** Returns the default malloc zone. */
- (NSZone *) zone
{
	return NSDefaultMallocZone();
}

@end
