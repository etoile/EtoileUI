/*
	Copyright (C) 2011 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  June 2011
	License: Modified BSD (see COPYING)
 */

#import <EtoileFoundation/EtoileFoundation.h>
#import "ETLayout.h"

@interface ETLayout (ModelDescription)
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
	ETPropertyDescription *layoutSizeCustomized = 
		[ETPropertyDescription descriptionWithName: @"layoutSizeCustomized" type: (id)@"BOOL"];	
	ETPropertyDescription *itemSize = 
		[ETPropertyDescription descriptionWithName: @"itemSize" type: (id)@"NSSize"];	
	ETPropertyDescription *itemSizeConstraintStyle = 
		[ETPropertyDescription descriptionWithName: @"itemSize" type: (id)@"NSUInteger"];	

	// TODO: Declare the numerous derived (implicitly transient) properties we have 

	/* Transient properties
	   _tool, _dropIndicator, _isLayouting */
	NSArray *transientProperties = A(dropIndicator, layerItem);

	// TODO: Support tool persistence... Rarely needed though.
	// TODO: We need a direct ivar access to persist the layer item
	// TODO: Evaluate whether we should support drop indicator persistence
	NSArray *persistentProperties = A(attachedTool, context, delegate, layoutView,
		layoutSize, isContentSizeLayout, layoutSizeCustomized, itemSize, itemSizeConstraintStyle);

	[[persistentProperties mappedCollection] setPersistent: YES];
	[entity setPropertyDescriptions: 
		[persistentProperties arrayByAddingObjectsFromArray: transientProperties]];

	return entity;
}

@end

// NOTE: ETFixedLayout, ETFreeLayout uses ETLayout model description
