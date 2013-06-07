/*
	Copyright (C) 2013 Quentin Mathe
 
	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  May 2013
	License:  Modified BSD (see COPYING)
 */

#import <EtoileFoundation/Macros.h>
#import <EtoileFoundation/ETCollection+HOM.h>
#import <EtoileFoundation/ETModelElementDescription.h>
#import <EtoileFoundation/ETEntityDescription.h>
#import <EtoileFoundation/ETPropertyDescription.h>
#import <EtoileFoundation/NSObject+Model.h>
#import "ETItemValueTransformer.h"

@implementation ETItemValueTransformer

@synthesize transformBlock = _transformBlock, reverseTransformBlock = _reverseTransformBlock,
	name = _name, transformCode = _transformCode, reverseTransformCode = _reverseTransformCode;

+ (ETEntityDescription *) newEntityDescription
{
	ETEntityDescription *entity = [self newBasicEntityDescription];

	// For subclasses that don't override -newEntityDescription, we must not add 
	// the property descriptions that we will inherit through the parent
	if ([[entity name] isEqual: [ETItemValueTransformer className]] == NO)
		return entity;

	ETPropertyDescription *name =
		[ETPropertyDescription descriptionWithName: @"name" type: (id)@"NSString"];
	ETPropertyDescription *transformCode =
		[ETPropertyDescription descriptionWithName: @"transformCode" type: (id)@"NSString"];
	[transformCode setDisplayName: @"Transform Block"];
	ETPropertyDescription *reverseTransformCode =
		[ETPropertyDescription descriptionWithName: @"reverseTransformCode" type: (id)@"NSString"];
	[reverseTransformCode setDisplayName: @"Reverse Transform Block"];

	NSArray *persistentProperties = A(name, transformCode, reverseTransformCode);

	[entity setUIBuilderPropertyNames: (id)[[A(name, transformCode,
		reverseTransformCode) mappedCollection] name]];

	[entity setPropertyDescriptions: persistentProperties];

	return entity;
}

+ (void) registerAspects
{
	// TODO: It's a bit useless to register value transformers in this way.
	// For ETBooleanFromMaskValueTransformer, the client must copy it or we
	// must override -valueTransformerForName: to return copy
	// value transformers that support/require copy.
	[self setValueTransformer: AUTORELEASE([ETBooleanFromMaskValueTransformer new])
	                  forName: kETBooleanFromMaskValueTransformerName];
}

- (id) init
{
	SUPERINIT
	ASSIGN(_name, _(@"Untitled"));
	return self;
}

- (void) dealloc
{
	DESTROY(_name);
	DESTROY(_transformBlock);
	DESTROY(_reverseTransformBlock);
	DESTROY(_transformCode);
	DESTROY(_reverseTransformCode);
	[super dealloc];
}

- (NSString *) displayName
{
	return [self name];
}

- (id) transformedValue: (id)value
                 forKey: (NSString *)key
                 ofItem: (ETLayoutItem *)item
{
	if (_transformBlock != NULL)
	{
		return _transformBlock(value, key, item);
	}
	return [self transformedValue: value];
}

- (id) reverseTransformedValue: (id)value
                        forKey: (NSString *)key
                        ofItem: (ETLayoutItem *)item
{
	if (_reverseTransformBlock != NULL)
	{
		return _reverseTransformBlock(value, key, item);
	}
	return [self reverseTransformedValue: value];
}

@end


NSString * const kETBooleanFromMaskValueTransformerName = @"kETBooleanFromMaskValueTransformerName";

@implementation ETBooleanFromMaskValueTransformer

@synthesize editedBitValue = _editedBitValue;

- (id) init
{
	SUPERINIT;
	[self setName: kETBooleanFromMaskValueTransformerName];
	return self;
}

- (id) transformedValue: (id)value
                 forKey: (NSString *)key
                 ofItem: (ETLayoutItem *)item
{
	return [NSNumber numberWithBool: ([value unsignedIntegerValue] & [self editedBitValue])];
}

- (id) reverseTransformedValue: (id)value
                        forKey: (NSString *)key
                        ofItem: (ETLayoutItem *)item
{
	BOOL boolValue = [value boolValue];
	NSUInteger mask = [[item valueForProperty: key] unsignedIntegerValue];

	if (boolValue)
	{
		mask |= [self editedBitValue];
	}
	else
	{
		mask &= ~[self editedBitValue];
	}

	return  [NSNumber numberWithUnsignedInteger: mask];
}

@end
