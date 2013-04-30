/*
	Copyright (C) 2007 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  November 2007
	License:  Modified BSD (see COPYING)
 */

#import <EtoileFoundation/Macros.h>
#import <EtoileFoundation/ETCollection.h>
#import <EtoileFoundation/ETCollection+HOM.h>
#import <EtoileFoundation/ETKeyValuePair.h>
#import <EtoileFoundation/ETUTI.h>
#import <EtoileFoundation/NSObject+Etoile.h>
#import <EtoileFoundation/NSObject+Model.h>
#import "ETPickDropActionHandler.h"
#import "ETController.h"
#import "ETEvent.h"
#import "ETGeometry.h"
#import "ETTool.h"
#import "ETLayoutItemGroup.h"
#import "ETLayoutItem.h"
#import "ETLayoutExecutor.h"
#import "EtoileUIProperties.h"
#import "ETPickboard.h"
#import "ETPickDropCoordinator.h"
#import "ETSelectTool.h" /* For -shouldRemoveItemsAtPickTime */
#import "ETStyle.h"
#import "ETCompatibility.h"

#define SELECTION_BY_RANGE_KEY_MASK NSShiftKeyMask
#define SELECTION_BY_ONE_KEY_MASK NSCommandKeyMask


@implementation ETActionHandler (ETPickDropActionHandler)

/** Handles the drag request by both producing a pick action and starting a drag 
session.

This method can be called by the layout to synthetize a new drag (e.g. this 
method is called by ETTableLayout when rows are dragged). */
- (BOOL) handleDragItem: (ETLayoutItem *)item coordinator: (id)aPickCoordinator
{
	/* Find right now the layout which presents the item, its parent item might 
	   become nil with -handlePickItem:coordinator:. */
	ETLayout *layout = [[item ancestorItemForOpaqueLayout] layout];

	if (nil == layout || [layout isEqual: [item layout]])
	{
		layout = [[item parentItem] layout];
	}

	BOOL pickDisallowed = ([self handlePickItem: item coordinator: aPickCoordinator] == NO);

	if (pickDisallowed)
		return NO;

	/* We need to put something on the pasteboard otherwise AppKit won't 
	   allow the drag */
	NSPasteboard *pboard = [NSPasteboard pasteboardWithName: NSDragPboard];
	[pboard declareTypes: [NSArray arrayWithObject: ETLayoutItemPboardType] owner: nil];
	
	// TODO: Implements pasteboard compatibility to integrate with 
	// non-native Etoile code
	//NSData *data = [NSKeyedArchiver archivedDataWithRootObject: item];
	//[pboard setData: data forType: ETLayoutItemPboardType];

	[aPickCoordinator beginDragItem: item image: nil inLayout: layout];
	return YES;
}

