/*
	Copyright (C) 2011 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  June 2011
	License: Modified BSD (see COPYING)
 */

#import <EtoileFoundation/EtoileFoundation.h>
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
	[parentItem setOpposite: (id)@"ETLayoutItemGroup.items"];
	[parentItem setReadOnly: YES];
	[parentItem setDerived: YES];
    ETPropertyDescription *hostItem = [ETPropertyDescription descriptionWithName: @"hostItem" type: (id)@"ETLayoutItemGroup"];
	ETPropertyDescription *identifier = [ETPropertyDescription descriptionWithName: @"identifier" type: (id)@"NSString"];
	ETPropertyDescription *name = [ETPropertyDescription descriptionWithName: @"name" type: (id)@"NSString"];
	ETPropertyDescription *image = [ETPropertyDescription descriptionWithName: @"image" type: (id)@"NSImage"];
	[image setValueTransformerName: @"COObjectToArchivedData"];
	[image setPersistentTypeName: @"NSData"];
	ETPropertyDescription *icon = [ETPropertyDescription descriptionWithName: @"icon" type: (id)@"NSImage"];
	[icon setValueTransformerName: @"COObjectToArchivedData"];
	[icon setPersistentTypeName: @"NSData"];
	ETPropertyDescription *valueTransformers = [ETPropertyDescription descriptionWithName: @"valueTransformers" type: (id)@"ETItemValueTransformer"];
	[valueTransformers setMultivalued: YES];
	[valueTransformers setOrdered: NO];
	[valueTransformers setKeyed: YES];
	[valueTransformers setValueTransformerName: @"ETItemValueTransformerToString"];
	[valueTransformers setPersistentTypeName: @"NSString"];
	[valueTransformers setShowsItemDetails: YES];
	[valueTransformers setDetailedPropertyNames: A(@"name", @"transformCode", @"reverseTransformCode")];
	ETPropertyDescription *valueKey = [ETPropertyDescription descriptionWithName: @"valueKey" type: (id)@"NSString"];
	[valueKey setDerived: YES];
	ETPropertyDescription *value = [ETPropertyDescription descriptionWithName: @"value" type: (id)@"NSObject"];
	[value setDerived: YES];
	ETPropertyDescription *view = [ETPropertyDescription descriptionWithName: @"view" type: (id)@"NSView"];
	[view setPersistentTypeName: @"NSData"];
	ETPropertyDescription *styleGroup = [ETPropertyDescription descriptionWithName: @"styleGroup" type: (id)@"ETStyleGroup"];
	ETPropertyDescription *coverStyle = [ETPropertyDescription descriptionWithName: @"coverStyle" type: (id)@"ETStyle"];
	ETPropertyDescription *actionHandler = [ETPropertyDescription descriptionWithName: @"actionHandler" type: (id)@"ETActionHandler"];
	ETPropertyDescription *action = [ETPropertyDescription descriptionWithName: @"action" type: (id)@"SEL"];
	[action setPersistentTypeName: @"NSString"];
	/* We persist two distinct target references rather than the raw target, 
	   because we have no way to uniquely identify objects which are not items 
	   such as views */
	ETPropertyDescription *persistentTarget = [ETPropertyDescription descriptionWithName: @"persistentTarget" type: (id)@"COObject"];
	ETPropertyDescription *persistentTargetOwner = [ETPropertyDescription descriptionWithName: @"persistentTargetOwner" type: (id)@"ETLayoutItem"];
	ETPropertyDescription *contentBounds = [ETPropertyDescription descriptionWithName: @"contentBounds" type: (id)@"NSRect"];
	ETPropertyDescription *position = [ETPropertyDescription descriptionWithName: @"position" type: (id)@"NSPoint"];
	ETPropertyDescription *anchorPoint = [ETPropertyDescription descriptionWithName: @"anchorPoint" type: (id)@"NSPoint"];
	ETPropertyDescription *persistentFrame = [ETPropertyDescription descriptionWithName: @"persistentFrame" type: (id)@"NSRect"];
	// TODO: Enable when truly supported
	//ETPropertyDescription *transform = [ETPropertyDescription descriptionWithName: @"transform" type: (id)@"NSAffineTransform"];
	ETPropertyDescription *autoresizing = [ETPropertyDescription descriptionWithName: @"autoresizingMask" type: (id)@"NSUInteger"];
	ETPropertyDescription *contentAspect = [ETPropertyDescription descriptionWithName: @"contentAspect" type: (id)@"NSUInteger"];
	[contentAspect setRole: [ETMultiOptionsRole new]];
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
	ETPropertyDescription *flipped = [ETPropertyDescription descriptionWithName: @"flipped" type: (id)@"BOOL"];
	ETPropertyDescription *selected = [ETPropertyDescription descriptionWithName: @"selected" type: (id)@"BOOL"];
	ETPropertyDescription *selectable = [ETPropertyDescription descriptionWithName: @"selectable" type: (id)@"BOOL"];
	ETPropertyDescription *exposed = [ETPropertyDescription descriptionWithName: @"exposed" type: (id)@"BOOL"];
	ETPropertyDescription *hidden = [ETPropertyDescription descriptionWithName: @"hidden" type: (id)@"BOOL"];
	ETPropertyDescription *subtype = [ETPropertyDescription descriptionWithName: @"subtype" type: (id)@"ETUTI"];
	[subtype setValueTransformerName: @"ETUTIToString"];
	[subtype setPersistentTypeName: @"NSString"];
	ETPropertyDescription *scrollable = [ETPropertyDescription descriptionWithName: @"scrollable" type: (id)@"BOOL"];
	
	/* Represented Object Internal Persistent Properties */

	ETPropertyDescription *representedObjectKey = [ETPropertyDescription descriptionWithName: @"representedObjectKey" type: (id)@"NSString"];
	ETPropertyDescription *representedAttribute = [ETPropertyDescription descriptionWithName: @"representedAttribute" type: (id)@"NSObject"];
	ETPropertyDescription *representedOrderedAttribute = [ETPropertyDescription descriptionWithName: @"representedOrderedAttribute" type: (id)@"NSObject"];
	[representedOrderedAttribute setMultivalued: YES];
	[representedOrderedAttribute setOrdered: YES];
	ETPropertyDescription *representedUnorderedAttribute = [ETPropertyDescription descriptionWithName: @"representedUnorderedAttribute" type: (id)@"NSObject"];
	[representedUnorderedAttribute setMultivalued: YES];
	[representedUnorderedAttribute setOrdered: NO];
	ETPropertyDescription *representedRelationship = [ETPropertyDescription descriptionWithName: @"representedRelationship" type: (id)@"COObject"];
	ETPropertyDescription *representedOrderedRelationship = [ETPropertyDescription descriptionWithName: @"representedOrderedRelationship" type: (id)@"COObject"];
	[representedOrderedRelationship setMultivalued: YES];
	[representedOrderedRelationship setOrdered: YES];
	ETPropertyDescription *representedUnorderedRelationship = [ETPropertyDescription descriptionWithName: @"representedUnorderedRelationship" type: (id)@"COObject"];
	[representedUnorderedRelationship setMultivalued: YES];
	[representedUnorderedRelationship setOrdered: NO];

	/* Transient Properties */

	/* We declare only the transient properties that matters for a UI builder or 
	   document editor, because viewing or editing them in an inspector is useful. */

	// TODO: Declare -UTI in the transient properties (or rather at NSObject level)...

	ETPropertyDescription *visible = [ETPropertyDescription descriptionWithName: @"visible" type: (id)@"BOOL"];
	[visible setReadOnly: YES];
	[visible setDerived: YES];
	ETPropertyDescription *repObject = [ETPropertyDescription descriptionWithName: @"representedObject" type: (id)@"NSObject"];
	ETPropertyDescription *controllerItem = [ETPropertyDescription descriptionWithName: @"controllerItem" type: (id)@"ETLayoutItemGroup"];
	[controllerItem setReadOnly: YES];
	ETPropertyDescription *sourceItem = [ETPropertyDescription descriptionWithName: @"sourceItem" type: (id)@"ETLayoutItemGroup"];
	[sourceItem setReadOnly: YES];
	ETPropertyDescription *isMetaItem = [ETPropertyDescription descriptionWithName: @"isMetaItem" type: (id)@"BOOL"];
	[isMetaItem setReadOnly: YES];
	ETPropertyDescription *style = [ETPropertyDescription descriptionWithName: @"style" type: (id)@"ETStyle"];
	ETPropertyDescription *frame = [ETPropertyDescription descriptionWithName: @"frame" type: (id)@"NSRect"];
	ETPropertyDescription *x = [ETPropertyDescription descriptionWithName: @"x" type: (id)@"CGFloat"];
	ETPropertyDescription *y = [ETPropertyDescription descriptionWithName: @"y" type: (id)@"CGFloat"];
	ETPropertyDescription *width = [ETPropertyDescription descriptionWithName: @"width" type: (id)@"CGFloat"];
	ETPropertyDescription *height = [ETPropertyDescription descriptionWithName: @"height" type: (id)@"CGFloat"];
	ETPropertyDescription *target = [ETPropertyDescription descriptionWithName: @"target" type: (id)@"NSObject"];
	ETPropertyDescription *hasVerticalScroller = [ETPropertyDescription descriptionWithName: @"hasVerticalScroller" type: (id)@"BOOL"];
	ETPropertyDescription *hasHorizontalScroller = [ETPropertyDescription descriptionWithName: @"hasHorizontalScroller" type: (id)@"BOOL"];

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

	NSArray *persistentProperties = A(identifier, name, image, icon, representedObjectKey, 
		representedAttribute, representedOrderedAttribute, representedUnorderedAttribute,
		representedRelationship, representedOrderedRelationship, representedUnorderedRelationship,
		valueTransformers, view, styleGroup, coverStyle,
		actionHandler, action, persistentTarget, persistentTargetOwner,
		contentBounds, position, anchorPoint, persistentFrame, autoresizing,
		contentAspect, boundingBox, defaultFrame, flipped, selected, selectable,
		exposed, hidden, subtype, scrollable);
	// TODO: title, objectValue, formatter, minValue and maxValue should
	// be declared among the persistent properties or we should support to
	// override the entity description bound to ETLayoutItem (making possible 
	// to redeclare these properties as persistent if no view is used).
	NSArray *derivedProperties = A(parentItem, hostItem, controllerItem, sourceItem,
		isMetaItem, repObject, valueKey, value, visible, style, frame, x, y,
		width, height, target, hasVerticalScroller, hasHorizontalScroller);
	NSArray *transientProperties = [derivedProperties arrayByAddingObjectsFromArray:
		A(title, objectValue, formatter, minValue, maxValue, pickMetadata,
		UIBuilderAction, attachedTool)];

	[entity setUIBuilderPropertyNames: (id)[[A(identifier, name, 
		image, icon, valueKey, target, UIBuilderAction, 
		frame, position, anchorPoint, autoresizing, contentAspect,
		flipped, selected, selectable, visible, scrollable, hasVerticalScroller,
		hasHorizontalScroller) mappedCollection] name]];

	[[derivedProperties mappedCollection] setDerived: YES];
	[[persistentProperties mappedCollection] setPersistent: YES];
	[entity setPropertyDescriptions: [persistentProperties arrayByAddingObjectsFromArray: transientProperties]];

	return entity;
}

