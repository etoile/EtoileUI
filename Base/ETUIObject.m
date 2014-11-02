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

@interface ETUIObject (ETUIObjectTestAdditions)
- (void) recordDeallocation;
@end

@interface ETUIObject ()
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

static NSMutableDictionary *sharedInstanceUUIDs = nil;

+ (ETUUID *) sharedInstanceUUIDForObjectGraphContext: (COObjectGraphContext *)aContext
{
	// TODO: For a persistent context, return the UUID in the persistent root metadata.
	// TODO: Clear shared instance bound to a context not in use.

	if (sharedInstanceUUIDs == nil)
		sharedInstanceUUIDs = [[NSMutableDictionary alloc] init];

	NSString *className = NSStringFromClass(self);
	id key = (aContext != nil ? S(className, aContext) : S(className));
	ETUUID *uuid = [sharedInstanceUUIDs objectForKey: key];

	if (uuid == nil)
	{
		uuid = [ETUUID UUID];
		[sharedInstanceUUIDs setObject: uuid forKey: key];
	}

	return uuid;
}

/** <override-never />
Returns the shared instance that corresponds to the receiver class in the given 
object graph context.

ETStyle and ETActionHandler subclasses support shared instances. For other 
ETUIObject subclasses, other initialization means  should be used (e.g. 
ETLayoutItemFactory or the dedicated initializers). */
+ (id) sharedInstanceForObjectGraphContext: (COObjectGraphContext *)aContext
{
	ETUUID *permanentUUID = [self sharedInstanceUUIDForObjectGraphContext: aContext];
	ETUIObject *object = [aContext loadedObjectForUUID: permanentUUID];

	if (object != nil)
		return object;

	ETEntityDescription *entity =
		[[aContext modelDescriptionRepository] entityDescriptionForClass: self];

	return AUTORELEASE([[self alloc] initWithEntityDescription: entity
	                                                      UUID: permanentUUID
	                                        objectGraphContext: aContext]);
}
/** <override-dummy />
Does nothing by default, but can be overriden to recreate the transient state
in a way valid for both the designated initializer and -awakeFromDeserialization.
 
If you override it, it's the subclass responsability to call it in 
-awakeFromDeserialization and the initializer. 
 
You must never call the superclass implementation. */
- (void)prepareTransientState
{
	
}

- (void) dealloc
{
    if ([self respondsToSelector: @selector(recordDeallocation)])
    {
        [self recordDeallocation];
    }
    [super dealloc];
}

- (id) copyToObjectGraphContext: (COObjectGraphContext *)aDestination
{
	NILARG_EXCEPTION_TEST(aDestination);
	ETUUID *newItemUUID = [AUTORELEASE([COCopier new]) copyItemWithUUID: [self UUID]
	                                                          fromGraph: [self objectGraphContext]
	                                                            toGraph: aDestination];

	return RETAIN([[self objectGraphContext] loadedObjectForUUID: newItemUUID]);
}

/** Calls -copyToObjectGraphContext: with the receiver object graph context.

The zone argument is currently ignored. */
- (id) copyWithZone: (NSZone *)aZone
{
	return [self copyToObjectGraphContext: [self objectGraphContext]];
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

// TODO: Remove once shared instances don't get garbage collected on
// -[COObjectGraphContext discardAllChanges], or when -discardAllChanges is not
// called on the default transient object graph context in the test suite.
/*- (void) checkIsNotRemovedFromContext
{

}*/

// FIXME: Remove
- (void) awakeFromDeserialization
{
    
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

@end
