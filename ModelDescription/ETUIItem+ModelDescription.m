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

	ETPropertyDescription *supervisorView = [ETPropertyDescription descriptionWithName: @"supervisorView" type: (id)@"NSView"];
	ETPropertyDescription *decoratorItem = [ETPropertyDescription descriptionWithName: @"decoratorItem" type: (id)@"ETUIItem"];
	[decoratorItem setOpposite: (id)@"ETDecoratorItem.decoratedItem"];
	ETPropertyDescription *decoratedItem = [ETPropertyDescription descriptionWithName: @"decoratedItem" type: (id)@"ETUIItem"];
	ETPropertyDescription *firstDecoratedItem = [ETPropertyDescription descriptionWithName: @"firstDecoratedItem" type: (id)@"ETUIItem"];
	// FIXME: The type should be ETDecoratorItem
	ETPropertyDescription *lastDecoratorItem = [ETPropertyDescription descriptionWithName: @"lastDecoratorItem" type: (id)@"ETUIItem"];
	ETPropertyDescription *decorationRect = [ETPropertyDescription descriptionWithName: @"decorationRect" type: (id)@"NSRect"];
	ETPropertyDescription *isDecoratorItem = [ETPropertyDescription descriptionWithName: @"isDecoratorItem" type: (id)@"BOOL"];
	ETPropertyDescription *isWindowItem = [ETPropertyDescription descriptionWithName: @"isWindowItem" type: (id)@"BOOL"];
	ETPropertyDescription *isScrollableAreaItem = [ETPropertyDescription descriptionWithName: @"isScrollableAreaItem" type: (id)@"BOOL"];
	ETPropertyDescription *enclosingItem = [ETPropertyDescription descriptionWithName: @"enclosingItem" type: (id)@"ETUIItem"];
	ETPropertyDescription *nextResponder = [ETPropertyDescription descriptionWithName: @"nextResponder" type: (id)@"NSObject"];
	ETPropertyDescription *shouldSyncSupervisorViewGeometry = [ETPropertyDescription descriptionWithName: @"shouldSyncSupervisorView" type: (id)@"BOOL"];
	ETPropertyDescription *usesWidgetView = [ETPropertyDescription descriptionWithName: @"usesWidgetView" type: (id)@"BOOL"];
	// TODO: We could include -displayView in the transient properties
	
	/* Transient ivars: 	
	   _supervisorView */

	[entity setPropertyDescriptions: A(supervisorView, decoratorItem, decoratedItem, 
		firstDecoratedItem, lastDecoratorItem, decorationRect, isDecoratorItem, 
		isWindowItem, isScrollableAreaItem, enclosingItem, nextResponder, 
		shouldSyncSupervisorViewGeometry, usesWidgetView)];

	return entity;
}

@end
