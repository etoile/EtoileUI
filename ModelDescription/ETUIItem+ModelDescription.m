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

	/* We declare only the transient properties that matters for a UI builder or 
	   document editor, because viewing or editing them in an inspector is useful. */

	ETPropertyDescription *usesWidgetView = [ETPropertyDescription descriptionWithName: @"usesWidgetView" type: (id)@"BOOL"];
	ETPropertyDescription *flipped = [ETPropertyDescription descriptionWithName: @"flipped" type: (id)@"BOOL"];
	ETPropertyDescription *supervisorView = [ETPropertyDescription descriptionWithName: @"supervisorView" type: (id)@"NSView"];
	ETPropertyDescription *decoratorItem = [ETPropertyDescription descriptionWithName: @"decoratorItem" type: (id)@"ETUIItem"];
	[decoratorItem setOpposite: (id)@"ETDecoratorItem.decoratedItem"];
	ETPropertyDescription *decoratedItem = [ETPropertyDescription descriptionWithName: @"decoratedItem" type: (id)@"ETUIItem"];
	ETPropertyDescription *firstDecoratedItem = [ETPropertyDescription descriptionWithName: @"firstDecoratedItem" type: (id)@"ETUIItem"];
	ETPropertyDescription *lastDecoratorItem = [ETPropertyDescription descriptionWithName: @"lastDecoratorItem" type: (id)@"ETDecoratorItem"];
	ETPropertyDescription *decorationRect = [ETPropertyDescription descriptionWithName: @"decorationRect" type: (id)@"NSRect"];
	ETPropertyDescription *enclosingItem = [ETPropertyDescription descriptionWithName: @"enclosingItem" type: (id)@"ETUIItem"];
	ETPropertyDescription *nextResponder = [ETPropertyDescription descriptionWithName: @"nextResponder" type: (id)@"NSObject"];
	
	[decoratorItem setPersistent: YES];

	NSArray *derivedProperties = @[usesWidgetView, flipped, decoratedItem,
		firstDecoratedItem, lastDecoratorItem, decorationRect, enclosingItem,
		nextResponder];

	[[derivedProperties mappedCollection] setDerived: YES];
	[[derivedProperties mappedCollection] setReadOnly: YES];

	[entity setPropertyDescriptions: [@[supervisorView, decoratorItem]
		arrayByAddingObjectsFromArray: derivedProperties]];

	return entity;
}

@end
