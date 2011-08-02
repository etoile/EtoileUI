/*
	Copyright (C) 2011 Quentin Mathe

	Author:  Quentin Mathe <quentin.math@gmail.com>
	Date:  July 2011
	License: Modified BSD (see COPYING)
 */

#import <EtoileFoundation/Macros.h>
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

#else

- (id) init
{
	SUPERINIT;
	// TODO: Examine common use cases and see whether we should pass a 
	// capacity hint to improve performances.
	_variableStorage = [[NSMapTable alloc] init];
	return self;
}

- (void) dealloc
{
	DESTROY(_variableStorage);
    [super dealloc];
}

#endif

- (id) copyWithZone: (NSZone *)aZone
{
#ifdef OBJECTMERGING
	ETUIObject *newObject = [super copyWithZone: aZone];
#else
	ETUIObject *newObject = [[self class] allocWithZone: aZone];
	newObject->_variableStorage = [[NSMapTable alloc] init];
#endif
	NSInvocation *initInvocation = [self initInvocationForCopyWithZone: aZone];

	if (nil != initInvocation)
	{
		[initInvocation invokeWithTarget: newObject];
		[initInvocation getReturnValue: &newObject];
	}

	return newObject;
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
	COObject *rootObject = [self rootObject];
	ETAssert(rootObject != nil);
	ETAssert([rootObject editingContext] != nil);
	[[rootObject editingContext] commit];
#endif
}

#ifndef OBJECTMERGING

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

