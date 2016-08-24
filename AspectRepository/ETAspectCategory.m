/*
	Copyright (C) 20010 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  May 2010
	License: Modified BSD (see COPYING)
 */

#import <EtoileFoundation/ETCollection+HOM.h>
#import <EtoileFoundation/ETKeyValuePair.h>
#import <EtoileFoundation/ETUTI.h>
#import <EtoileFoundation/NSObject+Model.h>
#import <EtoileFoundation/NSObject+Trait.h>
#import <EtoileFoundation/Macros.h>
#import <CoreObject/COPrimitiveCollection.h>
#import "ETAspectCategory.h"
#import "ETCompatibility.h"

#pragma GCC diagnostic ignored "-Wprotocol"

@implementation ETAspectCategory

@synthesize name, allowedAspectTypes, icon;

+ (void) initialize
{
	if (self != [ETAspectCategory class])
		return;

	[self applyTraitFromClass: [ETCollectionTrait class]];
	[self applyTraitFromClass: [ETMutableCollectionTrait class]];
}

/** Returns the UTI type at the top of the type hierarchy which can be used to 
represent we accept any object as a valid aspect. */
+ (ETUTI *) anyType
{
	// TODO: We should return a supertype common to both NSObject UTI and public.data
	return [ETUTI typeWithClass: [NSObject class]];
}

/** <init />
Initializes and returns a new category whose content includes the dictionary 
entries.

If the given name is nil, the string value of +anyType is set as the category 
name. */
- (id) initWithName: (NSString *)aName
         dictionary: (NSDictionary *)aDict
 objectGraphContext: (COObjectGraphContext *)aContext
{
	self = [super initWithObjectGraphContext: aContext];
	if (self == nil)
		return nil;

	if (nil == aDict)
	{
		_aspectEntries = [[COMutableArray alloc] init];
	}
	else
	{
		_aspectEntries = [[COMutableArray alloc] initWithArray: [aDict arrayRepresentation]];
	}
	allowedAspectTypes = [[NSSet alloc] initWithObjects: [[self class] anyType], nil];
	if (aName == nil)
	{
		name = [[[self class] anyType] stringValue];
	}
	else
	{
		name = aName;
	}
	icon = [NSImage imageNamed: @"box"];
	return self;
}

/** Initializes and returns a new empty category.

See -initWithName:dictionary:objectGraphContext:. */
- (id) initWithName: (NSString *)aName
 objectGraphContext: (COObjectGraphContext *)aContext
{
	return [self initWithName: aName dictionary: nil objectGraphContext: aContext];
}

/** Initializes and returns a new empty category.

See -initWithName:dictionary:objectGraphContext:. */
- (id) initWithObjectGraphContext: (COObjectGraphContext *)aContext
{
	return [self initWithName: nil dictionary: nil objectGraphContext: aContext];
}

- (void) setName: (NSString *)aName
{
	NILARG_EXCEPTION_TEST(aName);
	name = aName;
}

- (NSString *) displayName
{
	return [self name];
}

/** Returns the aspect bound to the given key.

Might return an aliased aspect name rather than an aspect object. You should 
usually use -resolvedAspectForKey: than this method.

See also -setAspect:forKey:. */
- (id) aspectForKey: (NSString *)aKey
{
	FOREACH(_aspectEntries, pair, ETKeyValuePair *)
	{
		if ([[pair key] isEqualToString: aKey])
		{
			return [pair value];
		}
	}
	return nil;
}

- (BOOL) isValidAspect: (id)anAspect
{
	BOOL isAspectAliasedName = ([anAspect isString] && [anAspect hasPrefix: @"@"]);

	if (isAspectAliasedName)
		return YES;

	if ([[self allowedAspectTypes] isEmpty])
		return YES;

	ETUTI *aspectType = [ETUTI typeWithClass: [anAspect class]];
	BOOL isValidAspect = NO;

	for (ETUTI *allowedType in [self allowedAspectTypes])
	{
		if ([aspectType conformsToType: allowedType])
		{
			isValidAspect = YES;
			break;
		}
	}

	return isValidAspect;
}

