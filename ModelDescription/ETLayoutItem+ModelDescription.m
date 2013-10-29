/*
	Copyright (C) 2011 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  June 2011
	License: Modified BSD (see COPYING)
 */

#import <EtoileFoundation/EtoileFoundation.h>
#import <CoreObject/CODictionary.h>
#import "ETLayoutItem.h"
#import "ETLayoutItemGroup.h"
#import "ETItemValueTransformer.h"

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
	ETPropertyDescription *icon = [ETPropertyDescription descriptionWithName: @"icon" type: (id)@"NSImage"];
	ETPropertyDescription *repObject = [ETPropertyDescription descriptionWithName: @"representedObject" type: (id)@"NSObject"];
	ETPropertyDescription *valueTransformers = [ETPropertyDescription descriptionWithName: @"valueTransformers" type: (id)@"ETItemValueTransformer"];
	[valueTransformers setMultivalued: YES];
	[valueTransformers setOrdered: NO];
	[valueTransformers setKeyed: YES];
	[valueTransformers setShowsItemDetails: YES];
	[valueTransformers setDetailedPropertyNames: A(@"name", @"transformCode", @"reverseTransformCode")];
	ETPropertyDescription *valueKey = [ETPropertyDescription descriptionWithName: @"valueKey" type: (id)@"NSString"];
	ETPropertyDescription *value = [ETPropertyDescription descriptionWithName: @"value" type: (id)@"NSObject"];
	ETPropertyDescription *view = [ETPropertyDescription descriptionWithName: @"view" type: (id)@"NSView"];
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
	[contentAspect setRole: AUTORELEASE([ETMultiOptionsRole new])];
	[[contentAspect role] setAllowedOptions:
	 [D(@(ETContentAspectNone), _(@"None"),
		@(ETContentAspectComputed), _(@"Computed by Cover Style"),
		@(ETContentAspectCentered), _(@"Centered"),
		@(ETContentAspectScaleToFit), _(@"Scale To Fit"),
		@(ETContentAspectScaleToFill), _(@"Scale to Fill"),
		@(ETContentAspectScaleToFillHorizontally), _(@"Scale To Fill Horizontally"),
		@(ETContentAspectScaleToFillVertically), _(@"Scale to Fill Vertically"),
		@(ETContentAspectStretchToFill), _(@"Stretch to Fill"))
			arrayRepresentation]];
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
	ETPropertyDescription *x = [ETPropertyDescription descriptionWithName: @"x" type: (id)@"CGFloat"];
	ETPropertyDescription *y = [ETPropertyDescription descriptionWithName: @"y" type: (id)@"CGFloat"];
	ETPropertyDescription *width = [ETPropertyDescription descriptionWithName: @"width" type: (id)@"CGFloat"];
	ETPropertyDescription *height = [ETPropertyDescription descriptionWithName: @"height" type: (id)@"CGFloat"];
	ETPropertyDescription *target = [ETPropertyDescription descriptionWithName: @"target" type: (id)@"NSObject"];
	ETPropertyDescription *acceptsActions = [ETPropertyDescription descriptionWithName: @"acceptsActions" type: (id)@"BOOL"];
	// TODO: We should persist the inspector but how... We should use a better type than NSObject.
	ETPropertyDescription *inspector = [ETPropertyDescription descriptionWithName: @"inspector" type: (id)@"NSObject"];

	/* Widget Additional Properties */
	
	ETPropertyDescription *title = [ETPropertyDescription descriptionWithName: @"title" type: (id)@"NSString"];
	ETPropertyDescription *formatter = [ETPropertyDescription descriptionWithName: @"formatter" type: (id)@"NSObject"];
	ETPropertyDescription *objectValue = [ETPropertyDescription descriptionWithName: @"objectValue" type: (id)@"NSObject"];
	ETPropertyDescription *minValue = [ETPropertyDescription descriptionWithName: @"minValue" type: (id)@"double"];
	ETPropertyDescription *maxValue = [ETPropertyDescription descriptionWithName: @"maxValue" type: (id)@"double"];

	/* Pickboard Related Properties */

	// TODO: Turn into a persistent property (for pickboard persistency)
	ETPropertyDescription *pickMetadata = [ETPropertyDescription descriptionWithName: @"pickMetadata" type: (id)@"NSObject"];
	[pickMetadata setMultivalued: YES];
	[pickMetadata setKeyed: YES];

	/* Transient UI Builder Properties */

	ETPropertyDescription *UIBuilderAction = [ETPropertyDescription descriptionWithName: @"UIBuilderAction" type: (id)@"SEL"];
	[UIBuilderAction setDisplayName: @"Action"];
	ETPropertyDescription *attachedTool = [ETPropertyDescription descriptionWithName: @"attachedTool" type: (id)@"ETTool"];

	/* Transient ivars: 	
	   _isSyncingSupervisorViewGeometry, _scrollViewShown, _wasKVOStopped
	   
	   Hmm, _scrollViewShow ought to be persisted. */

	NSArray *persistentProperties = A(identifier, name, image, icon, 
		repObject, valueTransformers, valueKey, value, view, styleGroup, coverStyle,
		actionHandler, action, targetId, contentBounds, position, anchorPoint, 
		persistentFrame, autoresizing, contentAspect, boundingBox, defaultFrame,
		flipped, selected, selectable, visible);
	// TODO: title, objectValue, formatter, minValue and maxValue should
	// be declared among the persistent properties or we should support to
	// override the entity description bound to ETLayoutItem (making possible 
	// to redeclare these properties as persistent if no view is used).
	NSArray *transientProperties = A(parentItem, baseItem, rootItem, indexPath,
		isBaseItem, subject, style, frame, x, y, width, height, target, 
		acceptsActions, inspector, subtype, title, objectValue, formatter,
		minValue, maxValue, pickMetadata, UIBuilderAction, attachedTool);

	[entity setUIBuilderPropertyNames: (id)[[A(identifier, name, 
		image, icon, valueKey, target, UIBuilderAction, 
		frame, position, anchorPoint, autoresizing, contentAspect,
		flipped, selected, selectable, visible) mappedCollection] name]];

	[[persistentProperties mappedCollection] setPersistent: YES];
	[entity setPropertyDescriptions: [persistentProperties arrayByAddingObjectsFromArray: transientProperties]];

	return entity;
}

