/*
	Copyright (C) 2007 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  November 2007
	License:  Modified BSD (see COPYING)
 */

#import <EtoileFoundation/NSObject+Etoile.h>
#import <EtoileFoundation/NSObject+Model.h>
#import <EtoileFoundation/ETCollection.h>
#import <EtoileFoundation/ETUTI.h>
#import "ETPickDropActionHandler.h"
#import "ETController.h"
#import "ETInstrument.h"
#import "ETLayoutItem.h"
#import "ETLayoutItemGroup.h"
#import "ETPickDropCoordinator.h"
#import "ETPickboard.h"
#import "ETEvent.h"
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
	if ([self canDragItem: item coordinator: aPickCoordinator] == NO)
		return NO;
		
	ETLayoutItemGroup *baseItem = [item baseItem];
	NSArray *selectedItems = [baseItem selectedItemsInLayout];
	ETEvent *pickInfo = [aPickCoordinator pickEvent];
	// TODO: pickboard shouldn't be harcoded but rather customizable
	id pboard = [ETPickboard localPickboard];
	id pick = nil;
	
	/* No selection exists, we will pick the receiver
	   NOTE: otherwise we set a picked item when none exists to ensure
	   [selectedItems containsObject: item] can succeed when the pick isn't
	   a drag. A better solution could be introduce a ETPointerPickingMask 
	   (or ETMousePickingMask). */
	if (item == nil)
		item = [selectedItems isEmpty] ? (id)baseItem : [selectedItems firstObject];

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

	// TODO: Call back -handlePick:forItems:pickboard: which takes care of calling
	// pick and drop source methods when a source exists.
	return YES;
}

- (ETLayoutItem *) handleValidateDropObject: (id)droppedObject
                                     onItem: (ETLayoutItem *)dropTarget
                                coordinator: (id)aPickCoordinator
{
	BOOL canDrop = [self canDropObject: droppedObject
	                            onItem: dropTarget 
	                       coordinator: aPickCoordinator];
	BOOL retargetDrop = ([dropTarget isGroup] == NO || canDrop == NO);

	if (retargetDrop)
	{
		ETLayoutItemGroup *parent = [dropTarget parentItem];

		if (parent == nil)
			return nil;

		/* We try to find recursively a parent item which validates the drop */
		return [[parent actionHandler] handleValidateDropObject: droppedObject
		                                                 onItem: parent 
		                                            coordinator: aPickCoordinator];
	}

	return dropTarget;
}

/** You can override this method to change how drop is handled. The parameter
	item represents the dragged item which just got dropped on the receiver. */
