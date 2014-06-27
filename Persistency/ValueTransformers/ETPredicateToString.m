/*
	Copyright (C) 2014 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  June 2014
	License: Modified BSD (see COPYING)
 */

#import "ETPredicateToString.h"
#import "ETCompatibility.h"

@implementation ETPredicateToString

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
	NSParameterAssert(value == nil || [value isKindOfClass: [NSPredicate class]]);

	return [value predicateFormat];
}

- (id) reverseTransformedValue: (id)value
{
	NSParameterAssert(value == nil || [value isKindOfClass: [NSString class]]);

	return (value != nil ? [NSPredicate predicateWithFormat: value] : nil);
}

@end

