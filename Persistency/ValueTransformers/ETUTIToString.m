/*
	Copyright (C) 2014 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  June 2014
	License: Modified BSD (see COPYING)
 */

#import <EtoileFoundation/ETUTI.h>
#import "ETUTIToString.h"
#import "ETCompatibility.h"

@implementation ETUTIToString

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
	NSParameterAssert(value == nil || [value isKindOfClass: [ETUTI class]]);

	return [value stringValue];
}

- (id) reverseTransformedValue: (id)value
{
	NSParameterAssert(value == nil || [value isKindOfClass: [NSString class]]);

	return (value != nil ? [ETUTI typeWithString: value] : nil);
}

@end