- (NSDictionary *) valueTransformers
{
	CODictionary *transformers = [self valueForVariableStorageKey: @"valueTransformers"];
	NSMutableDictionary *editableTransformers = [NSMutableDictionary dictionary];

	[[transformers content] enumerateKeysAndObjectsUsingBlock: ^ (id property, id transformerName,  BOOL *stop)
	{
		[editableTransformers setObject: [ETItemValueTransformer valueTransformerForName: transformerName]
		                         forKey: property];
	}];
	return [editableTransformers copy];
}

- (void) setValueTransformers: (NSDictionary *)editedTransformers
{
	[self willChangeValueForProperty: @"valueTransformers"];
	CODictionary *transformers = [self valueForVariableStorageKey: @"valueTransformers"];;
	[transformers removeAllObjects];

	[editedTransformers enumerateKeysAndObjectsUsingBlock: ^ (id property, id transformer, BOOL *stop)
	{
		ETAssert([ETItemValueTransformer valueTransformerForName: [transformer name]] == transformer);
		[transformers setObject: [transformer name]
		                forKey: property];
	}];
	[self didChangeValueForProperty: @"valueTransformers"];
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

	ETPropertyDescription *source = [ETPropertyDescription descriptionWithName: @"source" type: (id)@"NSObject"];
	ETPropertyDescription *delegate = [ETPropertyDescription descriptionWithName: @"delegate" type: (id)@"NSObject"];

	ETPropertyDescription *controller = [ETPropertyDescription descriptionWithName: @"controller" type: (id)@"ETController"];
	[controller setOpposite: (id)@"ETController.content"];

	ETPropertyDescription *doubleAction = 
		[ETPropertyDescription descriptionWithName: @"doubleAction" type: (id)@"SEL"];
	ETPropertyDescription *shouldMutateRepObject = 
		[ETPropertyDescription descriptionWithName: @"shouldMutateRepresentedObject" type: (id)@"BOOL"];
	[shouldMutateRepObject setDisplayName: @"Mutate Represented Object"];
	ETPropertyDescription *itemScaleFactor = 
		[ETPropertyDescription descriptionWithName: @"itemScaleFactor" type: (id)@"CGFloat"];
	// NOTE: _wasViewHidden must be persisted. If YES at deserialization, we 
	// unhide the item view.
	ETPropertyDescription *wasViewHidden = [ETPropertyDescription descriptionWithName: @"wasViewHidden" type: (id)@"BOOL"];

	/* Transient Properties */

	ETPropertyDescription *doubleClickedItem = [ETPropertyDescription descriptionWithName: @"doubleClickedItem" type: (id)@"ETLayoutItem"];

	// TODO: Declare the numerous derived (implicitly transient) properties we have 
	// descendantItemsSharingSameBaseItem, allDescendantItems, firstItem, 
	// lastItem, numberOfItems, canReload, canUpdateLayout, layoutView, 
	// visibleItems, visibleContentSize, selectionIndex, 
	// selectionIndexes, selectionIndexPaths, selectedItems, selectedInLayout, 
	// acceptsActionsForItemsOutsideOfFrame

	/* Transient ivars: 	
	   _sortedItems, _arrangedItems, _cachedDisplayImage, _reloading, 
	   _hasNewContent, _hasNewLayout, _hasNewArrangement, _sorted, _filtered,
	   _changingSelection */
	   
	/* Ignored ivars and properties:
	   _isLayerItem (unsupported) */

	NSArray *persistentProperties = A(items, layout, source, delegate, controller,
		doubleAction, shouldMutateRepObject, itemScaleFactor, wasViewHidden);
	NSArray *transientProperties = A(doubleClickedItem);

	[entity setUIBuilderPropertyNames: (id)[[A(delegate, doubleAction,
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
