/*
	Copyright (C) 2014 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  April 2014
	License: Modified BSD (see COPYING)
 */

#import "ETItemValueTransformerToString.h"
#import "ETItemValueTransformer.h"
#import "ETCompatibility.h"

@implementation ETItemValueTransformerToString

+ (Class) transformedValueClass
{
	return [NSString class];
}

+ (BOOL) allowsReverseTransformation
{
	return YES;
}

- (id) transformedValue: (id)value
{
	NSParameterAssert([value isKindOfClass: [ETItemValueTransformer class]]);

	return [value name];
}

- (id) reverseTransformedValue: (id)value
{
	NSParameterAssert([value isKindOfClass: [NSString class]]);

	return [ETItemValueTransformer valueTransformerForName: value];
}

@end

