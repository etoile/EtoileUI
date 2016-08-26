
/*
	Copyright (C) 2011 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  July 2011
	License: Modified BSD (see COPYING)
 */

#import <EtoileFoundation/EtoileFoundation.h>
#import "ETDecoratorItem.h"
#import "ETScrollableAreaItem.h"
#import "ETTitleBarItem.h"
#import "ETWindowItem.h"

@interface ETDecoratorItem (ModelDescription)
@end

@interface ETScrollableAreaItem (ModelDescription)
@end

@interface ETTitleBarItem (ModelDescription)
@end

@interface ETWindowItem (ModelDescription)
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
	[decoratedItem setDerived: YES];
	[decoratedItem setOpposite: (id)@"ETUIItem.decoratorItem"];
	ETPropertyDescription *visibleRect =
		[ETPropertyDescription descriptionWithName: @"visible" type: (id)@"NSRect"];
	[visibleRect setReadOnly: YES];
	[visibleRect setDerived: YES];
	ETPropertyDescription *visibleContentRect =
		[ETPropertyDescription descriptionWithName: @"visibleContentRect" type: (id)@"NSRect"];
	[visibleContentRect setReadOnly: YES];
	[visibleContentRect setDerived: YES];
	ETPropertyDescription *contentRect =
		[ETPropertyDescription descriptionWithName: @"contentRect" type: (id)@"NSRect"];
	[contentRect setReadOnly: YES];
	[contentRect setDerived: YES];
	// NOTE: We override ETUIItem.flipped to become read/write.
	ETPropertyDescription *flipped =
		[ETPropertyDescription descriptionWithName: @"flipped" type: (id)@"BOOL"];
	[flipped setDerived: YES];

	[entity setPropertyDescriptions: @[decoratedItem]];

	return entity;
}

@end


@implementation ETScrollableAreaItem (ModelDescription)

+ (ETEntityDescription *) newEntityDescription
{
	ETEntityDescription *entity = [self newBasicEntityDescription];

	// For subclasses that don't override -newEntityDescription, we must not add 
	// the property descriptions that we will inherit through the parent
	if ([[entity name] isEqual: [ETScrollableAreaItem className]] == NO)
		return entity;

	ETPropertyDescription *hasVerticalScroller =
		[ETPropertyDescription descriptionWithName: @"hasVerticalScroller" type: (id)@"BOOL"];
	ETPropertyDescription *hasHorizontalScroller =
		[ETPropertyDescription descriptionWithName: @"hasHorizontalScroller" type: (id)@"BOOL"];
	ETPropertyDescription *ensuresContentFillsVisibleArea =
		[ETPropertyDescription descriptionWithName: @"ensuresContentFillsVisibleArea" type: (id)@"BOOL"];
	ETPropertyDescription *oldDecoratedItemAutoresizingMask =
		[ETPropertyDescription descriptionWithName: @"oldDecoratedItemAutoresizingMask" type: (id)@"NSUInteger"];

	NSArray *persistentProperties =
		@[ensuresContentFillsVisibleArea, oldDecoratedItemAutoresizingMask];
	NSArray *transientProperties = @[hasVerticalScroller, hasHorizontalScroller];

	[[persistentProperties mappedCollection] setPersistent: YES];

	[entity setPropertyDescriptions:
	 	[persistentProperties arrayByAddingObjectsFromArray:transientProperties]];

	return entity;
}

@end


@implementation ETTitleBarItem (ModelDescription)