- (BOOL) handlePickItem: (ETLayoutItem *)item coordinator: (id)aPickCoordinator
{
	NSParameterAssert(nil != item);

	if ([self canDragItem: item coordinator: aPickCoordinator] == NO)
	{
		[aPickCoordinator reset];
		return NO;
	}

	NSArray *selectedItems = [[item parentItem] selectedItemsInLayout];
	NSUInteger pickingMask = [[aPickCoordinator pickEvent] pickingMask];
	// TODO: pickboard shouldn't be harcoded but rather customizable
	ETPickboard *pboard = [ETPickboard localPickboard];
	id pick = nil;
	BOOL wasUsedAsRepObject = NO;

	/* If the dragged item is part of a selection which includes more than
	   one item, we put a pick collection on pickboard. But if the dragged
	   item isn't part of the selection, we don't put the selected items on
	   the pickboard. */
	if ([selectedItems count] > 1 && [selectedItems containsObject: item])
	{
		// TODO: Should use -pickedObjectForItem:
		NSArray *pickedItems = nil;
		
		if (pickingMask & ETCopyPickingMask)
		{
			pickedItems = [selectedItems valueForKey: @"deepCopy"];
			[pickedItems makeObjectsPerformSelector: @selector(release)];
		}
		else /* ETPickPickingMask or ETCutPickingMask */
		{
			pickedItems = selectedItems;
		}
		pick = [ETPickCollection pickCollectionWithCollection: pickedItems];
	}
	else
	{
		id pickedObject = [self pickedObjectForItem: item];
		//id hint = [self pickedHintForItem: item];

		if ([pickedObject isEqual: [item representedObject]])
		{
			wasUsedAsRepObject = YES;
		}

		if (pickingMask & ETCopyPickingMask)
		{
			pick = AUTORELEASE([pickedObject deepCopy]);
		}
		else /* ETPickPickingMask or ETCutPickingMask */
		{
			pick = pickedObject;
		}
	}

	NSUInteger pickIndex = [[item parentItem] indexOfItem: item];
	NSMapTable *draggedItems = [NSMapTable mapTableWithStrongToStrongObjects];

	[draggedItems setObject: item
	                 forKey: pick];

	[pboard pushObject: pick 
	          metadata: D([NSNumber numberWithUnsignedInteger: pickIndex], kETPickMetadataPickIndex,
			              [NSNumber numberWithBool: wasUsedAsRepObject], kETPickMetadataWasUsedAsRepresentedObject,
			              draggedItems, kETPickMetadataDraggedItems)];

	BOOL isMove = ((pickingMask & ETCopyPickingMask) == NO);

	if (isMove)
	{
		BOOL shouldRemoveItems = YES;
		BOOL isCut = (pickingMask & ETCutPickingMask);

		/* We always remove the items immediately when the pick is a cut */
		if (NO == isCut && [[ETTool activeTool] respondsToSelector: @selector(shouldRemoveItemsAtPickTime)])
		{
			shouldRemoveItems = [[ETTool activeTool] shouldRemoveItemsAtPickTime];
		}

		if (shouldRemoveItems)
		{
			if ([pick isKindOfClass: [ETPickCollection class]])
			{
				// FIXME: Doesn't work on Mac OS X 
				// [[[pick contentArray] map] removeFromParent];
				[[pick contentArray] makeObjectsPerformSelector: @selector(removeFromParent)];
			}
			else
			{
				[pick removeFromParent];
			}
			/* See similar call comment in 
			   -[ETPickDropCoordinator prepareInsertionForObject:metadata:atIndex:inItemGroup:] */
			[[ETLayoutExecutor sharedInstance] execute];
		}
	}

	return YES;
}

/** Returns the drop target item when -canDropObject:atIndex:onItem:coordinator:
returns YES, otherwise returns nil to denote an invalid drop or the drop target 
parent in case the object can be dropped on it.

The parent item is tested with -canDropObject:atIndex:onItem:coordinator:.

When the drop target is not an item group, the drop won't be validated.

You can override this method to implement other drop validation rules, which 
cannot be expressed with -allowedPickTypesForItem: and -allowedDropTypesForItem: 
whose UTIs are usually declared at the controller level.<br />
When the given index is equal to ETUndeterminedIndex, the drop operation is a 
'drop on' the drop target, otherwise the drop operation is 'drop insertion'. You 
are allowed to change the drop index which might also represent a new drop 
operation. e.g. <code>*anIndex = ETUndeterminedIndex</code> when anIndex was 3. */
- (ETLayoutItem *) handleValidateDropObject: (id)droppedObject
                                       hint: (id)aHint
                                    atPoint: (NSPoint)dropPoint
                              proposedIndex: (NSInteger *)anIndex
                                     onItem: (ETLayoutItem *)dropTarget
                                coordinator: (ETPickDropCoordinator *)aPickCoordinator
{
	//ETLog(@"DROP - Begin validate drop %@ at %ld on %@ in %@", [droppedObject primitiveDescription], (long)*anIndex, [dropTarget primitiveDescription], self);

	BOOL canDrop = [self canDropObject: droppedObject
	                           atIndex: *anIndex
	                            onItem: dropTarget
	                       coordinator: aPickCoordinator];
	BOOL retargetDrop = (NO == [dropTarget isGroup] || NO == canDrop);

	if (retargetDrop)
	{
		//NSLog(@"Retarget drop in action handler");
		ETLayoutItemGroup *parent = [dropTarget parentItem];
		NSInteger dropTargetIndex = [parent indexOfItem: dropTarget]; /* drop above or before */
		BOOL needsIndexAdjustment = (ETIsNullPoint(dropPoint) == NO);

		if (needsIndexAdjustment)
		{
			Class dropIndicatorClass = [[[parent layout] dropIndicator] class];
			NSPoint pointInParent = [dropTarget convertPointToParent: dropPoint];
			ETIndicatorPosition position = 
				[dropIndicatorClass indicatorPositionForPoint: pointInParent
				                                nearItemFrame: [dropTarget frame]];

			if (ETIndicatorPositionRight == position)
			{
				dropTargetIndex++;
			}
		}

		if (nil != parent && [[parent actionHandler] canDropObject: droppedObject
		                                                   atIndex: dropTargetIndex
		                                                    onItem: parent 
		                                               coordinator: aPickCoordinator])
		{
			*anIndex = dropTargetIndex;
			dropTarget = parent;
		}
		else
		{
			dropTarget = nil;
		}
	}

	ETDebugLog(@"DROP - End validate drop %@ at %ld on %@ in %@", [droppedObject primitiveDescription],
		(long)*anIndex, [dropTarget primitiveDescription], self);

	return dropTarget;
}

