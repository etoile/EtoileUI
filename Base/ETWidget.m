/*
	Copyright (C) 2013 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  May 2013
	License: Modified BSD (see COPYING)
 */

#import <EtoileFoundation/NSObject+Trait.h>
#import <EtoileFoundation/NSObject+Model.h>
#import "ETWidget.h"
#import "ETLayoutItem.h"
#import "ETCompatibility.h"


@implementation ETLayoutItem (ETWidgetProxy)

- (id) objectValue
{
	id value = [self value];
	return (value != nil ? value : [super objectValue]);
}

- (void) setObjectValue: (id)aValue
{
	[self setValue: aValue];
}

// TODO: Implement formatter property

- (id) formatter
{
	return nil;
}

- (void) setFormatter: (NSFormatter *)aFormatter
{
	
}

- (NSActionCell *) cell
{
	return nil;
}

@end