+ (ETEntityDescription *) newEntityDescription
{
	ETEntityDescription *entity = [self newBasicEntityDescription];

	// For subclasses that don't override -newEntityDescription, we must not add 
	// the property descriptions that we will inherit through the parent
	if ([[entity name] isEqual: [ETTitleBarItem className]] == NO)
		return entity;

	ETPropertyDescription *titleBarView =
		[ETPropertyDescription descriptionWithName: @"titleBarView" type: (id)@"NSView"];
	[titleBarView setValueTransformerName: @"COObjectToArchivedData"];
	[titleBarView setPersistentTypeName: @"NSData"];
	ETPropertyDescription *titleBarHeight =
		[ETPropertyDescription descriptionWithName: @"titleBarHeight" type: (id)@"CGFloat"];
	[titleBarHeight setReadOnly: YES];
	[titleBarHeight setDerived: YES];
	ETPropertyDescription *expanded =
		[ETPropertyDescription descriptionWithName: @"expanded" type: (id)@"BOOL"];
	[expanded setReadOnly: YES];
	[expanded setDerived: YES];

	[titleBarView setPersistent: YES];

	[entity setPropertyDescriptions: @[titleBarView, titleBarHeight, expanded]];

	return entity;
}

@end


@implementation ETWindowItem (ModelDescription)

+ (ETEntityDescription *) newEntityDescription
{
	ETEntityDescription *entity = [self newBasicEntityDescription];

	// For subclasses that don't override -newEntityDescription, we must not add 
	// the property descriptions that we will inherit through the parent
	if ([[entity name] isEqual: [ETWindowItem className]] == NO)
		return entity;

	/* Transient Properties */

	ETPropertyDescription *itemWindow =
		[ETPropertyDescription descriptionWithName: @"itemWindow" type: (id)@"NSWindow"];
	[itemWindow setValueTransformerName: @"COObjectToArchivedData"];
	[itemWindow setPersistentTypeName: @"NSData"];
	ETPropertyDescription *shouldKeepWindowFrame =
		[ETPropertyDescription descriptionWithName: @"shouldKeepWindowFrame" type: (id)@"BOOL"];
	ETPropertyDescription *oldDecoratedItemAutoresizingMask =
		[ETPropertyDescription descriptionWithName: @"oldDecoratedItemAutoresizingMask" type: (id)@"NSUInteger"];
	// NOTE: We override ETUIItem.flipped to become persistent.
	ETPropertyDescription *flipped =
		[ETPropertyDescription descriptionWithName: @"flipped" type: (id)@"BOOL"];

	/* Transient Properties */

	ETPropertyDescription *isUntitled =
		[ETPropertyDescription descriptionWithName: @"isUntitled" type: (id)@"BOOL"];
	[isUntitled setReadOnly: YES];
	[isUntitled setDerived: YES];
	ETPropertyDescription *usesCustomWindowTitle =
		[ETPropertyDescription descriptionWithName: @"usesCustomWindowTitle" type: (id)@"BOOL"];
	[usesCustomWindowTitle setReadOnly: YES];
	[usesCustomWindowTitle setDerived: YES];
	ETPropertyDescription *titleBarHeight =
		[ETPropertyDescription descriptionWithName: @"titleBarHeight" type: (id)@"CGFloat"];
	[titleBarHeight setReadOnly: YES];
	[titleBarHeight setDerived: YES];
	/* Focused item and edited item can be persistent, but not as part of the UI, 
	   but as part of the UI state restoration, see ETUIStateRestoration. */
	ETPropertyDescription *focusedItem =
		[ETPropertyDescription descriptionWithName: @"focusedItem" type: (id)@"ETLayoutItem"];
	[focusedItem setReadOnly: YES];
	ETPropertyDescription *editedItem =
		[ETPropertyDescription descriptionWithName: @"editedItem" type: (id)@"ETLayoutItem"];
	ETPropertyDescription *activeFieldEditorItem =
		[ETPropertyDescription descriptionWithName: @"activeFieldEditorItem" type: (id)@"ETLayoutItem"];

	NSArray *persistentProperties = @[itemWindow, shouldKeepWindowFrame,
		oldDecoratedItemAutoresizingMask, flipped];
	NSArray *transientProperties = @[isUntitled, usesCustomWindowTitle,
		titleBarHeight, focusedItem, editedItem, activeFieldEditorItem];
	
	[[persistentProperties mappedCollection] setPersistent: YES];
	
	[entity setPropertyDescriptions:
		[persistentProperties arrayByAddingObjectsFromArray:transientProperties]];


	return entity;
}

@end
