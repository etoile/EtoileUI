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

@end