/** Inserts the dropped object at the given index in the drop target and 
returns YES on success and NO otherwise (e.g. an invalid index).

When the index is ETUndeterminedIndex, the dropped object is inserted as the 
last element in the drop target collection.

The dropped object can be a pick collection. See ETPickCollection.

The existing implementation requires drop targets to return YES to -isGroup and 
can unbox pick collections transparently (it inserts the elements into the drop 
target).

You can override this method to change how drop is handled. e.g. You might 
want to support dropping object on drop targets without requiring them to be 
item groups and reacts to that appropriately. */
- (BOOL) handleDropCollection: (ETPickCollection *)aPickCollection
                     metadata: (NSDictionary *)metadata
                      atIndex: (NSInteger)anIndex
                       onItem: (ETLayoutItem *)dropTarget
                  coordinator: (ETPickDropCoordinator *)aPickCoordinator
{
	// NOTE: To keep the order of the picked objects a reverse enumerator is 
	// used to balance the shifting of the last inserted object occurring on each insertion
	NSEnumerator *e = [[aPickCollection contentArray] reverseObjectEnumerator];
	BOOL result = NO;

	FOREACHE(nil, object, id, e)
	{
		id hint = [aPickCoordinator hintFromObject: &object];

		result |= [self handleDropObject: object 
		                            hint: hint
		                        metadata: metadata
		                         atIndex: anIndex 
		                          onItem: dropTarget 
		                     coordinator: aPickCoordinator];
	}
	return result;
}

- (void) commitDropOnItem: (ETLayoutItem *)dropTarget
{
	// TODO: Attempt to look up a short description from the metadata
	[dropTarget commitWithType: @"Item Insertion" shortDescription: @"Drop object"];
}

/** Inserts the dropped object at the given index in the drop target and 
returns YES on success and NO otherwise (e.g. an invalid index).

When the index is ETUndeterminedIndex, the dropped object is inserted as the 
last element in the drop target collection.

The dropped object can be a pick collection. See ETPickCollection.

The existing implementation requires drop targets to return YES to -isGroup and 
can unbox pick collections transparently (it inserts the elements into the drop 
target).

You can override this method to change how drop is handled. e.g. You might 
want to support dropping object on drop targets without requiring them to be 
item groups and reacts to that appropriately. */
- (BOOL) handleDropObject: (id)droppedObject
                     hint: (id)aHint
                 metadata: (NSDictionary *)metadata
                  atIndex: (NSInteger)anIndex
                   onItem: (ETLayoutItem *)dropTarget
              coordinator: (ETPickDropCoordinator *)aPickCoordinator
{
	// TODO: Improve insertion of arbitrary objects. All objects can be
	// dropped (NSArray, NSString, NSWindow, NSImage, NSObject, Class etc.)
	NSParameterAssert([dropTarget isGroup]);

	ETDebugLog(@"DROP - Handle drop %@ at %i on %@ in %@", droppedObject, (int)anIndex, dropTarget, self);
	
	NSInteger insertionIndex = anIndex;

	if (ETUndeterminedIndex == anIndex)
	{
		insertionIndex = [(ETLayoutItemGroup *)dropTarget numberOfItems];
	}

	[aPickCoordinator insertDroppedObject: droppedObject 
	                                 hint: aHint
	                             metadata: metadata
	                              atIndex: insertionIndex
	                          inItemGroup: (ETLayoutItemGroup *)dropTarget];

	// FIXME: We use this delayed commit to ensure the commit occurs at the
	// ending of the drop handling
	[self performSelector: @selector(commitDropOnItem:)
	           withObject: dropTarget
				afterDelay: 0.1];
	return YES;
}

