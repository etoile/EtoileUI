/*
	Copyright (C) 2014 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  June 2014
	License: Modified BSD (see COPYING)
 */

#import <EtoileFoundation/ETUUID.h>
#import "ETUUIDToString.h"
#import "ETCompatibility.h"

@implementation ETUUIDToString

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
	NSParameterAssert(value == nil || [value isKindOfClass: [ETUUID class]]);

	return [value stringValue];
}

- (id) reverseTransformedValue: (id)value
{
	NSParameterAssert(value == nil || [value isKindOfClass: [NSString class]]);

	return (value != nil ? [ETUUID UUIDWithString: value] : nil);
}

@end

