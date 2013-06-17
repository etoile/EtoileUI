/*
	Copyright (C) 2011 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  June 2011
	License: Modified BSD (see COPYING)
 */

#import <EtoileFoundation/EtoileFoundation.h>
#import "ETLayout.h"
#import "ETComputedLayout.h"
#import "ETPositionalLayout.h"
#import "ETWidgetLayout.h"
#import "ETTableLayout.h"
#import "ETOutlineLayout.h"

// NOTE: ETFixedLayout, ETFreeLayout uses ETLayout model description
@interface ETLayout (ModelDescription)
@end

@interface ETPositionalLayout (ModelDescription)
@end

@interface ETComputedLayout (ModelDescription)
@end

@implementation ETLayout (ModelDescription)

+ (ETEntityDescription *) newEntityDescription
{
	ETEntityDescription *entity = [self newBasicEntityDescription];

	// For subclasses that don't override -newEntityDescription, we must not add 
	// the property descriptions that we will inherit through the parent
	if ([[entity name] isEqual: [ETLayout className]] == NO) 
		return entity;

	// TODO: Type should be ETLayoutItem
	ETPropertyDescription *context = 
		[ETPropertyDescription descriptionWithName: @"layoutContext" type: (id)@"ETLayoutItemGroup"];
	[context setOpposite: (id)@"ETLayoutItemGroup.layout"];
	ETPropertyDescription *delegate = 
		[ETPropertyDescription descriptionWithName: @"delegate" type: (id)@"NSObject"];
	ETPropertyDescription *layoutView = 
		[ETPropertyDescription descriptionWithName: @"layoutView" type: (id)@"NSView"];
	ETPropertyDescription *attachedTool =
		[ETPropertyDescription descriptionWithName: @"attachedTool" type: (id)@"ETTool"];
	ETPropertyDescription *layerItem = 
		[ETPropertyDescription descriptionWithName: @"layerItem" type: (id)@"ETLayoutItemGroup"];
	ETPropertyDescription *dropIndicator = 
		[ETPropertyDescription descriptionWithName: @"dropIndicator" type: (id)@"ETDropIndicator"];

	// NOTE: layoutSize is not transient, it is usually computed but can be customized
	ETPropertyDescription *layoutSize = 
		[ETPropertyDescription descriptionWithName: @"layoutSize" type: (id)@"NSSize"];
	ETPropertyDescription *isContentSizeLayout = 
		[ETPropertyDescription descriptionWithName: @"isContentSizeLayout" type: (id)@"BOOL"];
	ETPropertyDescription *usesCustomLayoutSize =
		[ETPropertyDescription descriptionWithName: @"usesCustomLayoutSize" type: (id)@"BOOL"];	


	// TODO: Declare the numerous derived (implicitly transient) properties we have 

	/* Transient properties
	   _tool, _dropIndicator, _isRendering */
	NSArray *transientProperties = A(dropIndicator, layerItem);

	// TODO: Support tool persistence... Rarely needed though.
	// TODO: We need a direct ivar access to persist the layer item
	// TODO: Evaluate whether we should support drop indicator persistence
	NSArray *persistentProperties = A(attachedTool, context, delegate, layoutView,
		layoutSize, isContentSizeLayout, usesCustomLayoutSize);

	[entity setUIBuilderPropertyNames: (id)[[A(delegate, dropIndicator, isContentSizeLayout) mappedCollection] name]];

	[[persistentProperties mappedCollection] setPersistent: YES];
	[entity setPropertyDescriptions: 
		[persistentProperties arrayByAddingObjectsFromArray: transientProperties]];

	return entity;
}

@end


@implementation ETPositionalLayout (ModelDescription)

