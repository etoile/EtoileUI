/*
	Copyright (C) 2013 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  December 2013
	License: Modified BSD (see COPYING)
 */

#import <EtoileFoundation/EtoileFoundation.h>
#import "ETTool.h"
#import "ETIconLayout.h"
#import "ETMoveTool.h"
#import "ETPaintBucketTool.h"
#import "ETSelectTool.h"

@interface ETTool (ModelDescrition)
@end

@interface ETMoveTool (ModelDescrition)
@end

@interface ETSelectTool (ModelDescrition)
@end

@interface ETSelectAndClickTool (ModelDescrition)
@end

@interface ETPaintBucketTool (ModelDescrition)
@end


@implementation ETTool (ModelDescription)

+ (ETEntityDescription *) newEntityDescription
{
	ETEntityDescription *entity = [self newBasicEntityDescription];

	// For subclasses that don't override -newEntityDescription, we must not add 
	// the property descriptions that we will inherit through the parent.
	if ([[entity name] isEqual: [ETTool className]] == NO)
		return entity;

	ETPropertyDescription *layoutOwner =
		[ETPropertyDescription descriptionWithName: @"layoutOwner" type: (id)@"ETLayout"];
	[layoutOwner setDerived: YES];
	[layoutOwner setOpposite: (id)@"ETLayout.attachedTool"];
	ETPropertyDescription *cursorName =
		[ETPropertyDescription descriptionWithName: @"cursorName" type: (id)@"NSString"];

	NSArray *transientProperties = A(layoutOwner);
	NSArray *persistentProperties = A(cursorName);

	[[persistentProperties mappedCollection] setPersistent: YES];

	[entity setPropertyDescriptions:
		[persistentProperties arrayByAddingObjectsFromArray: transientProperties]];

	return entity;
}

@end


@implementation ETMoveTool (ModelDescription)

+ (ETEntityDescription *) newEntityDescription
{
	ETEntityDescription *entity = [self newBasicEntityDescription];

	// For subclasses that don't override -newEntityDescription, we must not add 
	// the property descriptions that we will inherit through the parent.
	if ([[entity name] isEqual: [ETMoveTool className]] == NO)
		return entity;

	ETPropertyDescription *movedItem =
		[ETPropertyDescription descriptionWithName: @"movedItem" type: (id)@"ETLayoutItem"];
	ETPropertyDescription *shouldProduceTranslate =
		[ETPropertyDescription descriptionWithName: @"shouldProduceTranslateActions" type: (id)@"BOOL"];
	[shouldProduceTranslate setPersistent: YES];

	[entity setPropertyDescriptions: A(movedItem, shouldProduceTranslate)];

	return entity;
}

@end


@implementation ETSelectTool (ModelDescription)

+ (ETEntityDescription *) newEntityDescription
{
	ETEntityDescription *entity = [self newBasicEntityDescription];

	// For subclasses that don't override -newEntityDescription, we must not add 
	// the property descriptions that we will inherit through the parent.
	if ([[entity name] isEqual: [ETSelectTool className]] == NO)
		return entity;

	ETPropertyDescription *selectionAreaItem =
		[ETPropertyDescription descriptionWithName: @"selectionAreaItem" type: (id)@"ETLayoutItem"];
	ETPropertyDescription *multipleSelectionAllowed =
		[ETPropertyDescription descriptionWithName: @"multipleSelectionAllowed" type: (id)@"BOOL"];
	ETPropertyDescription *emptySelectionAllowed =
		[ETPropertyDescription descriptionWithName: @"emptySelectionAllowed" type: (id)@"BOOL"];
	ETPropertyDescription *removesItemsAtPickTime =
		[ETPropertyDescription descriptionWithName: @"removesItemsAtPickTime" type: (id)@"BOOL"];
	ETPropertyDescription *forcesItemPick =
		[ETPropertyDescription descriptionWithName: @"forcesItemPick" type: (id)@"BOOL"];
	ETPropertyDescription *actionHandlerPrototype =
		[ETPropertyDescription descriptionWithName: @"actionHandlerPrototype" type: (id)@"ETActionHandler"];

	NSArray *transientProperties = A(actionHandlerPrototype);
	NSArray *persistentProperties = A(selectionAreaItem, multipleSelectionAllowed,
		emptySelectionAllowed, removesItemsAtPickTime, forcesItemPick);

	[[persistentProperties mappedCollection] setPersistent: YES];

	[entity setPropertyDescriptions:
		[persistentProperties arrayByAddingObjectsFromArray: transientProperties]];

	return entity;
}

@end


@implementation ETSelectAndClickTool (ModelDescription)

+ (ETEntityDescription *) newEntityDescription
{
	ETEntityDescription *entity = [self newBasicEntityDescription];

	// For subclasses that don't override -newEntityDescription, we must not add 
	// the property descriptions that we will inherit through the parent.
	if ([[entity name] isEqual: [ETSelectAndClickTool className]] == NO)
		return entity;

	ETPropertyDescription *ignoresBackgroundClick =
		[ETPropertyDescription descriptionWithName: @"ignoresBackgroundClick" type: (id)@"BOOL"];
	[ignoresBackgroundClick setPersistent: YES];

	[entity addPropertyDescription: ignoresBackgroundClick];

	return entity;
}

@end


@implementation ETPaintBucketTool (ModelDescription)

+ (ETEntityDescription *) newEntityDescription
{
	ETEntityDescription *entity = [self newBasicEntityDescription];

	// For subclasses that don't override -newEntityDescription, we must not add 
	// the property descriptions that we will inherit through the parent.
	if ([[entity name] isEqual: [ETPaintBucketTool className]] == NO)
		return entity;

	ETPropertyDescription *fillColor =
		[ETPropertyDescription descriptionWithName: @"fillColor" type: (id)@"NSColor"];
	fillColor.persistentTypeName = @"NSString";
	fillColor.valueTransformerName = @"COColorToHTMLString";
	ETPropertyDescription *strokeColor =
		[ETPropertyDescription descriptionWithName: @"strokeColor" type: (id)@"NSColor"];
	strokeColor.persistentTypeName = @"NSString";
	strokeColor.valueTransformerName = @"COColorToHTMLString";
	ETPropertyDescription *paintMode =
		[ETPropertyDescription descriptionWithName: @"paintMode" type: (id)@"NSUInteger"];

	NSArray *persistentProperties = A(fillColor, strokeColor, paintMode);
	
	[[persistentProperties mappedCollection] setPersistent: YES];

	[entity setPropertyDescriptions: persistentProperties];

	return entity;
}

@end