- (BOOL) handleDropObject: (id)droppedObject
                   onItem: (ETLayoutItem *)dropTargetItem
			  coordinator: (id)aPickCoordinator
{
	ETDebugLog(@"DROP - Handle drop %@ for %@ on %@ in %@", aPickCoordinator, 
		droppedObject, dropTargetItem, self);

	ETLayoutItemGroup *baseItem = [dropTargetItem baseItem];
	int dropIndex = NSNotFound;

	if ([aPickCoordinator isPasting] == NO)
	{
		// FIXME: Do the coordinate conversion with ETLayoutItem API.
		NSPoint loc = [[baseItem supervisorView] convertPoint: [aPickCoordinator dragLocationInWindow] fromView: nil];
		dropIndex = [aPickCoordinator itemGroup: baseItem dropIndexAtLocation: loc withItem: droppedObject onItem: dropTargetItem];
	}
	
	NSAssert2([dropTargetItem isGroup], @"Drop target %@ must be a layout "
		"item group to accept dropped droppedObject %@ as a child", 
		dropTargetItem, droppedObject);
			
	// FIXME: Handle pick collection too.
	if (dropIndex != NSNotFound)
	{
		[aPickCoordinator itemGroup: (ETLayoutItemGroup *)dropTargetItem 
		        insertDroppedObject: droppedObject 
		                    atIndex: dropIndex];
		return YES;
	}
	else
	{

		[aPickCoordinator itemGroup: (ETLayoutItemGroup *)dropTargetItem 
		        insertDroppedObject: droppedObject 
		                    atIndex: [(ETLayoutItemGroup *)dropTargetItem numberOfItems]];
		return NO;
	}
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

- (BOOL) shouldRemoveItemsAtPickTime
{
	if ([[ETInstrument activeInstrument] respondsToSelector: @selector(shouldRemoveItemsAtPickTime)])
		return [[ETInstrument activeInstrument] shouldRemoveItemsAtPickTime];
		
	return NO;
}

/* Drag Source Feedback */

- (void) handleDragItem: (ETLayoutItem *)draggedItem 
           beginAtPoint: (NSPoint)aPoint 
            coordinator: (id)aPickCoordinator
{
	ETLog(@"DRAG SOURCE - Drag begin receives in dragging source %@", draggedItem);
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
	ETLog(@"DRAG SOURCE - Drag end receives in dragging source %@", draggedItem);

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
	
	if ([self canDropObject: draggedItem onItem: item coordinator: aPickCoordinator] == NO)
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

	if ([self canDropObject: draggedItem onItem: item coordinator: aPickCoordinator] == NO)
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
- (ETUTI *) allowedPickTypeForItem: (ETLayoutItem *)item
{
	return [[[item baseItem] valueForProperty: kETControllerProperty] allowedPickType];
}

/** Returns the allowed drop UTIs specified in the controller bound to the base 
item of the given item. */
- (ETUTI *) allowedDropTypeForItem: (ETLayoutItem *)item
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

	return [controller allowedDropTypeForTargetType: uti];
}

/** Returns whether the item is draggable.

Returns YES when the item conforms to the allowed pick types returned by 
-allowedPickUTIsForItem:, otherwise returns NO. */
- (BOOL) canDragItem: (ETLayoutItem *)item
         coordinator: (ETPickDropCoordinator *)aPickCoordinator
{
	if ([aPickCoordinator isPickDropForced])
		return YES;

	// FIXME: Rework ETUTI API a bit...
	//return [testedObject conformsToType: [ETUTI transientTypeWithSupertypes: 
	//	[self allowedPickUTIsForItem: item]]];
	return [[item UTI] conformsToType: [self allowedPickTypeForItem: item]];
}

/** Returns whether the dropped object can be inserted into the drop target.

Returns YES when the dropped object conforms to the allowed drop types returned 
by -allowedDropUTIsForItem: for the drop target, otherwise returns NO.

When the dropped object is a pick collection, each element type is checked with 
-conformsToType:. */
- (BOOL) canDropObject: (id)droppedObject 
                onItem: (ETLayoutItem *)dropTarget
           coordinator: (ETPickDropCoordinator *)aPickCoordinator
{
	if ([droppedObject isEqual: dropTarget])
		return NO;

	if ([aPickCoordinator isPickDropForced])
		return YES;

	// FIXME: Rework ETUTI API a bit...
	//return [testedObject conformsToType: [ETUTI transientTypeWithSupertypes: 
	//	[self allowedDropUTIsForItem: item]]];
	return [[(NSObject *)droppedObject UTI] conformsToType: [self allowedDropTypeForItem: dropTarget]];
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

/** This method is short-circuited by view-based layouts that come with their
	own drag and drop implementation. For example ETTableLayout handles the drag
	directly by catching the event, calling -[ETLayoutItem handleDrag:forItem:] 
	on the layout context and getting -[ETTableLayout beginDrag:forItem:image:] 
	invoked as a call back. 
	Layouts should -invoke -[ETLayoutItem handleDrag:forItem:] then they will
	receive -handleDrag:forItem:, -beginDrag:forItem:image: as call backs in
	case they decide to implement these methods. */
//- (void) mouseDragged: (ETEvent *)event on: (id)item

@end
