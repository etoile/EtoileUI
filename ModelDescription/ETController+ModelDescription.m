/*
	Copyright (C) 2011 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  June 2011
	License: Modified BSD (see COPYING)
 */

#import <EtoileFoundation/EtoileFoundation.h>
#import "ETController.h"
#import "ETNibOwner.h"

@interface ETNibOwner (ModelDescription)
@end

@implementation ETNibOwner (ModelDescription)

+ (ETEntityDescription *) newEntityDescription
{
	ETEntityDescription *entity = [self newBasicEntityDescription];

	// For subclasses that don't override -newEntityDescription, we must not add 
	// the property descriptions that we will inherit through the parent
	if ([[entity name] isEqual: [ETNibOwner className]] == NO) 
		return entity;

	// TODO: Declare the property descriptions

	return entity;
}

@end


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

	/* Transient ivars
	   content (weak ref) */
	NSArray *persistentProperties = A(content);

	[[persistentProperties mappedCollection] setPersistent: YES];
	[entity setPropertyDescriptions: persistentProperties];

	return entity;
}

@end
