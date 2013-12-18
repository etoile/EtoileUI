/*
	Copyright (C) 2013 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  December 2013
	License: Modified BSD (see COPYING)
 */

#import <EtoileFoundation/EtoileFoundation.h>
#import "ETTool.h"
#import "ETIconLayout.h"
#import "ETInstruments.h"
#import "ETPaintBucketTool.h"
#import "ETSelectTool.h"

@interface ETTool (ModelDescrition)
@end

@interface ETPaintBucketTool (ModelDescrition)
@end


@interface ETSelectAndClickTool (ModelDescrition)
@end

@implementation ETTool (ModelDescription)

+ (ETEntityDescription *) newEntityDescription
{
	ETEntityDescription *entity = [self newBasicEntityDescription];

	// For subclasses that don't override -newEntityDescription, we must not add 
	// the property descriptions that we will inherit through the parent.
	if ([[entity name] isEqual: [ETTool className]] == NO)
		return entity;

	ETPropertyDescription *cursor = [ETPropertyDescription descriptionWithName: @"cursor" type: (id)@"NSCursor"];

	NSArray *persistentProperties = A(cursor);

	[[persistentProperties mappedCollection] setPersistent: YES];

	[entity setPropertyDescriptions: persistentProperties];

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

	ETPropertyDescription *ignoresBackgroundClick = [ETPropertyDescription descriptionWithName: @"ignoresBackgroundClick" type: (id)@"BOOL"];
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

	ETPropertyDescription *fillColor = [ETPropertyDescription descriptionWithName: @"fillColor" type: (id)@"NSColor"];
	ETPropertyDescription *strokeColor = [ETPropertyDescription descriptionWithName: @"strokeColor" type: (id)@"NSColor"];

	NSArray *persistentProperties = A(fillColor, strokeColor);
	
	[[persistentProperties mappedCollection] setPersistent: YES];

	[entity setPropertyDescriptions: persistentProperties];

	return entity;
}

@end
