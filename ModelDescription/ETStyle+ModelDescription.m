/*
	Copyright (C) 2011 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  June 2011
	License: Modified BSD (see COPYING)
 */

#import <EtoileFoundation/EtoileFoundation.h>
#import "ETBasicItemStyle.h"
#import "ETStyle.h"
#import "ETStyleGroup.h"
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

	ETPropertyDescription *isShared = [ETPropertyDescription descriptionWithName: @"isShared" type: (id)@"BOOL"];

	[entity setUIBuilderPropertyNames: A([isShared name])];

	[entity addPropertyDescription: isShared];

	return entity;
}

@end

@interface ETStyleGroup (ModelDescrition)
@end

@implementation ETStyleGroup (ModelDescription)

+ (ETEntityDescription *) newEntityDescription
{
	ETEntityDescription *entity = [self newBasicEntityDescription];

	// For subclasses that don't override -newEntityDescription, we must not add 
	// the property descriptions that we will inherit through the parent.
	if ([[entity name] isEqual: [ETStyleGroup className]] == NO) 
		return entity;

	ETPropertyDescription *styles = [ETPropertyDescription descriptionWithName: @"styles" type: (id)@"ETStyle"];
	[styles setMultivalued: YES];
	[styles setOrdered: YES];
	ETPropertyDescription *firstStyle = [ETPropertyDescription descriptionWithName: @"firstStyle" type: (id)@"ETStyle"];
	ETPropertyDescription *lastStyle = [ETPropertyDescription descriptionWithName: @"lastStyle" type: (id)@"ETStyle"];

	[entity setUIBuilderPropertyNames:  A([styles name])];

	[styles setPersistent: YES];
	[entity setPropertyDescriptions: A(styles, firstStyle, lastStyle)];

	return entity;
}

@end

@interface ETBasicItemStyle (ModelDescrition)
@end

@implementation ETBasicItemStyle (ModelDescription)

+ (ETEntityDescription *) newEntityDescription
{
	ETEntityDescription *entity = [self newBasicEntityDescription];
	
	// For subclasses that don't override -newEntityDescription, we must not add
	// the property descriptions that we will inherit through the parent.
	if ([[entity name] isEqual: [ETBasicItemStyle className]] == NO)
		return entity;

	// TODO: Add labelAttributes and selectedLabelAttributes
	ETPropertyDescription *labelPosition = [ETPropertyDescription descriptionWithName: @"labelPosition" type: (id)@"NSUInteger"];
	[labelPosition setRole: AUTORELEASE([ETMultiOptionsRole new])];
	[[labelPosition role] setAllowedOptions:
	 	[D(@(ETLabelPositionNone), _(@"None"),
		   @(ETLabelPositionContentAspect), _(@"Based on Item Content Aspect"),
		   @(ETLabelPositionCentered), _(@"Centered"),
		   @(ETLabelPositionInsideLeft), _(@"Inside Left"),
		   @(ETLabelPositionOutsideLeft), _(@"Outside Left"),
		   @(ETLabelPositionInsideTop), _(@"Inside Top"),
		   @(ETLabelPositionOutsideTop), _(@"Outside Top"),
		   @(ETLabelPositionInsideRight), _(@"Inside Right"),
		   @(ETLabelPositionOutsideRight), _(@"Outside Right"),
		   @(ETLabelPositionInsideBottom), _(@"Inside Bottom"),
		   @(ETLabelPositionOutsideBottom), _(@"Outside Bottom")) arrayRepresentation]];
	ETPropertyDescription *labelMargin = [ETPropertyDescription descriptionWithName: @"labelMargin" type: (id)@"CGFloat"];
	ETPropertyDescription *maxLabelSize = [ETPropertyDescription descriptionWithName: @"maxLabelSize" type: (id)@"NSSize"];
	ETPropertyDescription *maxImageSize = [ETPropertyDescription descriptionWithName: @"maxImageSize" type: (id)@"NSSize"];
	ETPropertyDescription *edgeInset = [ETPropertyDescription descriptionWithName: @"edgeInset" type: (id)@"CGFloat"];

	NSArray *transientProperties = [NSArray array];
	NSArray *persistentProperties = A(labelPosition, labelMargin, maxLabelSize,
		maxImageSize, edgeInset);

	[entity setUIBuilderPropertyNames: (id)[[A(edgeInset, labelPosition,
		labelMargin, maxLabelSize, maxImageSize) mappedCollection] name]];

	// TODO: Turn on once the persistency test suite is updated
	//[[persistentProperties mappedCollection] setPersistent: YES];
	[entity setPropertyDescriptions:
		[persistentProperties arrayByAddingObjectsFromArray: transientProperties]];

	
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
	ETPropertyDescription *alpha = [ETPropertyDescription descriptionWithName: @"alphaValue" type: (id)@"CGFloat"];
	ETPropertyDescription *hidden = [ETPropertyDescription descriptionWithName: @"hidden" type: (id)@"BOOL"];

	NSArray *transientProperties = A(bounds);
	NSArray *persistentProperties = A(path, pathResizeSel, fillColor, strokeColor, alpha, hidden);

	[entity setUIBuilderPropertyNames: (id)[[A(path, fillColor, strokeColor,
		alpha) mappedCollection] name]];

	[[persistentProperties mappedCollection] setPersistent: YES];
	[entity setPropertyDescriptions: [persistentProperties arrayByAddingObjectsFromArray: transientProperties]];

	return entity;
}

@end
