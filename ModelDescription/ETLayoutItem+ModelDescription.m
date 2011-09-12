/*
	Copyright (C) 2011 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  June 2011
	License: Modified BSD (see COPYING)
 */

#import <EtoileFoundation/EtoileFoundation.h>
#import "ETLayoutItem.h"
#import "ETLayoutItemGroup.h"

@interface ETLayoutItem (ModelDescription)
@end

@implementation ETLayoutItem (ModelDescription)

+ (ETEntityDescription *) newEntityDescription
{
	ETEntityDescription *entity = [self newBasicEntityDescription];

	// For subclasses that don't override -newEntityDescription, we must not add 
	// the property descriptions that we will inherit through the parent
	if ([[entity name] isEqual: [ETLayoutItem className]] == NO) 
		return entity;

	// TODO: What should we do with _defaultValues?

	ETPropertyDescription *parentItem = [ETPropertyDescription descriptionWithName: @"parentItem" type: (id)@"ETLayoutItemGroup"];
	[parentItem setIsContainer: YES];
	[parentItem setOpposite: (id)@"ETLayoutItemGroup.items"];
	ETPropertyDescription *repObject = [ETPropertyDescription descriptionWithName: @"representedObject" type: (id)@"NSObject"];
	ETPropertyDescription *view = [ETPropertyDescription descriptionWithName: @"view" type: (id)@"NSView"];
	ETPropertyDescription *viewTargetId = [ETPropertyDescription descriptionWithName: @"viewTargetId" type: (id)@"NSString"];
	ETPropertyDescription *styleGroup = [ETPropertyDescription descriptionWithName: @"styleGroup" type: (id)@"ETStyleGroup"];
	ETPropertyDescription *coverStyle = [ETPropertyDescription descriptionWithName: @"coverStyle" type: (id)@"ETStyle"];
	ETPropertyDescription *actionHandler = [ETPropertyDescription descriptionWithName: @"actionHandler" type: (id)@"ETActionHandler"];
	ETPropertyDescription *contentBounds = [ETPropertyDescription descriptionWithName: @"contentBounds" type: (id)@"NSRect"];
	ETPropertyDescription *position = [ETPropertyDescription descriptionWithName: @"position" type: (id)@"NSPoint"];
	ETPropertyDescription *anchorPoint = [ETPropertyDescription descriptionWithName: @"anchorPoint" type: (id)@"NSPoint"];
	// TODO: Enable when truly supported
	//ETPropertyDescription *transform = [ETPropertyDescription descriptionWithName: @"transform" type: (id)@"NSAffineTransform"];
	ETPropertyDescription *autoresizing = [ETPropertyDescription descriptionWithName: @"autoresizingMask" type: (id)@"NSUInteger"];
	ETPropertyDescription *contentAspect = [ETPropertyDescription descriptionWithName: @"contentAspect" type: (id)@"NSUInteger"];
	ETPropertyDescription *boundingBox = [ETPropertyDescription descriptionWithName: @"boundingBox" type: (id)@"NSRect"];
	// TODO: We should move flipped to ETUIItem. We need to override it though 
	// not to be read-only, because ETLayoutItem introduces -setFlipped:.
	ETPropertyDescription *flipped = [ETPropertyDescription descriptionWithName: @"flipped" type: (id)@"BOOL"];
	ETPropertyDescription *selected = [ETPropertyDescription descriptionWithName: @"selected" type: (id)@"BOOL"];
	ETPropertyDescription *visible = [ETPropertyDescription descriptionWithName: @"visible" type: (id)@"BOOL"];

	// TODO: Declare the numerous derived (implicitly transient) properties we have

	/* Transient properties: 	
	   _isSyncingSupervisorViewGeometry, _scrollViewShown, _wasKVOStopped
	   
	   Hmm, _scrollViewShow ought to be persisted. */

	NSArray *persistentProperties = A(parentItem, repObject, view, viewTargetId, styleGroup, 
		coverStyle, actionHandler, contentBounds, position, anchorPoint, autoresizing, 
		contentAspect, boundingBox, flipped, selected, visible);

	[[persistentProperties mappedCollection] setPersistent: YES];
	[entity setPropertyDescriptions: persistentProperties];

	return entity;
}

