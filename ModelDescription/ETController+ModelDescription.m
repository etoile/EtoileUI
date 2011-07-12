/*
	Copyright (C) 2011 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  June 2011
	License: Modified BSD (see COPYING)
 */

#import <EtoileFoundation/EtoileFoundation.h>
#import "ETController.h"

@interface ETController (ModelDescription)
@end

@implementation ETController (ModelDescription)

+ (ETEntityDescription *) newEntityDescription
{
	ETEntityDescription *entity = [self newBasicEntityDescription];

	// For subclasses that don't override -newEntityDescription, we must not add 
	// the property descriptions that we will inherit through the parent
	if ([[entity name] isEqual: [ETController className]] == NO) 
		return entity;

	ETPropertyDescription *content = 
		[ETPropertyDescription descriptionWithName: @"content" type: (id)@"ETLayoutItemGroup"];
	[content setOpposite: (id)@"ETLayoutItemGroup.controller"];

	/* Transient properties
	   content (weak ref) */

	[entity setPropertyDescriptions: A(content)];


	return entity;
}

@end