- (NSDictionary *) valueTransformers
{
	return [self valueForVariableStorageKey: @"valueTransformers"];
}

- (void) setValueTransformers: (NSDictionary *)editedTransformers
{
	[self willChangeValueForProperty: @"valueTransformers"];
	[self setValue: editedTransformers forVariableStorageKey: @"valueTransformers"];
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
	ETPropertyDescription *layout = [ETPropertyDescription descriptionWithName: @"layout" type: (id)@"ETLayout"];
	[layout setOpposite: (id)@"ETLayout.contextItem"];
	ETPropertyDescription *source = [ETPropertyDescription descriptionWithName: @"source" type: (id)@"NSObject"];
	[source setPersistentTypeName: @"COObject"];
	ETPropertyDescription *delegate = [ETPropertyDescription descriptionWithName: @"delegate" type: (id)@"COObject"];
	ETPropertyDescription *controller = [ETPropertyDescription descriptionWithName: @"controller" type: (id)@"ETController"];
	[controller setOpposite: (id)@"ETController.content"];
	ETPropertyDescription *doubleAction = 
		[ETPropertyDescription descriptionWithName: @"doubleAction" type: (id)@"SEL"];
	[doubleAction setPersistentTypeName: @"NSString"];
	ETPropertyDescription *shouldMutateRepObject = 
		[ETPropertyDescription descriptionWithName: @"shouldMutateRepresentedObject" type: (id)@"BOOL"];
	[shouldMutateRepObject setDisplayName: @"Mutate Represented Object"];
	ETPropertyDescription *itemScaleFactor = 
		[ETPropertyDescription descriptionWithName: @"itemScaleFactor" type: (id)@"CGFloat"];
	// NOTE: _wasViewHidden must be persisted. If YES at deserialization, we 
	// unhide the item view.
	ETPropertyDescription *wasViewHidden = [ETPropertyDescription descriptionWithName: @"wasViewHidden" type: (id)@"BOOL"];

	/* Transient Properties */
	
	/* We declare only the transient properties that matters for a UI builder or 
	   document editor, because viewing or editing them in an inspector is useful. */

	ETPropertyDescription *numberOfItems = [ETPropertyDescription descriptionWithName: @"numberOfItems" type: (id)@"NSInteger"];
	[numberOfItems setReadOnly: YES];
	[numberOfItems setDerived: YES];
	ETPropertyDescription *allDescendantItems = [ETPropertyDescription descriptionWithName: @"allDescendantItems" type: (id)@"ETLayoutItem"];
	[allDescendantItems setMultivalued: YES];
	[allDescendantItems setOrdered: YES];
	[allDescendantItems setDerived: YES];
	ETPropertyDescription *selectionIndex = [ETPropertyDescription descriptionWithName: @"selectionIndex" type: (id)@"NSUInteger"];
	[selectionIndex setDerived: YES];
	ETPropertyDescription *selectedItems = [ETPropertyDescription descriptionWithName: @"selectedItems" type: (id)@"ETLayoutItem"];
	[selectedItems setMultivalued: YES];
	[selectedItems setOrdered: YES];
	[selectedItems setDerived: YES];
	ETPropertyDescription *selectedItemsInLayout = [ETPropertyDescription descriptionWithName: @"selectedItemsInLayout" type: (id)@"ETLayoutItem"];
	[selectedItemsInLayout setMultivalued: YES];
	[selectedItemsInLayout setOrdered: YES];
	[selectedItemsInLayout setDerived: YES];
	ETPropertyDescription *isSorted = [ETPropertyDescription descriptionWithName: @"sorted" type: (id)@"BOOL"];
	[isSorted setReadOnly: YES];
	[isSorted setDerived: YES];
	ETPropertyDescription *isFiltered = [ETPropertyDescription descriptionWithName: @"filtered" type: (id)@"BOOL"];
	[isFiltered setReadOnly: YES];
	[isFiltered setDerived: YES];
	ETPropertyDescription *doubleClickedItem = [ETPropertyDescription descriptionWithName: @"doubleClickedItem" type: (id)@"ETLayoutItem"];
	[doubleClickedItem setReadOnly: YES];
	ETPropertyDescription *acceptsActionsForItemsOutsideOfFrame = [ETPropertyDescription descriptionWithName: @"acceptsActionsForItemsOutsideOfFrame" type: (id)@"BOOL"];
	[acceptsActionsForItemsOutsideOfFrame setReadOnly: YES];
	ETPropertyDescription *visibleContentSize = [ETPropertyDescription descriptionWithName: @"visibleContentSize" type: (id)@"NSSize"];
	[visibleContentSize setReadOnly: YES];
	[visibleContentSize setDerived: YES];

	/* The sorting and filtering state is transient, we recreate either in 
	   -[ETController didLoadObjectGraph] or later on -[ETLayoutItem reload].
	   This explains why we don't persist the arranged items. */

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