@end

@interface ETLayoutItemGroup (ModelDescription)
@end

@implementation ETLayoutItemGroup (ModelDescription)

+ (ETEntityDescription *) newEntityDescription
{
	ETEntityDescription *entity = [self newBasicEntityDescription];

	// For subclasses that don't override -newEntityDescription, we must not add 
	// the property descriptions that we will inherit through the parent
	if ([[entity name] isEqual: [ETLayoutItemGroup className]] == NO) 
		return entity;

	ETPropertyDescription *items = [ETPropertyDescription descriptionWithName: @"items" type: (id)@"ETLayoutItem"];
	[items setMultivalued: YES];
	[items setOrdered: YES];
	[items setOpposite: (id)@"ETLayoutItem.parentItem"];

	// TODO: Move to ETLayoutItem and update ETLayout description as necessary
	ETPropertyDescription *layout = [ETPropertyDescription descriptionWithName: @"layout" type: (id)@"ETLayout"];
	[layout setOpposite: (id)@"ETLayout.layoutContext"];
	ETPropertyDescription *autolayout = [ETPropertyDescription descriptionWithName: @"autolayout" type: (id)@"BOOL"];

	ETPropertyDescription *source = [ETPropertyDescription descriptionWithName: @"source" type: (id)@"NSObject"];
	ETPropertyDescription *delegate = [ETPropertyDescription descriptionWithName: @"delegate" type: (id)@"NSObject"];

	ETPropertyDescription *controller = [ETPropertyDescription descriptionWithName: @"controller" type: (id)@"ETController"];
	[controller setOpposite: (id)@"ETController.content"];

	ETPropertyDescription *doubleClickAction = 
		[ETPropertyDescription descriptionWithName: @"doubleClickAction" type: (id)@"SEL"];
	ETPropertyDescription *shouldMutateRepObject = 
		[ETPropertyDescription descriptionWithName: @"shouldMutateRepresentedObject" type: (id)@"SEL"];
	ETPropertyDescription *itemScaleFactor = 
		[ETPropertyDescription descriptionWithName: @"itemScaleFactor" type: (id)@"float"];
	// NOTE: _wasViewHidden must be persisted. If YES at deserialization, we 
	// unhide the item view.
	ETPropertyDescription *wasViewHidden = [ETPropertyDescription descriptionWithName: @"wasViewHidden" type: (id)@"BOOL"];

	// TODO: Declare the numerous derived (implicitly transient) properties we have 

	/* Transient properties: 	
	   _sortedItems, _arrangedItems, _cachedDisplayImage, _reloading, 
	   _hasNewContent, _hasNewLayout, _hasNewArrangement, _sorted, _filtered,
	   _changingSelection
	   descendantItemsSharingSameBaseItem, allDescendantItems, firstItem, 
	   lastItem, numberOfItems, canReload, canUpdateLayout, layoutView, 
	   visibleItems, visibleContentSize, cachedDisplayImage, selectionIndex, 
	   selectionIndexes, selectionIndexPaths, selectedItems, selectedInLayout, 
	   doubleClickedItem, acceptsActionsForItemsOutsideOfFrame */
	   
	/* Ignored properties:
	   _usesLayoutBasedFrame (unsupported), _isLayerItem (unsupported)
	   isStack (unsupported), isStacked (unsupported) */

	NSArray *persistentProperties = A(items, layout, autolayout, source, 
		delegate, controller, doubleClickAction, shouldMutateRepObject, 
		itemScaleFactor, wasViewHidden);

	[[persistentProperties mappedCollection] setPersistent: YES];
	[entity setPropertyDescriptions: persistentProperties];

	return entity;
}

@end
