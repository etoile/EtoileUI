/*
	Copyright (C) 2014 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  April 2014
	License: Modified BSD (see COPYING)
 */

#import "ETCollectionToPersistentCollection.h"
#import "ETCompatibility.h"


@interface ETIdentityValueTransformer : NSValueTransformer
@end

@implementation ETIdentityValueTransformer

+ (Class) transformedValueClass
{
	return [NSObject class];
}

+ (BOOL) allowsReverseTransformation
{
	return YES;
}

- (id) transformedValue: (id)value
{
	return value;
}

- (id) reverseTransformedValue: (id)value
{
	return value;
}

@end


@implementation ETCollectionToPersistentCollection

@synthesize valueTransformerName = _valueTransformerName;
@synthesize keyTransformerName = _keyTransformerName;

+ (Class) transformedValueClass
{
	// NOTE: We should return NSObject may be.
	ETAssertUnreachable();
	return Nil;
}

+ (BOOL) allowsReverseTransformation
{
	return YES;
}

static ETIdentityValueTransformer *identityTransformer = nil;

+ (void) initialize
{
	if (self != [ETCollectionToPersistentCollection class])
		return;

	identityTransformer = [ETIdentityValueTransformer new];
}

- (NSValueTransformer *) valueTransformer
{
	if ([self valueTransformerName] == nil)
		return identityTransformer;
	
	return [NSValueTransformer valueTransformerForName: [self valueTransformerName]];
}

- (NSValueTransformer *) keyTransformer
{
	if ([self keyTransformerName] == nil)
		return identityTransformer;
	
	return [NSValueTransformer valueTransformerForName: [self keyTransformerName]];
}

- (id) transformedValue: (id)collection
{
	NSParameterAssert([collection conformsToProtocol: @protocol(ETCollection)]);

	NSValueTransformer *keyTransformer = [self keyTransformer];
	NSValueTransformer *valueTransformer = [self valueTransformer];
	id serializedCollection =
		[[[collection mutableClass] alloc] initWithCapacity: [collection count]];

	if (keyTransformer != nil)
	{
		ETAssert([collection isKeyed]);

		[collection enumerateKeysAndObjectsUsingBlock: ^ (id key, id obj, BOOL *stop)
		{
			serializedCollection[[keyTransformer transformedValue: key]] = [valueTransformer transformedValue: obj];
		}];
	}
	else
	{
		for (id obj in collection)
		{
			[serializedCollection addObject: [valueTransformer transformedValue: obj]];
		}
	}
	return serializedCollection;
}

- (id) reverseTransformedValue: (id)serializedCollection
{
	NSParameterAssert([serializedCollection conformsToProtocol: @protocol(ETCollection)]);

	NSValueTransformer *keyTransformer = [self keyTransformer];
	NSValueTransformer *valueTransformer = [self valueTransformer];
	id collection =
		[[[serializedCollection mutableClass] alloc] initWithCapacity: [serializedCollection count]];

	if (keyTransformer != nil)
	{
		ETAssert([serializedCollection isKeyed]);

		[serializedCollection enumerateKeysAndObjectsUsingBlock: ^ (id key, id obj, BOOL *stop)
		{
			collection[[keyTransformer reverseTransformedValue: key]] = [valueTransformer reverseTransformedValue: obj];
		}];
	}
	else
	{
		for (id obj in serializedCollection)
		{
			[collection addObject: [valueTransformer reverseTransformedValue: obj]];
		}
	}

	return collection;
}

@end
