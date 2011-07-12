/*
	Copyright (C) 2011 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  June 2011
	License: Modified BSD (see COPYING)
 */

#import <EtoileFoundation/EtoileFoundation.h>
#import "ETUIItem.h"

@interface ETUIItem (ModelDescription)
@end

@implementation ETUIItem (ModelDescription)

+ (ETEntityDescription *) newEntityDescription
{
	ETEntityDescription *entity = [self newBasicEntityDescription];

	// For subclasses that don't override -newEntityDescription, we must not add 
	// the property descriptions that we will inherit through the parent
	if ([[entity name] isEqual: [ETUIItem className]] == NO) 
		return entity;


	// FIXME: For now, ETLayoutItem description declares flipped

	ETPropertyDescription *decoratorItem = [ETPropertyDescription descriptionWithName: @"decoratorItem" type: (id)@"ETUIItem"];
	[decoratorItem setOpposite: (id)@"ETDecoratorItem.decoratedItem"];

	// TODO: Declare the numerous derived (implicitly transient) properties we have

	/* Transient properties: 	
	   _supervisorView
	   usesWidgetView, displayView, lastDecoratorItem, decoratedItem, 
	   firstDecoratedItem, decorationRect, isDecoratorItem, isWindowItem, 
	   isScrollableAreaItem, nextResponder, shouldSyncSupervisorViewGeometry */

	[entity setPropertyDescriptions: A(decoratorItem)];

	return entity;
}

@end
