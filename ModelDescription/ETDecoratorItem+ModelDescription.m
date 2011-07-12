
/*
	Copyright (C) 2011 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  July 2011
	License: Modified BSD (see COPYING)
 */

#import <EtoileFoundation/EtoileFoundation.h>
#import "ETDecoratorItem.h"

@interface ETDecoratorItem (ModelDescription)
@end

@implementation ETDecoratorItem (ModelDescription)

+ (ETEntityDescription *) newEntityDescription
{
	ETEntityDescription *entity = [self newBasicEntityDescription];

	// For subclasses that don't override -newEntityDescription, we must not add 
	// the property descriptions that we will inherit through the parent
	if ([[entity name] isEqual: [ETDecoratorItem className]] == NO) 
		return entity;

	// TODO: Type should be ETLayoutItem
	ETPropertyDescription *decoratedItem = 
		[ETPropertyDescription descriptionWithName: @"decoratedItem" type: (id)@"ETUIItem"];
	[decoratedItem setOpposite: (id)@"ETUIItem.decoratorItem"];

	/* Transient properties
	   _decoratedItem (weak ref) */

	[entity setPropertyDescriptions: A(decoratedItem)];

	return entity;
}

@end