- (void) insertAspect: (id)anAspect forKey: (NSString *)aKey atIndex: (NSUInteger)anIndex
{
	NILARG_EXCEPTION_TEST(anAspect);
	NILARG_EXCEPTION_TEST(aKey);

	if ([self isValidAspect: anAspect] == NO)
	{
		ETUTI *aspectType = [ETUTI typeWithClass: [anAspect class]];

		[NSException raise: NSInvalidArgumentException 
		            format: @"Cannot insert %@. Aspect type %@ not allowed in %@",
		                    anAspect, aspectType, self];
	}
	[self willChangeValueForProperty: @"aspectEntries"];

	ETKeyValuePair *pair = [[ETKeyValuePair alloc] initWithKey: aKey value: anAspect];

	if (anIndex == ETUndeterminedIndex)
	{
		[_aspectEntries addObject: pair];
	}
	else
	{
		[_aspectEntries insertObject: pair atIndex: anIndex];
	}

	[self didChangeValueForProperty: @"aspectEntries"];
}

/** Sets the aspect bound to the given key.

Aspects are kept ordered. The aspect is then inserted in last position "rather 
than randomly", when no aspect has been bound to this key yet.

The ordering is visible in the key-value pairs returned by -contentArray.

The first argument can be an aspect object or an aliased aspect name.<br />
A valid aliased name is some aspect name present in the same category and 
prefixed with <em>@</em>.<br />
See the example in the ETAspectCategory description 
and -resolvedAspectForKey:. */
- (void) setAspect: (id)anAspect forKey: (NSString *)aKey
{
	// TODO: Pass the right index if the key is already present
	[self insertAspect: anAspect forKey: aKey atIndex: ETUndeterminedIndex];
}

/** Removes the aspect bound to the given key. */
- (void) removeAspectForKey: (NSString *)aKey
{
	[self willChangeValueForProperty: @"aspectEntries"];
	[_aspectEntries removeObject: [self aspectForKey: aKey]];
	[self didChangeValueForProperty: @"aspectEntries"];
}

/** Returns all the aspect keys. */
- (NSArray *) aspectKeys
{
	return (id)[[_aspectEntries mappedCollection] key];
}

/** Returns all the aspect objects and aliased aspect names.

Aliased aspect names are not resolved in the returned array. */
- (NSArray *) aspects
{
	return (id)[[_aspectEntries mappedCollection] value];
}

/** Returns the aspect object bound to the given key, by resolving aliased 
aspect names until the result is a valid aspect object or nil.

See also -aspectForKey:. */
- (id) resolvedAspectForKey: (NSString *)aKey
{
	id value = [self aspectForKey: aKey];

	if ([value isString] && [value hasPrefix: @"@"])
	{
		value = [self resolvedAspectForKey: aKey];
	}

	return value;
}

/** @taskunit Collection Protocols */

/** Returns YES. */
- (BOOL) isOrdered
{
	return YES;
}

/** Returns YES. */
- (BOOL) isKeyed
{
	return YES;
}

/** Returns a key-value pair collection as an array copy.

See ETKeyValuePair and ETKeyedCollection. */
- (NSArray *) arrayRepresentation
{
	return [NSArray arrayWithArray: _aspectEntries];
}

/** Returns a key-value pair collection.

See ETKeyValuePair. */
- (id) content
{
	return _aspectEntries;
}

/** Returns the same than -aspects. */
- (id) contentArray
{
	return [NSArray arrayWithArray: [self aspects]];
}

/** Returns the enumerator that corresponds to -aspects. */
- (NSEnumerator *) objectEnumerator
{
	return [[self aspects] objectEnumerator];
}

- (void) insertObject: (id)object atIndex: (NSUInteger)index hint: (id)hint
{
	id aspect = object;
	NSString *key = nil;

	if ([hint isKeyValuePair])
	{
		aspect = [hint value];
		key = [hint key];
		ETAssert(object == nil || object == aspect);
	}
	else
	{
		// TODO: Add a counter to support multiple Untitled aspects
		key = @"Untitled";
	}

	[self insertAspect: aspect forKey: key atIndex: index];
}

- (void) removeObject: (id)object atIndex: (NSUInteger)index hint: (id)hint
{
	id aspect = object;
	NSString *key = nil;

	if ([hint isKeyValuePair])
	{
		aspect = [hint value];
		key = [hint key];
		ETAssert(object == nil || object == aspect);
	}

	if (index == ETUndeterminedIndex)
	{
		[self removeAspectForKey: key];
	}
	else
	{
		[_aspectEntries removeObjectAtIndex: index];
	}
}

@end
