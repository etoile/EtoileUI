/*
	Copyright (C) 2014 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  June 2014
	License: Modified BSD (see COPYING)
 */

#import "ETUTITuple.h"
#import "ETCompatibility.h"

@implementation ETUTITuple

@dynamic content;

+ (ETEntityDescription *)newEntityDescription
{
	ETEntityDescription *collection = [self newBasicEntityDescription];

	// For subclasses that don't override -newEntityDescription, we must not add the 
	// property descriptions that we will inherit through the parent
	if ([[collection name] isEqual: [ETUTITuple className]] == NO)
		return collection;

	[collection setLocalizedDescription: _(@"UTI Tuple")];

	ETPropertyDescription *content =
		[self contentPropertyDescriptionWithName: @"content"
		                                    type: @"ETUTI"
		                                opposite: nil];
    ETAssert([content isOrdered]);
    [content setValueTransformerName: @"ETUTIToString"];
    [content setPersistentTypeName: @"NSString"];

	[collection setPropertyDescriptions: @[content]];

	return collection;
}

- (NSString *) contentKey
{
    return @"content";
}

@end
