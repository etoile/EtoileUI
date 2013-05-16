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

	/* Persistent Properties */

	ETPropertyDescription *parentItem = [ETPropertyDescription descriptionWithName: @"parentItem" type: (id)@"ETLayoutItemGroup"];
	[parentItem setIsContainer: YES];
	[parentItem setOpposite: (id)@"ETLayoutItemGroup.items"];
	ETPropertyDescription *identifier = [ETPropertyDescription descriptionWithName: @"identifier" type: (id)@"NSString"];
	ETPropertyDescription *name = [ETPropertyDescription descriptionWithName: @"name" type: (id)@"NSString"];
	ETPropertyDescription *image = [ETPropertyDescription descriptionWithName: @"image" type: (id)@"NSImage"];
	ETPropertyDescription *icon = [ETPropertyDescription descriptionWithName: @"image" type: (id)@"NSImage"];
	ETPropertyDescription *repObject = [ETPropertyDescription descriptionWithName: @"representedObject" type: (id)@"NSObject"];
	ETPropertyDescription *value = [ETPropertyDescription descriptionWithName: @"value" type: (id)@"NSObject"];
	ETPropertyDescription *view = [ETPropertyDescription descriptionWithName: @"view" type: (id)@"NSView"];
	ETPropertyDescription *viewTargetId = [ETPropertyDescription descriptionWithName: @"viewTargetId" type: (id)@"NSString"];
	ETPropertyDescription *styleGroup = [ETPropertyDescription descriptionWithName: @"styleGroup" type: (id)@"ETStyleGroup"];
	ETPropertyDescription *coverStyle = [ETPropertyDescription descriptionWithName: @"coverStyle" type: (id)@"ETStyle"];
	ETPropertyDescription *actionHandler = [ETPropertyDescription descriptionWithName: @"actionHandler" type: (id)@"ETActionHandler"];
	ETPropertyDescription *action = [ETPropertyDescription descriptionWithName: @"action" type: (id)@"SEL"];
	/* We persist a target id rather than the raw target, because we have no 
	   way to uniquely identify objects which are not items such as views */
	ETPropertyDescription *targetId = [ETPropertyDescription descriptionWithName: @"targetId" type: (id)@"NSString"];
	ETPropertyDescription *contentBounds = [ETPropertyDescription descriptionWithName: @"contentBounds" type: (id)@"NSRect"];
	ETPropertyDescription *position = [ETPropertyDescription descriptionWithName: @"position" type: (id)@"NSPoint"];
	ETPropertyDescription *anchorPoint = [ETPropertyDescription descriptionWithName: @"anchorPoint" type: (id)@"NSPoint"];
	ETPropertyDescription *persistentFrame = [ETPropertyDescription descriptionWithName: @"persistentFrame" type: (id)@"NSRect"];
	// TODO: Enable when truly supported
	//ETPropertyDescription *transform = [ETPropertyDescription descriptionWithName: @"transform" type: (id)@"NSAffineTransform"];
	ETPropertyDescription *autoresizing = [ETPropertyDescription descriptionWithName: @"autoresizingMask" type: (id)@"NSUInteger"];
	ETPropertyDescription *contentAspect = [ETPropertyDescription descriptionWithName: @"contentAspect" type: (id)@"NSUInteger"];
	ETPropertyDescription *boundingBox = [ETPropertyDescription descriptionWithName: @"boundingBox" type: (id)@"NSRect"];
	// TODO: What should we do with _defaultValues?
	ETPropertyDescription *defaultFrame = [ETPropertyDescription descriptionWithName: @"defaultFrame" type: (id)@"NSRect"];
	// TODO: We should move flipped to ETUIItem. We need to override it though 
	// not to be read-only, because ETLayoutItem introduces -setFlipped:.
	ETPropertyDescription *flipped = [ETPropertyDescription descriptionWithName: @"flipped" type: (id)@"BOOL"];
	ETPropertyDescription *selected = [ETPropertyDescription descriptionWithName: @"selected" type: (id)@"BOOL"];
	ETPropertyDescription *selectable = [ETPropertyDescription descriptionWithName: @"selectable" type: (id)@"BOOL"];
	ETPropertyDescription *visible = [ETPropertyDescription descriptionWithName: @"visible" type: (id)@"BOOL"];
	// TODO: The subtype UTI is declared transient because we have to work out how to persist ETUTI.
	ETPropertyDescription *subtype = [ETPropertyDescription descriptionWithName: @"subtype" type: (id)@"ETUTI"];

	/* Transient Properties */

	// TODO: Declare -UTI in the transient properties (or rather at NSObject level)...
	// TODO: More transient properties could be declared. For example scrollableAreaItem etc. 

	ETPropertyDescription *baseItem = [ETPropertyDescription descriptionWithName: @"baseItem" type: (id)@"ETLayoutItemGroup"];
	ETPropertyDescription *rootItem = [ETPropertyDescription descriptionWithName: @"rootItem" type: (id)@"ETLayoutItemGroup"];
	ETPropertyDescription *indexPath = [ETPropertyDescription descriptionWithName: @"indexPath" type: (id)@"NSIndexPath"];
	ETPropertyDescription *isBaseItem = [ETPropertyDescription descriptionWithName: @"isBaseItem" type: (id)@"BOOL"];
	ETPropertyDescription *subject = [ETPropertyDescription descriptionWithName: @"subject" type: (id)@"NSObject"];
	ETPropertyDescription *style = [ETPropertyDescription descriptionWithName: @"style" type: (id)@"ETStyle"];
	ETPropertyDescription *frame = [ETPropertyDescription descriptionWithName: @"frame" type: (id)@"NSRect"];
	ETPropertyDescription *x = [ETPropertyDescription descriptionWithName: @"x" type: (id)@"float"];
	ETPropertyDescription *y = [ETPropertyDescription descriptionWithName: @"y" type: (id)@"float"];
	ETPropertyDescription *width = [ETPropertyDescription descriptionWithName: @"width" type: (id)@"float"];
	ETPropertyDescription *height = [ETPropertyDescription descriptionWithName: @"height" type: (id)@"float"];
	ETPropertyDescription *target = [ETPropertyDescription descriptionWithName: @"target" type: (id)@"NSObject"];
	ETPropertyDescription *acceptsActions = [ETPropertyDescription descriptionWithName: @"acceptsActions" type: (id)@"BOOL"];
	// TODO: We should persist the inspector but how... We should use a better type than NSObject.
	ETPropertyDescription *inspector = [ETPropertyDescription descriptionWithName: @"inspector" type: (id)@"NSObject"];

	/* Transient ivars: 	
	   _isSyncingSupervisorViewGeometry, _scrollViewShown, _wasKVOStopped
	   
	   Hmm, _scrollViewShow ought to be persisted. */

	NSArray *persistentProperties = A(parentItem, identifier, name, image, icon, 
		repObject, value, view, viewTargetId, styleGroup, coverStyle, 
		actionHandler, action, targetId, contentBounds, position, anchorPoint, 
		persistentFrame, autoresizing, contentAspect, boundingBox, defaultFrame,
		flipped, selected, selectable, visible);
	NSArray *transientProperties = A(baseItem, rootItem, indexPath, 
		isBaseItem, subject, style, frame, x, y, width, height, target, 
		acceptsActions, inspector, subtype);

	// TODO: Use frame, position, anchorPoint
	[entity setUIBuilderPropertyNames: (id)[[A(identifier, name, image, icon,
		target, action, x, y, width, height, autoresizing, contentAspect,
		flipped, selected, selectable, visible) mappedCollection] name]];

	[[persistentProperties mappedCollection] setPersistent: YES];
	[entity setPropertyDescriptions: [persistentProperties arrayByAddingObjectsFromArray: transientProperties]];

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
	
	/* Persistent Properties */

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

	ETPropertyDescription *doubleAction = 
		[ETPropertyDescription descriptionWithName: @"doubleAction" type: (id)@"SEL"];
	ETPropertyDescription *shouldMutateRepObject = 
		[ETPropertyDescription descriptionWithName: @"shouldMutateRepresentedObject" type: (id)@"BOOL"];
	ETPropertyDescription *itemScaleFactor = 
		[ETPropertyDescription descriptionWithName: @"itemScaleFactor" type: (id)@"float"];
	// NOTE: _wasViewHidden must be persisted. If YES at deserialization, we 
	// unhide the item view.
	ETPropertyDescription *wasViewHidden = [ETPropertyDescription descriptionWithName: @"wasViewHidden" type: (id)@"BOOL"];

	/* Transient Properties */

	ETPropertyDescription *doubleClickedItem = [ETPropertyDescription descriptionWithName: @"doubleClickedItem" type: (id)@"ETLayoutItem"];

	// TODO: Declare the numerous derived (implicitly transient) properties we have 
	// descendantItemsSharingSameBaseItem, allDescendantItems, firstItem, 
	// lastItem, numberOfItems, canReload, canUpdateLayout, layoutView, 
	// visibleItems, visibleContentSize, cachedDisplayImage, selectionIndex, 
	// selectionIndexes, selectionIndexPaths, selectedItems, selectedInLayout, 
	// acceptsActionsForItemsOutsideOfFrame

	/* Transient ivars: 	
	   _sortedItems, _arrangedItems, _cachedDisplayImage, _reloading, 
	   _hasNewContent, _hasNewLayout, _hasNewArrangement, _sorted, _filtered,
	   _changingSelection */
	   
	/* Ignored ivars and properties:
	   _usesLayoutBasedFrame (unsupported), _isLayerItem (unsupported)
	   isStack (unsupported), isStacked (unsupported) */

	NSArray *persistentProperties = A(items, layout, autolayout, source, 
		delegate, controller, doubleAction, shouldMutateRepObject, 
		itemScaleFactor, wasViewHidden);
	NSArray *transientProperties = A(doubleClickedItem);

	[entity setUIBuilderPropertyNames: (id)[[A(layout, delegate, doubleAction,
		shouldMutateRepObject, itemScaleFactor) mappedCollection] name]];
	
	[[persistentProperties mappedCollection] setPersistent: YES];
	[entity setPropertyDescriptions: [persistentProperties arrayByAddingObjectsFromArray: transientProperties]];

	return entity;
}

/* Returns a ETLayoutItemGroup entity under the name ETCompoundDocument that 
overrides the position property description to be transient. */
+ (ETEntityDescription *) newEntityDescriptionForCompoundDocument
{
	ETEntityDescription *entity = [self newEntityDescription];
	ETPropertyDescription *position = [ETPropertyDescription descriptionWithName: @"position" type: (id)@"NSPoint"];

	[entity setName: @"ETCompoundDocument"];
	[entity addPropertyDescription: position];

	return entity;
}

@end
