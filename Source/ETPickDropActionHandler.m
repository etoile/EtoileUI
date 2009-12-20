/*
	Copyright (C) 2007 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  November 2007
	License:  Modified BSD (see COPYING)
 */

#import <EtoileFoundation/Macros.h>
#import <EtoileFoundation/ETCollection.h>
#import <EtoileFoundation/ETCollection+HOM.h>
#import <EtoileFoundation/ETUTI.h>
#import <EtoileFoundation/NSObject+Etoile.h>
#import <EtoileFoundation/NSObject+Model.h>
#import "ETPickDropActionHandler.h"
#import "ETController.h"
#import "ETEvent.h"
#import "ETGeometry.h"
#import "ETInstrument.h"
#import "ETLayoutItemGroup.h"
#import "ETLayoutItem.h"
#import "EtoileUIProperties.h"
#import "ETPickboard.h"
#import "ETPickDropCoordinator.h"
#import "ETSelectTool.h" /* For -shouldRemoveItemsAtPickTime */
#import "ETStyle.h"
#import "ETCompatibility.h"

const NSInteger ETUndeterminedIndex = -1;

#define SELECTION_BY_RANGE_KEY_MASK NSShiftKeyMask
#define SELECTION_BY_ONE_KEY_MASK NSCommandKeyMask


@implementation ETActionHandler (ETPickDropActionHandler)

/** Handles the drag request by both producing a pick action and starting a drag 
session.

This method can be called by the layout to synthetize a new drag (e.g. this 
method is called by ETTableLayout when rows are dragged). */
- (BOOL) handleDragItem: (ETLayoutItem *)item coordinator: (id)aPickCoordinator
{
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

	[aPickCoordinator beginDragItem: item image: nil];
	return YES;
}

- (BOOL) handlePickItem: (ETLayoutItem *)item coordinator: (id)aPickCoordinator
{
	NSParameterAssert(nil != item);

	if ([self canDragItem: item coordinator: aPickCoordinator] == NO)
		return NO;

	NSArray *selectedItems = [[item parentItem] selectedItems];
	ETEvent *pickInfo = [aPickCoordinator pickEvent];
	// TODO: pickboard shouldn't be harcoded but rather customizable
	ETPickboard *pboard = [ETPickboard localPickboard];
	id pick = nil;

	/* If the dragged item is part of a selection which includes more than
	   one item, we put a pick collection on pickboard. But if the dragged
	   item isn't part of the selection, we don't put the selected items on
	   the pickboard. */
	if ([selectedItems count] > 1 && [selectedItems containsObject: item])
	{
		NSArray *pickedItems = nil;
		
		if ([pickInfo pickingMask] & ETCopyPickingMask)
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
		if ([pickInfo pickingMask] & ETCopyPickingMask)
		{
			pick = AUTORELEASE([item deepCopy]);
		}
		else /* ETPickPickingMask or ETCutPickingMask */
		{
			pick = item;
		}
	}
	
	[pboard pushObject: pick];

	BOOL isMove = ~([pickInfo pickingMask] & ETCopyPickingMask);

	if (isMove)
	{
		BOOL shouldRemoveItems = YES;

		if ([[ETInstrument activeInstrument] respondsToSelector: @selector(shouldRemoveItemsAtPickTime)])
		{
			shouldRemoveItems = [[ETInstrument activeInstrument] shouldRemoveItemsAtPickTime];
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
'drop on'the drop target, otherwise the drop operation is 'drop insertion'. You 
are allowed to change the drop index which might also represent a new drop 
operation. e.g. <code>*anIndex = ETUndeterminedIndex</code> when anIndex was 3. */
- (ETLayoutItem *) handleValidateDropObject: (id)droppedObject
                                    atPoint: (NSPoint)dropPoint
                              proposedIndex: (NSInteger *)anIndex
                                     onItem: (ETLayoutItem *)dropTarget
                                coordinator: (ETPickDropCoordinator *)aPickCoordinator
{
	BOOL canDrop = [self canDropObject: droppedObject
	                           atIndex: *anIndex
	                            onItem: dropTarget
	                       coordinator: aPickCoordinator];
	BOOL retargetDrop = (NO == [dropTarget isGroup] || NO == canDrop);

	if (retargetDrop)
	{
		ETLayoutItemGroup *parent = [dropTarget parentItem];
		NSInteger dropTargetIndex = [parent indexOfItem: dropTarget]; /* drop above or before */
		BOOL needsIndexAdjustment = (ETIsNullPoint(dropPoint) == NO);

		if (needsIndexAdjustment)
		{
			Class dropIndicatorClass = [ETDropIndicator class]; // TODO: [[parent layout] dropIndicatorClass];
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

	//ETLog(@"DROP - Validate drop %@ at %i on %@ in %@", droppedObject, *anIndex, dropTarget, self);

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
- (BOOL) handleDropObject: (id)droppedObject
                  atIndex: (NSInteger)anIndex
                   onItem: (ETLayoutItem *)dropTarget
			  coordinator: (ETPickDropCoordinator *)aPickCoordinator
{
	NSParameterAssert([dropTarget isGroup]);

	ETLog(@"DROP - Handle drop %@ at %i on %@ in %@", droppedObject, anIndex, dropTarget, self);
	
	NSInteger insertionIndex = anIndex;

	if (ETUndeterminedIndex == anIndex)
	{
		insertionIndex = [(ETLayoutItemGroup *)dropTarget numberOfItems];
	}

	/* Will unbox a pick collection transparently */
	/*return*/ [aPickCoordinator itemGroup: (ETLayoutItemGroup *)dropTarget
		           insertDroppedObject: droppedObject 
		                       atIndex: insertionIndex];
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

- (unsigned int) draggingSourceOperationMaskForLocal: (BOOL)isLocal
{
	return NSDragOperationEvery;
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
		id draggedObject = [[ETPickboard localPickboard] popObject];
		
		ETLog(@"Cancelled drag of %@ receives in dragging source %@", 
			draggedObject, self);
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
	
	return [aPickCoordinator dragOperationMask];
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
	
	return [aPickCoordinator dragOperationMask];
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
-conformsToType:. */
- (BOOL) canDropObject: (id)droppedObject
               atIndex: (NSInteger)dropIndex 
                onItem: (ETLayoutItem *)dropTarget
           coordinator: (ETPickDropCoordinator *)aPickCoordinator
{
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

- (IBAction) copy: (id)sender onItem: (ETLayoutItem *)item
{
	ETLog(@"Copy receives in %@", self);
	
	[self handlePickItem: item coordinator: [ETPickDropCoordinator sharedInstance]];
}

- (IBAction) paste: (id)sender onItem: (ETLayoutItem *)item
{
	ETLog(@"Paste receives in %@", self);

	ETLayoutItem *pastedItem = [[ETPickboard localPickboard] popObject];
	
	[self handleDropObject: pastedItem 
	               atIndex: ETUndeterminedIndex
	                onItem: item 
	           coordinator: [ETPickDropCoordinator sharedInstance]];
}

- (IBAction) cut: (id)sender onItem: (ETLayoutItem *)item
{
	ETLog(@"Cut receives in %@", self);

	ETEvent *event = ETEVENT([NSApp currentEvent], nil, ETCutPickingMask);
		
	[self handlePickItem: item 
	         coordinator: [ETPickDropCoordinator sharedInstanceWithEvent: event]];
}

@end