+ (ETEntityDescription *) newEntityDescription
{
	ETEntityDescription *entity = [self newBasicEntityDescription];
	
	// For subclasses that don't override -newEntityDescription, we must not add
	// the property descriptions that we will inherit through the parent
	if ([[entity name] isEqual: [ETPositionalLayout className]] == NO)
		return entity;

	ETPropertyDescription *constrainedItemSize =
		[ETPropertyDescription descriptionWithName: @"constrainedItemSize" type: (id)@"NSSize"];
	ETPropertyDescription *itemSizeConstraintStyle = 
		[ETPropertyDescription descriptionWithName: @"itemSizeConstraintStyle" type: (id)@"NSUInteger"];
	[itemSizeConstraintStyle setRole: AUTORELEASE([ETMultiOptionsRole new])];
	[[itemSizeConstraintStyle role] setAllowedOptions:
	 	[D(@(ETSizeConstraintStyleNone), _(@"None"),
		   @(ETSizeConstraintStyleVertical), _(@"Vertical"),
		   @(ETSizeConstraintStyleHorizontal), _(@"Horizontal"),
		   @(ETSizeConstraintStyleVerticalHorizontal), _(@"Vertical and Horizontal")) arrayRepresentation]];

	NSArray *transientProperties = [NSArray array];
	NSArray *persistentProperties = A(constrainedItemSize, itemSizeConstraintStyle);

	[entity setUIBuilderPropertyNames: (id)[[A(constrainedItemSize,
		itemSizeConstraintStyle) mappedCollection] name]];

	[[persistentProperties mappedCollection] setPersistent: YES];
	[entity setPropertyDescriptions: 
		[persistentProperties arrayByAddingObjectsFromArray: transientProperties]];
	
	return entity;
}

@end


@implementation ETComputedLayout (ModelDescription)

+ (ETEntityDescription *) newEntityDescription
{
	ETEntityDescription *entity = [self newBasicEntityDescription];
	
	// For subclasses that don't override -newEntityDescription, we must not add
	// the property descriptions that we will inherit through the parent
	if ([[entity name] isEqual: [ETComputedLayout className]] == NO)
		return entity;

	// TODO: Migrate to CGFloat
	ETPropertyDescription *borderMargin =
		[ETPropertyDescription descriptionWithName: @"borderMargin" type: (id)@"float"];
	ETPropertyDescription *itemMargin =
		[ETPropertyDescription descriptionWithName: @"itemMargin" type: (id)@"float"];
	
	NSArray *transientProperties = [NSArray array];
	NSArray *persistentProperties = A(borderMargin, itemMargin);
	
	[entity setUIBuilderPropertyNames: (id)[[A(borderMargin, itemMargin) mappedCollection] name]];
	
	[[persistentProperties mappedCollection] setPersistent: YES];
	[entity setPropertyDescriptions:
	 	[persistentProperties arrayByAddingObjectsFromArray: transientProperties]];
	
	return entity;
}

@end


@implementation ETWidgetLayout (ModelDescription)

+ (ETEntityDescription *) newEntityDescription
{
	ETEntityDescription *entity = [self newBasicEntityDescription];
	
	// For subclasses that don't override -newEntityDescription, we must not add
	// the property descriptions that we will inherit through the parent
	if ([[entity name] isEqual: [ETWidgetLayout className]] == NO)
		return entity;
	
	ETPropertyDescription *nibName =
		[ETPropertyDescription descriptionWithName: @"nibName" type: (id)@"NSString"];
	[nibName setReadOnly: YES];
	ETPropertyDescription *layoutView =
		[ETPropertyDescription descriptionWithName: @"layoutView" type: (id)@"NSView"];
	ETPropertyDescription *selectionIndexPaths =
		[ETPropertyDescription descriptionWithName: @"selectionIndexPaths" type: (id)@"NSIndexPath"];
	[selectionIndexPaths setMultivalued: YES];
	[selectionIndexPaths setOrdered: YES];
	ETPropertyDescription *doubleClickedItem =
		[ETPropertyDescription descriptionWithName: @"doubleClickedItem" type: (id)@"ETLayoutItem"];
	[doubleClickedItem setReadOnly: YES];
	// TODO: Perhaps add a Class entity description to the metamodel (not sure)
	ETPropertyDescription *widgetViewClass =
		[ETPropertyDescription descriptionWithName: @"widgetViewClass" type: (id)@"NSObject"];
	[widgetViewClass setReadOnly: YES];

	NSArray *transientProperties = A(nibName, selectionIndexPaths,
		doubleClickedItem, widgetViewClass);
	NSArray *persistentProperties = A(layoutView);
	
	[[persistentProperties mappedCollection] setPersistent: YES];
	[entity setPropertyDescriptions:
		[persistentProperties arrayByAddingObjectsFromArray: transientProperties]];
	
	return entity;
}

