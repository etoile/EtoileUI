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
#import "ETTokenLayout.h"

@interface ETStyle (ModelDescrition)
@end

@interface ETStyleGroup (ModelDescrition)
@end

@interface ETBasicItemStyle (ModelDescrition)
@end

@interface ETShape (ModelDescrition)
@end

@interface ETTokenStyle (ModelDescrition)
@end

@implementation ETStyle (ModelDescription)

+ (ETEntityDescription *) newEntityDescription
{
	ETEntityDescription *entity = [self newBasicEntityDescription];

	// For subclasses that don't override -newEntityDescription, we must not add 
	// the property descriptions that we will inherit through the parent.
	if ([[entity name] isEqual: [ETStyle className]] == NO) 
		return entity;

	/* We overwrite COObject.isShared to be read/write */
	ETPropertyDescription *isShared = [ETPropertyDescription descriptionWithName: @"isShared" type: (id)@"BOOL"];
	[isShared setPersistent: YES];

	[entity setUIBuilderPropertyNames: @[[isShared name]]];

	[entity addPropertyDescription: isShared];

	return entity;
}

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

	[entity setUIBuilderPropertyNames:  @[[styles name]]];

	[styles setPersistent: YES];
	[entity setPropertyDescriptions: @[styles, firstStyle, lastStyle]];

	return entity;
}

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
	[labelPosition setRole: [ETMultiOptionsRole new]];
	[[labelPosition role] setAllowedOptions:
	 	[@{ _(@"None"): @(ETLabelPositionNone),
		    _(@"Based on Item Content Aspect"): @(ETLabelPositionContentAspect),
		    _(@"Centered"): @(ETLabelPositionCentered),
		    _(@"Inside Left"): @(ETLabelPositionInsideLeft),
		    _(@"Outside Left"): @(ETLabelPositionOutsideLeft),
		    _(@"Inside Top"): @(ETLabelPositionInsideTop),
		    _(@"Outside Top"): @(ETLabelPositionOutsideTop),
		    _(@"Inside Right"): @(ETLabelPositionInsideRight),
		    _(@"Outside Right"): @(ETLabelPositionOutsideRight),
		    _(@"Inside Bottom"): @(ETLabelPositionInsideBottom),
		    _(@"Outside Bottom"): @(ETLabelPositionOutsideBottom) } arrayRepresentation]];
	ETPropertyDescription *labelMargin = [ETPropertyDescription descriptionWithName: @"labelMargin" type: (id)@"CGFloat"];
	ETPropertyDescription *labelAttributes = [ETPropertyDescription descriptionWithName: @"labelAttributes" type: (id)@"NSObject"];
	[labelAttributes setKeyed: YES];
	[labelAttributes setMultivalued: YES];
	ETPropertyDescription *selectedLabelAttributes = [ETPropertyDescription descriptionWithName: @"selectedLabelAttributes" type: (id)@"NSObject"];
	[selectedLabelAttributes setKeyed: YES];
	[selectedLabelAttributes setMultivalued: YES];
	ETPropertyDescription *maxLabelSize = [ETPropertyDescription descriptionWithName: @"maxLabelSize" type: (id)@"NSSize"];
	ETPropertyDescription *maxImageSize = [ETPropertyDescription descriptionWithName: @"maxImageSize" type: (id)@"NSSize"];
	ETPropertyDescription *edgeInset = [ETPropertyDescription descriptionWithName: @"edgeInset" type: (id)@"CGFloat"];

	// FIXME: Make labelAttributes and selectedLabelAttributes persistent
	NSArray *transientProperties = @[labelAttributes, selectedLabelAttributes];
	NSArray *persistentProperties = @[labelPosition, labelMargin, maxLabelSize,
		maxImageSize, edgeInset];

	[entity setUIBuilderPropertyNames: (id)[[@[edgeInset, labelPosition,
		labelMargin, maxLabelSize, maxImageSize] mappedCollection] name]];

	[[persistentProperties mappedCollection] setPersistent: YES];
	[entity setPropertyDescriptions:
		[persistentProperties arrayByAddingObjectsFromArray: transientProperties]];

	
	return entity;
}

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
    [path setValueTransformerName: @"COObjectToArchivedData"];
    [path setPersistentTypeName: @"NSData"];
	ETPropertyDescription *bounds = [ETPropertyDescription descriptionWithName: @"bounds" type: (id)@"NSRect"];
	ETPropertyDescription *pathResizeSel = [ETPropertyDescription descriptionWithName: @"pathResizeSelector" type: (id)@"SEL"];
	ETPropertyDescription *pathResizeSelName = [ETPropertyDescription descriptionWithName: @"pathResizeSelectorName" typeName: @"NSString"];
	ETPropertyDescription *fillColor = [ETPropertyDescription descriptionWithName: @"fillColor" type: (id)@"NSColor"];
    [fillColor setValueTransformerName: @"COColorToHTMLString"];
    [fillColor setPersistentTypeName: @"NSString"];
	ETPropertyDescription *strokeColor = [ETPropertyDescription descriptionWithName: @"strokeColor" type: (id)@"NSColor"];
    [strokeColor setValueTransformerName: @"COColorToHTMLString"];
    [strokeColor setPersistentTypeName: @"NSString"];
	ETPropertyDescription *alpha = [ETPropertyDescription descriptionWithName: @"alphaValue" type: (id)@"CGFloat"];
	ETPropertyDescription *hidden = [ETPropertyDescription descriptionWithName: @"hidden" type: (id)@"BOOL"];

	NSArray *transientProperties = @[bounds, pathResizeSel];
	NSArray *persistentProperties = @[path, pathResizeSelName, fillColor, strokeColor, alpha, hidden];

	[entity setUIBuilderPropertyNames: (id)[[@[path, fillColor, strokeColor,
		alpha] mappedCollection] name]];

	[[persistentProperties mappedCollection] setPersistent: YES];
	[entity setPropertyDescriptions: [persistentProperties arrayByAddingObjectsFromArray: transientProperties]];

	return entity;
}

@end


@implementation ETTokenStyle (ModelDescription)

+ (ETEntityDescription *) newEntityDescription
{
	ETEntityDescription *entity = [self newBasicEntityDescription];
	
	// For subclasses that don't override -newEntityDescription, we must not add
	// the property descriptions that we will inherit through the parent
	if ([[entity name] isEqual: [ETTokenStyle className]] == NO)
		return entity;

	ETPropertyDescription *tintColor =
		[ETPropertyDescription descriptionWithName: @"tintColor" type: (id)@"NSColor"];
	[tintColor setValueTransformerName: @"COColorToHTMLString"];
	[tintColor setPersistentTypeName: @"NSString"];

	[entity setUIBuilderPropertyNames: @[[tintColor name]]];
	
	[tintColor setPersistent: YES];
	[entity setPropertyDescriptions: @[tintColor]];
	
	return entity;
}

@end
