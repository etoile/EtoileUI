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
#import "ETLayoutItem.h"

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

	NSArray *persistentProperties = @[name, transformCode, reverseTransformCode];

	[entity setUIBuilderPropertyNames: (id)[[@[name, transformCode,
		reverseTransformCode] mappedCollection] name]];

	[entity setPropertyDescriptions: persistentProperties];

	return entity;
}

+ (void) registerAspects
{
	// TODO: It's a bit useless to register value transformers in this way.
	// For ETBooleanFromMaskTransformer, the client must copy it or we
	// must override -valueTransformerForName: to return copy
	// value transformers that support/require copy.
	[self setValueTransformer: [ETBooleanFromMaskTransformer new]
	                  forName: kETBooleanFromMaskTransformerName];
	[self setValueTransformer: [ETNegateBooleanTransformer new]
	                  forName: kETNegateBooleanTransformerName];
}

- (instancetype) initWithName: (NSString *)aName;
{
	NILARG_EXCEPTION_TEST(aName);
	SUPERINIT;
	[self setName: aName];
	return self;
}

- (instancetype) init
{
	return [self initWithName: nil];
}

- (void) setName: (NSString *)aName
{
	NILARG_EXCEPTION_TEST(aName);
	
	// TODO: Write test to ensure that -setName: lets us change the name under
	// which a transformer is registered.

	if ([[ETItemValueTransformer valueTransformerNames] containsObject: aName])
	{
		ETItemValueTransformer *registeredTransformer =
			(id)[ETItemValueTransformer valueTransformerForName: aName];

		// TODO: Explain that a transformer cannot overwrite another transformer,
		// and be registered twice using a new instance (see the API documentation).
		INVALIDARG_EXCEPTION_TEST(aName, registeredTransformer == self);

		[ETItemValueTransformer setValueTransformer: nil forName: aName];
	}
	if ([[ETItemValueTransformer valueTransformerNames] containsObject: _name])
	{
		ETItemValueTransformer *registeredTransformer =
			(id)[ETItemValueTransformer valueTransformerForName: _name];
		
		// TODO: Explain that a transformer cannot overwrite another transformer,
		// and be registered twice using a new instance (see the API documentation).
		INVALIDARG_EXCEPTION_TEST(_name, registeredTransformer == self);

		[ETItemValueTransformer setValueTransformer: nil forName: _name];
	}

	_name = aName;
	[ETItemValueTransformer setValueTransformer: self forName: aName];
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


NSString * const kETNegateBooleanTransformerName = @"kETNegateBooleanTransformerName";

@implementation ETNegateBooleanTransformer

- (instancetype) init
{
	return [super initWithName: kETNegateBooleanTransformerName];
}

- (id) transformedValue: (id)value
				 forKey: (NSString *)key
				 ofItem: (ETLayoutItem *)item
{
	return [NSNumber numberWithBool: ![value boolValue]];
}

- (id) reverseTransformedValue: (id)value
						forKey: (NSString *)key
						ofItem: (ETLayoutItem *)item
{
	return [NSNumber numberWithBool: ![value boolValue]];
}

@end


NSString * const kETBooleanFromMaskTransformerName = @"kETBooleanFromMaskTransformerName";

@implementation ETBooleanFromMaskTransformer

@synthesize editedBitValue = _editedBitValue;

- (instancetype) init
{
	return [super initWithName: kETBooleanFromMaskTransformerName];
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

	return  @(mask);
}

@end
