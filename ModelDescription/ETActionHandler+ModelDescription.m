/*
	Copyright (C) 2011 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  June 2011
	License: Modified BSD (see COPYING)
 */

#import <EtoileFoundation/EtoileFoundation.h>
#import "ETActionHandler.h"
#import "ETTokenLayout.h"

@interface ETActionHandler (ModelDescription)
@end

@interface ETTokenActionHandler (ModelDescription)
@end


@implementation ETActionHandler (ModelDescription)

+ (ETEntityDescription *) newEntityDescription
{
	ETEntityDescription *entity = [self newBasicEntityDescription];

	// For subclasses that don't override -newEntityDescription, we must not add 
	// the property descriptions that we will inherit through the parent
	if ([[entity name] isEqual: [ETActionHandler className]] == NO) 
		return entity;

	ETPropertyDescription *fieldEditorItem = 
		[ETPropertyDescription descriptionWithName: @"fieldEditorItem" type: (id)@"ETLayoutItem"];
	// TODO: Remove (turn this property into a persistent one)
	[fieldEditorItem setReadOnly: YES];

	[entity setUIBuilderPropertyNames: @[[fieldEditorItem name]]];

	[entity setPropertyDescriptions: @[fieldEditorItem]];

	return entity;
}

@end


@implementation ETTokenActionHandler (ModelDescription)

+ (ETEntityDescription *) newEntityDescription
{
	ETEntityDescription *entity = [self newBasicEntityDescription];

	// For subclasses that don't override -newEntityDescription, we must not add 
	// the property descriptions that we will inherit through the parent
	if ([[entity name] isEqual: [ETTokenActionHandler className]] == NO)
		return entity;

	ETPropertyDescription *editedProperty =
		[ETPropertyDescription descriptionWithName: @"editedProperty" type: (id)@"NSString"];

	[entity setUIBuilderPropertyNames: @[[editedProperty name]]];

	[editedProperty setPersistent: YES];
	[entity setPropertyDescriptions: @[editedProperty]];

	return entity;
}

@end
