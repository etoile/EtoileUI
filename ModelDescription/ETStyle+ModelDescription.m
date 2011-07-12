/*
	Copyright (C) 2011 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  June 2011
	License: Modified BSD (see COPYING)
 */

#import <EtoileFoundation/EtoileFoundation.h>
#import "ETStyle.h"
#import "ETShape.h"

@interface ETStyle (ModelDescrition)
@end

@implementation ETStyle (ModelDescription)

+ (ETEntityDescription *) newEntityDescription
{
	ETEntityDescription *entity = [self newBasicEntityDescription];

	// For subclasses that don't override -newEntityDescription, we must not add 
	// the property descriptions that we will inherit through the parent.
	if ([[entity name] isEqual: [ETStyle className]] == NO) 
		return entity;

	// Nothing to declare for now

	return entity;
}

@end


@interface ETShape (ModelDescrition)
@end

@implementation ETShape (ModelDescription)

+ (ETEntityDescription *) newEntityDescription
{
	ETEntityDescription *entity = [self newBasicEntityDescription];

	// For subclasses that don't override -newEntityDescription, we must not add 
	// the property descriptions that we will inherit through the parent
	if ([[entity name] isEqual: [ETShape className]] == NO) 
		return entity;

	ETPropertyDescription *path = [ETPropertyDescription descriptionWithName: @"path" type: (id)@"NSBezierPath"];
	ETPropertyDescription *bounds = [ETPropertyDescription descriptionWithName: @"bounds" type: (id)@"NSRect"];
	ETPropertyDescription *pathResizeSel = [ETPropertyDescription descriptionWithName: @"pathResizeSelector" type: (id)@"SEL"];
	ETPropertyDescription *fillColor = [ETPropertyDescription descriptionWithName: @"fillColor" type: (id)@"NSColor"];
	ETPropertyDescription *strokeColor = [ETPropertyDescription descriptionWithName: @"strokeColor" type: (id)@"NSColor"];
	ETPropertyDescription *alpha = [ETPropertyDescription descriptionWithName: @"alphaValue" type: (id)@"NSColor"];
	ETPropertyDescription *hidden = [ETPropertyDescription descriptionWithName: @"hidden" type: (id)@"BOOL"];

	NSArray *persistentProperties = A(path, bounds, pathResizeSel, fillColor, strokeColor, alpha, hidden);

	[[persistentProperties mappedCollection] setPersistent: YES];
	[entity setPropertyDescriptions: persistentProperties];

	return entity;
}

@end