/* Dragging Source
   This protocol is implemented to allow the use of ETLayoutItemGroup instances
   as drag source. An ancestor item group plays the role of the dragging source 
   when child items are dragged. */

/** Overrides this method if you want to turn off key modifier actions for 
	child items dragged from the receiver item group they belong to. */
- (BOOL) ignoreModifierKeysWhileDragging
{
	return NO;
}

/** <override-dummy />
Overrides to control how the dropped object is inserted: move, copy, link, etc.

This method is called on the action handler bound to the drag source item.

The destination item is usally the drop target, if 
-handleDropObject:onItem:atIndex:coordinator: doesn't insert the dropped object 
elsewhere.

You can use it to easily detect a local drop (a drag that begins and ends in the 
drag source). If <code>[[item baseItem] isEqual: [aPickCoordinator dragSource]]</code> 
evaluates to YES, then it is a local drop.

Take note that the destination item is the hint. It can be nil when the 
drop occurs in another application, or sometimes on a native widget without 
EtoileUI pick and drop integration (e.g. from a table layout to a text view).

By default, returns NSDragOperationEvery. */
- (unsigned int) dragOperationMaskForDestinationItem: (ETLayoutItem *)item
                                         coordinator: (ETPickDropCoordinator *)aPickCoordinator
{
	// NOTE: Cocoa uses NSDragOperationCopy | NSDragOperationLink | NSDragOperationGeneric | NSDragOperationPrivate
	return NSDragOperationEvery;
}

/** <override-dummy />
Returns whether the item must be inserted as a represented object in the drop target. 

By default, returns NO.

Can be overriden to return a custom value. A common choice would be:

<example>
return [[metadata objectForKey: kETPickMetadataWasUsedAsRepresentedObject] boolValue];
</example>

See also -[ETLayoutItemGroup insertObject:atIndex:hint:boxingForced:]. */
- (BOOL) boxingForcedForDroppedItem: (ETLayoutItem *)droppedItem 
                           metadata: (NSDictionary *)metadata
{
	return NO;
}

/* Drag Source Feedback */

- (void) handleDragItem: (ETLayoutItem *)draggedItem 
           beginAtPoint: (NSPoint)aPoint 
            coordinator: (id)aPickCoordinator
{
	ETDebugLog(@"DRAG SOURCE - Drag begin receives in dragging source %@", draggedItem);
}

- (void) handleDragItem: (ETLayoutItem *)draggedItem 
             moveToItem: (ETLayoutItem *)item
            coordinator: (id)aPickCoordinator
{
	//ETLog(@"DRAG SOURCE - Drag move receives in dragging source %@", draggedItem);
}

- (void) handleDragItem: (ETLayoutItem *)draggedItem 
              endAtItem: (ETLayoutItem *)item
           wasCancelled: (BOOL)cancelled
            coordinator: (id)aPickCoordinator
{
	ETDebugLog(@"DRAG SOURCE - Drag end receives in dragging source %@", draggedItem);

	if (cancelled)
	{
		//id draggedObject = [[ETPickboard localPickboard] popObject];
		
		ETDebugLog(@"Cancelled drag of %@ receives in dragging source %@",
			[[ETPickboard localPickboard] popObject], self);
	}
}

