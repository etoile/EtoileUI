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
#import <EtoileFoundation/Macros.h>
#import "ETAspectCategory.h"
#import "ETCompatibility.h"


@implementation ETAspectCategory

@synthesize name, allowedAspectTypes;

/** Returns the UTI type at the top of the type hierarchy which can be used to 
represent we accept any object as a valid aspect. */
+ (ETUTI *) anyType
{
	return [ETUTI typeWithString: @"public.data"];
}

/** <init />
Initializes and returns a new category whose content includes the given 
dictionary entries.

The string value of +anyType is set as the category name. */
- (id) initWithDictionary: (NSDictionary *)aDict
{
	SUPERINIT;
	if (nil == aDict)
	{
		_aspects = [[NSMutableArray alloc] init];
	}
	else
	{
		_aspects = [[aDict arrayRepresentation] mutableCopy];
	}
	allowedAspectTypes = [[NSSet alloc] initWithObjects: [[self class] anyType], nil];
	ASSIGN(name, [[[self class] anyType] stringValue]);
	return self;
}

/** Initializes and returns a new empty category. */
- (id) init
{
	return [self initWithDictionary: nil];
}

- (void) dealloc
{
	DESTROY(_aspects);
	DESTROY(allowedAspectTypes);
	DESTROY(name);
	[super dealloc];
}

- (void) setName: (NSString *)aName
{
	NILARG_EXCEPTION_TEST(aName);
	ASSIGN(name, aName);
}

/** Returns the aspect bound to the given key.

Might return an aliased aspect name rather than an aspect object. You should 
usually use -resolvedAspectForKey: than this method.

See also -setAspect:forKey:. */
- (id) aspectForKey: (NSString *)aKey
{
	FOREACH(_aspects, pair, ETKeyValuePair *)
	{
		if ([[pair key] isEqualToString: aKey])
		{
			return [pair value];
		}
	}
	return nil;
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
	ETKeyValuePair *pair = [[ETKeyValuePair alloc] initWithKey: aKey value: anAspect];
	[_aspects addObject: pair];
	RELEASE(pair);
}

/** Removes the aspect bound to the given key. */
- (void) removeAspectForKey: (NSString *)aKey
{
	[_aspects removeObject: [self aspectForKey: aKey]];
}

/** Returns all the aspect keys. */
- (NSArray *) aspectKeys
{
	return (id)[[_aspects mappedCollection] key];
}

/** Returns all the aspect objects and aliased aspect names.

Aliased aspect names are not resolved in the returned array. */
- (NSArray *) aspects
{
	return (id)[[_aspects mappedCollection] value];
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

@end
