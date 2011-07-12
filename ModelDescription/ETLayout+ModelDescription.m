/*
	Copyright (C) 2011 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  June 2011
	License: Modified BSD (see COPYING)
 */

#import <EtoileFoundation/EtoileFoundation.h>
#import "ETLayout.h"

@interface ETLayout (ModelDescription)
@end

@implementation ETLayout (ModelDescription)

+ (ETEntityDescription *) newEntityDescription
{
	ETEntityDescription *entity = [self newBasicEntityDescription];

	// For subclasses that don't override -newEntityDescription, we must not add 
	// the property descriptions that we will inherit through the parent
	if ([[entity name] isEqual: [ETLayout className]] == NO) 
		return entity;

	// TODO: Type should be ETLayoutItem
	ETPropertyDescription *context = 
		[ETPropertyDescription descriptionWithName: @"layoutContext" type: (id)@"ETLayoutItemGroup"];
	[context setOpposite: (id)@"ETLayoutItemGroup.layout"];

	/* Transient properties
	   _layoutContext (weak ref) */

	[entity setPropertyDescriptions: A(context)];

	return entity;
}

@end