/** Drag Destination Feedback */

/** Allows to provide item with extra drop target behavior (e.g. custom visual 
feedback), when a dragged item moves over drop target area. */
- (NSDragOperation) handleDragMoveOverItem: (ETLayoutItem *)item 
                                  withItem: (ETLayoutItem *)draggedItem
                               coordinator: (id)aPickCoordinator
{
	//ETLog(@"DRAG DEST - Drag move receives in dragging destination %@", item);
	
	if ([self canDropObject: draggedItem atIndex: ETUndeterminedIndex onItem: item coordinator: aPickCoordinator] == NO)
		return NSDragOperationNone;
	
	return [aPickCoordinator dragOperationMaskForDestinationItem: item];
}

/** Allows to provide item with extra drop target behavior (e.g. custom visual 
feedback), when a dragged item enters the drop target area. */
- (NSDragOperation) handleDragEnterItem: (ETLayoutItem *)item
                               withItem: (ETLayoutItem *)draggedItem
                            coordinator: (id)aPickCoordinator
{
	ETDebugLog(@"DRAG DEST - Drag enter receives in dragging destination %@", item);

	if ([self canDropObject: draggedItem atIndex: ETUndeterminedIndex onItem: item coordinator: aPickCoordinator] == NO)
		return NSDragOperationNone;
	
	return [aPickCoordinator dragOperationMaskForDestinationItem: item];
}

/** Allows to provide item with extra drop target behavior (e.g. custom visual 
feedback), when a dragged item exits the drop target area. */
- (void) handleDragExitItem: (ETLayoutItem *)item
                   withItem: (ETLayoutItem *)draggedItem
                coordinator: (id)aPickCoordinator

{
	ETDebugLog(@"DRAG DEST - Drag exit receives in dragging destination %@", item);
}

/** Allows to provide item with extra drop target behavior (e.g. custom visual 
feedback), when a drag results in a drop or is cancelled on the drop target area. */
- (void) handleDragEndAtItem: (ETLayoutItem *)item
                    withItem: (ETLayoutItem *)draggedItem
                wasCancelled: (BOOL)cancelled
                 coordinator: (id)aPickCoordinator;
{
	ETDebugLog(@"DRAG DEST - Drag end receives in dragging destination %@", item);
}

/* Pick and Drop Filtering */

/** Returns the allowed pick UTIs specified in the controller bound to the base 
item of the given item. */
- (NSArray *) allowedPickTypesForItem: (ETLayoutItem *)item
{
	return [[[item baseItem] valueForProperty: kETControllerProperty] allowedPickTypes];
}

/** Returns the allowed drop UTIs specified in the controller bound to the base 
item of the given item. */
- (NSArray *) allowedDropTypesForItem: (ETLayoutItem *)item
{
	ETController *controller = [[item baseItem] valueForProperty: kETControllerProperty];
	ETUTI *uti = nil;

	if ([item representedObject] != nil)
	{
		uti = [[item representedObject] UTI];
	}
	else
	{
		uti = [item UTI];
	}

	return [controller allowedDropTypesForTargetType: uti];
}

/** <override-dummy />
Returns the object to be placed on the pickboard.

Can be overriden to return a custom object.
Avoid to return a copied object, otherwise the copy cursor badge won't be shown 
and the picked object might be unclear to the user.

By default, returns the represented object, or the item when no represented 
object is bound to it. */
- (id) pickedObjectForItem: (ETLayoutItem *)item
{
	id repObject = [item representedObject];

	if (repObject == nil)
		return item;

	return repObject;
}

- (id) pickedHintForItem: (ETLayoutItem *)item
{
	return ([[item representedObject] isKeyValuePair] ? [item representedObject] : nil);
}