@end


@implementation ETTableLayout (ModelDescription)

+ (ETEntityDescription *) newEntityDescription
{
	ETEntityDescription *entity = [self newBasicEntityDescription];
	
	// For subclasses that don't override -newEntityDescription, we must not add
	// the property descriptions that we will inherit through the parent
	if ([[entity name] isEqual: [ETTableLayout className]] == NO)
		return entity;
	
	ETPropertyDescription *displayedProperties =
		[ETPropertyDescription descriptionWithName: @"displayedProperties" type: (id)@"NSString"];
	[displayedProperties setMultivalued: YES];
	[displayedProperties setOrdered: YES];
	ETPropertyDescription *editableProperties =
		[ETPropertyDescription descriptionWithName: @"editableProperties" type: (id)@"BOOL"];
	[editableProperties setMultivalued: YES];
	ETPropertyDescription *styles =
		[ETPropertyDescription descriptionWithName: @"styles" type: (id)@"ETStyle"];
	[styles setMultivalued: YES];
	// FIXME: Use ETColumnFragment as type
	ETPropertyDescription *columns =
		[ETPropertyDescription descriptionWithName: @"columns" type: (id)@"NSObject"];
	[columns setMultivalued: YES];
	ETPropertyDescription *formatters =
		[ETPropertyDescription descriptionWithName: @"formatters" type: (id)@"NSFormatter"];
	[formatters setMultivalued: YES];
	/* The collection is immutable because you cannot declare new properties by 
	   editing it. You must edit 'displayedProperties' to do so instead. 
	   However the formatter objects themselves are mutable, but editing doesn't 
	   involve mutating the collection. */
	[formatters setReadOnly: YES];
	// TODO: Set a value transformer for 'value' so we can resolve the
	// formatter against the aspect repositories and NSFormatter subclasses.
	ETPropertyDescription *sortable =
		[ETPropertyDescription descriptionWithName: @"sortable" type: (id)@"BOOL"];
	ETPropertyDescription *contentFont =
		[ETPropertyDescription descriptionWithName: @"contentFont" type: (id)@"NSFont"];

	// FIXME: NSArray *transientProperties = A(displayedProperties, editableProperties,
	//	formatters, styles, columns, sortable, contentFont);
	NSArray *transientProperties = A(displayedProperties,
		formatters, sortable, contentFont);
	// FIXME: Declare PropertyColumns as a persistent property
	NSArray *persistentProperties = [NSArray array];
	
	[entity setUIBuilderPropertyNames: (id)[[transientProperties mappedCollection] name]];

	[[persistentProperties mappedCollection] setPersistent: YES];
	[entity setPropertyDescriptions:
		[persistentProperties arrayByAddingObjectsFromArray: transientProperties]];
	
	return entity;
}

- (NSDictionary *) formatters
{
	NSMutableDictionary *formatters = [NSMutableDictionary dictionary];

	for (NSString *property in _propertyColumns)
	{
		NSTableColumn *column = [_propertyColumns objectForKey: property];
		ETMutableObjectViewpoint *formatterViewpoint =
			[ETMutableObjectViewpoint viewpointWithName: @"formatter"
			                          representedObject: [column dataCell]];
	
		[formatters setObject: formatterViewpoint forKey: property];
	}
	return AUTORELEASE([formatters copy]);
}

@end
