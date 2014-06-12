/*
	Copyright (C) 2011 Quentin Mathe

	Author:  Quentin Mathe <quentin.math@gmail.com>
	Date:  July 2011
	License: Modified BSD (see COPYING)
 */

#import <EtoileFoundation/Macros.h>
#import <EtoileFoundation/ETCollection.h>
#import <EtoileFoundation/ETEntityDescription.h>
#import <EtoileFoundation/ETModelDescriptionRepository.h>
#import <EtoileFoundation/NSObject+Model.h>
#import <CoreObject/COCopier.h>
#import <CoreObject/COObjectGraphContext.h>
#import <CoreObject/COPath.h>
#import <CoreObject/COSerialization.h>
#import "ETUIObject.h"
#import "ETController.h"
#import "ETLayoutItemGroup.h"
#import "NSObject+EtoileUI.h"
#import "ETCompatibility.h"

@interface COObject ()
- (id) copyWithZone: (NSZone *)aZone;
@end

@implementation ETUIObject

/** Returns ET. */
+ (NSString *) typePrefix
{
	return @"ET";
}

static COObjectGraphContext *defaultObjectGraphContext = nil;

/** <override-never />
This method is only exposed to be used internally by CoreObject.

Returns a transient object graph context that can be used for building a UI in 
code.
 
See +[ETLayoutItemFactory sharedInstance]. */
+ (COObjectGraphContext *) defaultTransientObjectGraphContext
{
	if (defaultObjectGraphContext == nil)
	{
		defaultObjectGraphContext = [COObjectGraphContext new];
	}
	return defaultObjectGraphContext;
}

- (void) awakeFromDeserialization
{

}

- (id) copyToObjectGraphContext: (COObjectGraphContext *)aDestination
{
	NILARG_EXCEPTION_TEST(aDestination);
	ETUUID *newItemUUID = [AUTORELEASE([COCopier new]) copyItemWithUUID: [self UUID]
	                                                          fromGraph: [self objectGraphContext]
	                                                            toGraph: aDestination];

	return [[self objectGraphContext] loadedObjectForUUID: newItemUUID];
}

/** Calls -copyToObjectGraphContext: with the receiver object graph context.

The zone argument is currently ignored. */
- (id) copyWithZone: (NSZone *)aZone
{
	return [self copyToObjectGraphContext: [self objectGraphContext]];
}

#if 0

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

#endif

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

// FIXME: Horrible hack to return -[NSObject(Model) propertyNames] rather than 
// letting COObject returns redundant entity-declared properties.
// Allow EtoileUI test suite to pass all tests (it doesn't work well when 
// -propertyNames returns redundant properties).
- (NSArray *) NSObjectPropertyNames
{
	return [NSArray arrayWithObjects: @"icon", @"displayName", @"className", 
		@"stringValue", @"objectValue", @"isCollection", @"isGroup", 
		@"isMutable", @"isMutableCollection", @"isCommonObjectValue", 
		@"isNumber", @"isString", @"isClass", @"description", 
		@"primitiveDescription", nil];
}

- (NSArray *) propertyNames
{
	return [[self NSObjectPropertyNames] 
		arrayByAddingObjectsFromArray: [[self entityDescription] allPropertyDescriptionNames]];
}

/** Returns a dictionary representation of every property/value pairs not stored 
in ivars.
 
Unless you write a subclass or reflection code, you should never need this 
method, but use the property accessors or Property Value Coding methods to read 
and write the receiver properties. */
- (NSMutableDictionary *) variableStorage
{
	return _variableStorage;
}

// TODO: Remove once shared instances don't get garbage collected on
// -[COObjectGraphContext discardAllChanges], or when -discardAllChanges is not
// called on the default transient object graph context in the test suite.
- (void) checkIsNotRemovedFromContext
{

}

- (ETEntityDescription *)persistentEntityDescription
{
	return  [[[self objectGraphContext] modelDescriptionRepository] descriptionForName: @"COObject"];
}

- (BOOL) isCoreObjectReference: (id)value
{
	return ([value isKindOfClass: [ETUUID class]] || [value isKindOfClass: [COPath class]]);
}

- (NSData *) serializedRepresentationForObject: (id)anObject
{
	if ([anObject respondsToSelector: @selector(serializedRepresentation)])
	{
		return [anObject serializedRepresentation];
	}
	return anObject;
}

- (NSString *) serializedValueForWeakTypedReference: (id)value
{
	if ([value isKindOfClass: [ETUUID class]])
	{
		return [@"uuid: " stringByAppendingString: [(ETUUID *)value stringValue]];
	}
	else if ([value isKindOfClass: [COPath class]])
	{
		return [@"path: " stringByAppendingString: [value stringValue]];
	}
	else if ([value isKindOfClass: [NSURL class]])
	{
		return [@"url: " stringByAppendingString: [(NSURL *)value absoluteString]];
	}
	else if (value != nil)
	{
		NSData *data = [NSKeyedArchiver archivedDataWithRootObject: value];
		return [@"data: " stringByAppendingString: [data base64String]];
	}
	return nil;
}

- (id) weakTypedReferenceForSerializedValue: (NSString *)value
{
	if ([value hasPrefix: @"uuid: "])
	{
		return [ETUUID UUIDWithString: [value substringFromIndex: 6]];
	}
	else if ([value hasPrefix: @"path: "])
	{
		return [COPath pathWithString: [value substringFromIndex: 6]];
	}
	else if ([value hasPrefix: @"url: "])
	{
		return [NSURL URLWithString: [value substringFromIndex: 5]];
	}
	else if (value != nil)
	{
		NSData *data = [[value substringFromIndex: 6] base64DecodedData];
		return [NSKeyedUnarchiver unarchiveObjectWithData: data];
	}
	return nil;
}

- (BOOL)commitWithIdentifier: (NSString *)aCommitDescriptorId
{
	return [self commitWithIdentifier: aCommitDescriptorId metadata: nil];
}

/** <override-never />
Does nothing by default.

If built with CoreObject support, commits changes in the persistent root related 
to the receiver root object.

Will be called by ETActionHandler methods that make changes in response to the 
user interaction. */
- (BOOL)commitWithIdentifier: (NSString *)aCommitDescriptorId
					metadata: (NSDictionary *)additionalMetadata
{
	if ([self isPersistent] == NO)
		return NO;

	id rootObject = [self rootObject];
	COUndoTrack *undoTrack = nil;
	
	if ([rootObject isLayoutItem] && [rootObject isGroup])
	{
		// TODO: Formalize a bit more
		undoTrack = [[[rootObject controllerItem] controller] undoTrack];
	}

	COError *error = nil;
	BOOL result = [[self persistentRoot] commitWithIdentifier: aCommitDescriptorId
	                                                 metadata: additionalMetadata
	                                                undoTrack: undoTrack
	                                                    error: &error];
	ETAssert(error == nil);

	return result;
}

// FIXME: COObject relationship consistency is disabled because it doesn't
// work on a collection accessor that return immutable copies.
- (void) updateRelationshipConsistencyForProperty: (NSString *)key oldValue: (id)oldValue
{
	
}

@end