/** Returns whether the item is draggable.

Returns YES when the item conforms to a pick type returned by 
-allowedPickTypesForItem:, otherwise returns NO. */
- (BOOL) canDragItem: (ETLayoutItem *)item
         coordinator: (ETPickDropCoordinator *)aPickCoordinator
{
	if ([aPickCoordinator isPickDropForced])
		return YES;

	// TODO: Would be nice to rewrite that with HOM but that might be too hard...
	// [[item UTI] conformsToType: [[self allowedDropTypesForItem: dropTarget] each]];
	// will return the last evaluated -conformsToType: result rather than exit
	// on the first conforming type.
	ETUTI *draggedType = [item UTI];

	FOREACH([self allowedPickTypesForItem: item], pickType, ETUTI *)
	{
		if ([draggedType conformsToType: pickType])
		{
			return YES;
		}
	}
	return NO;
}

/** Returns whether the dropped object can be inserted into the drop target.

Returns YES when the dropped object conforms to a drop type returned 
by -allowedDropTypesForItem: for the drop target, otherwise returns NO.

When the dropped object is a pick collection, each element type is checked with 
-conformsToType: (not yet). */
- (BOOL) canDropObject: (id)droppedObject
               atIndex: (NSInteger)dropIndex 
                onItem: (ETLayoutItem *)dropTarget
           coordinator: (ETPickDropCoordinator *)aPickCoordinator
{
	return YES;
	if ([droppedObject isEqual: dropTarget])
		return NO;

	if ([aPickCoordinator isPickDropForced])
		return YES;

	ETUTI *droppedType = [droppedObject UTI];

	FOREACH([self allowedDropTypesForItem: dropTarget], dropType, ETUTI *)
	{
		if ([droppedType conformsToType: dropType])
		{
			return YES;
		}
	}
	return NO;
}

- (ETLayoutItem *) pickedItemForTargetItem: (ETLayoutItem *)item
{
	if ([item isGroup] == NO)
		return item;

	NSArray *selectedItems = [(ETLayoutItemGroup *)item selectedItemsInLayout];

	if ([selectedItems isEmpty])
		return item;

	return [selectedItems firstObject];
}

/** Copies the item or the selected items inside it.

The copied items are put on the active pickboard.

The given item is usually the first responder when this action was triggered by 
choosing 'Copy' in the 'Edit' menu. */
- (IBAction) copy: (id)sender onItem: (ETLayoutItem *)item
{
	ETLog(@"Copy receives in %@", self);

	ETEvent *event = ETEVENT([NSApp currentEvent], nil, ETCopyPickingMask);

	[self handlePickItem: AUTORELEASE([[self pickedItemForTargetItem: item] deepCopy])
	         coordinator: [ETPickDropCoordinator sharedInstanceWithEvent: event]];
}

/** Pastes the first item or pick collection present on the active pickboard 
into the given item.

The pasted items won't removed from the pickboard.

The given item is usually the first responder when this action was triggered by 
choosing 'Paste' in the 'Edit' menu. */
- (IBAction) paste: (id)sender onItem: (ETLayoutItem *)item
{
	ETLog(@"Paste receives in %@", self);

	ETEvent *event = ETEVENT([NSApp currentEvent], nil, ETPastePickingMask);
	id pastedObject = AUTORELEASE([[[ETPickboard localPickboard] firstObject] deepCopy]);

	[self handleDropCollection: pastedObject
	                  metadata: [[ETPickboard localPickboard] firstObjectMetadata]
	                   atIndex: ETUndeterminedIndex
	                    onItem: item 
	               coordinator: [ETPickDropCoordinator sharedInstanceWithEvent: event]];
}

/** Cuts the item or the selected items inside it.

The cut items are put on the active pickboard and always removed immediately 
from their parents.<br />
The value returned by -shouldRemoveItemsAtPickTime on the active tool is 
simply ignored.

The given item is usually the first responder when this action was triggered by 
choosing 'Cut' in the 'Edit' menu. */
- (IBAction) cut: (id)sender onItem: (ETLayoutItem *)item
{
	ETLog(@"Cut receives in %@", self);

	ETEvent *event = ETEVENT([NSApp currentEvent], nil, ETCutPickingMask);
		
	[self handlePickItem: [self pickedItemForTargetItem: item]
	         coordinator: [ETPickDropCoordinator sharedInstanceWithEvent: event]];
}

@end
