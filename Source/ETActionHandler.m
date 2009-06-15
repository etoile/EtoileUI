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
#import "ETActionHandler.h"
#import "ETApplication.h"
#import "ETController.h"
#import "ETGeometry.h"
#import "ETLayoutItem.h"
#import "ETLayoutItemGroup.h"
#import "ETLayoutItemGroup+Mutation.h"
#import "ETPickDropCoordinator.h"
#import "ETPickboard.h"
#import "ETEvent.h"
#import "ETContainer.h"
#import "ETCompatibility.h"
#import "ETInstrument.h"
#import "ETShape.h"
#import "ETStyle.h"

#define SELECTION_BY_RANGE_KEY_MASK NSShiftKeyMask
#define SELECTION_BY_ONE_KEY_MASK NSCommandKeyMask

@implementation ETActionHandler

static NSMutableDictionary *sharedActionHandlers = nil;

+ (id) sharedInstance
{
	if (sharedActionHandlers == nil)
		sharedActionHandlers = [[NSMutableDictionary alloc] init];

	NSString *className = NSStringFromClass(self);
	id handler = [sharedActionHandlers objectForKey: className];
	if (handler == nil)
	{
		handler = AUTORELEASE([[self alloc] init]);
		[sharedActionHandlers setObject: handler
		                         forKey: className];
	}

	return handler;
}

/* <override-dummy />
Makes the clicked item the first responder of the active instrument.

Overrides this method when you want to customize how simple click are handled. */
- (void) handleClickItem: (ETLayoutItem *)item
{
	ETDebugLog(@"Click %@", item);
	[[ETInstrument activeInstrument] makeFirstResponder: (id)item];
}

/** <override-dummy />
Tries to send the double action bound to the base item or the parent item. The
parent item is used when double action is set on the base item. 

Each time a target can receive the action, the -doubleClickedItem property is 
updated on the base item or the parent item, otherwise it is set to nil, then 
the action is sent.

Overrides this method when you want to customize how double-click are handled. */
- (void) handleDoubleClickItem: (ETLayoutItem *)item
{
	ETDebugLog(@"Double click %@", item);

	ETLayoutItemGroup *itemGroup = [item parentItem];
	
	if ([[item baseItem] doubleAction] != NULL)
	{
		itemGroup = [item baseItem];
	}

	BOOL foundTarget = ([ETApp targetForAction: [itemGroup doubleAction] 
	                                        to: [itemGroup target]
	                                      from: itemGroup] != nil);
	if (foundTarget)
	{
		[itemGroup setValue: item forKey: kETDoubleClickedItemProperty];
	}
	else
	{
		[itemGroup setValue: nil forKey: kETDoubleClickedItemProperty];
	}
	
	[[ETApplication sharedApplication] sendAction: [itemGroup doubleAction] 
	                                           to: [itemGroup target] 
	                                         from: itemGroup];
}

- (void) handleDragItem: (ETLayoutItem *)item byDelta: (NSSize)delta
{
	ETDebugLog(@"Drag %@", item);
	[self handleTranslateItem: item byDelta: delta];
}

- (void) handleTranslateItem: (ETLayoutItem *)item byDelta: (NSSize)delta
{
	NSRect prevBoundingFrame = [item convertRectToParent: [item boundingBox]];

	[item setPosition: ETSumPointAndSize([item position], delta)];

	/* Compute and redisplay the translation area */
	NSRect newBoundingFrame = [item convertRectToParent: [item boundingBox]];
	NSRect dirtyRect = NSUnionRect(newBoundingFrame, prevBoundingFrame);
	[[item parentItem] setNeedsDisplayInRect: dirtyRect];
	[[item parentItem] displayIfNeeded];

	ETLog(@"Translate dirty rect %@", NSStringFromRect(dirtyRect));
}

/** <override-dummy />
Does nothing.

Overrides this method when you want to customize how enter are handled.<br />
You can use this method and -handleExitItem: to implement roll-over effect. */
- (void) handleEnterItem: (ETLayoutItem *)item
{
	ETDebugLog(@"Enter %@", item);
}

/** <override-dummy />
Does nothing.

Overrides this method when you want to customize how exit are handled. */
- (void) handleExitItem: (ETLayoutItem *)item
{
	ETDebugLog(@"Exit %@", item);
}

- (void) handleEnterChildItem: (ETLayoutItem *)childItem
{
	ETDebugLog(@"Exit child %@", childItem);
}

- (void) handleExitChildItem: (ETLayoutItem *)childItem
{
	ETDebugLog(@"Enter child %@", childItem);
}

/* Key Actions */

- (BOOL) handleKeyEquivalent: (id <ETKeyInputAction>)keyInput onItem: (ETLayoutItem *)item
{
	return NO;
}

- (void) handleKeyUp: (id <ETKeyInputAction>)keyInput onItem: (ETLayoutItem *)item
{
	// FIXME: -handleKeyUp: isn't declared anywhere...
	// [[item nextResponder] handleKeyUp: keyInput];
}

- (void) handleKeyDown: (id <ETKeyInputAction>)keyInput onItem: (ETLayoutItem *)item
{
	// FIXME: [[item nextResponder] handleKeyDown: keyInput];
}

/** Returns whether item can be selected or not. 

By default returns YES, except when the item is a base item, then returns NO. */
- (BOOL) canSelect: (ETLayoutItem *)item
{
	//if ([item isBaseItem])
	//	return NO;

	return YES;
}

/** Sets the item as selected and marks it to be redisplayed. */
- (void) handleSelect: (ETLayoutItem *)item
{
	ETLog(@"Select %@", item);
	[item setSelected: YES];
	[item setNeedsDisplay: YES];

	// TODO: Cache the selection in the controller if there is one
	//[[[item baseItem] controller] addSelectedObject: item];
}

/** Returns whether item can be deselected or not. 

By default returns YES.

TODO: Problably remove, since it should be of any use and just adds complexity. */
- (BOOL) canDeselect: (ETLayoutItem *)item
{
	return YES;
}

/** Sets the item as not selected and marks it to be redisplayed. */
- (void) handleDeselect: (ETLayoutItem *)item
{
	ETLog(@"Deselect %@", item);
	[item setSelected: NO];

	// TODO: May be cache in the controller... 
	//[[[item baseItem] controller] removeSelectedObject: item];
}

- (BOOL) canFill: (ETLayoutItem *)item
{
	return [[item style] respondsToSelector: @selector(setFillColor:)];
}

- (BOOL) canStroke: (ETLayoutItem *)item
{
	return [[item style] respondsToSelector: @selector(setStrokeColor:)];
}

- (void) handleFill: (ETLayoutItem *)item withColor: (NSColor *)aColor
{
	[[item style] setFillColor: aColor];
	[item setNeedsDisplay: YES];
}

- (void) handleStroke: (ETLayoutItem *)item withColor: (NSColor *)aColor
{
	[[item style] setStrokeColor: aColor];
	[item setNeedsDisplay: YES];
}

/* Generic Actions */

/** Overrides to return YES if you want that items to which the receiver is 
bound to can become first responder. By default, returns NO. */
- (BOOL) acceptsFirstResponder
{
	return YES;
}

/** Tells the receiver that the item to which it is bound is asked to become 
the first responder. Returns YES by default, to let the item become first 
responder.

Overrides to handle how the receiver or the item to which it is bound to, react 
to the first responder status (e.g. UI feedback).

Moreover this method can be used as a last chance to refuse this status. */
- (BOOL) becomeFirstResponder
{
	return YES;
}

/** Tells the receiver that the item to which it is bound is asked to hand  
on the first responder status. Returns YES by default, to let the item 
resigns from the first responder status.

Overrides to handle how the receiver or the item to which it is bound to, react  
to the loss of the first responder status (e.g. UI feedback).

Moreover this method can be used to prevent to hand over the first responder 
status, when others request it. */
- (BOOL) resignFirstResponder
{
	return YES;
}

- (BOOL) acceptsFirstMouse
{
	return NO;
}

- (void) sendBackward: (id)sender onItem: (ETLayoutItem *)item
{
	ETLayoutItemGroup *parent = [item parentItem];
	
	if ([item isEqual: [parent firstItem]])
		return;

	int currentIndex = [parent indexOfItem: item];

	RETAIN(item);
	[item removeFromParent];
	[parent insertItem: item atIndex: currentIndex - 1];
	RELEASE(item);
}

- (void) sendToBack: (id)sender onItem: (ETLayoutItem *)item
{
	ETLayoutItemGroup *parent = [item parentItem];
	
	if ([item isEqual: [parent firstItem]])
		return;

	RETAIN(item);
	[item removeFromParent];
	[parent insertItem: item atIndex: 0];
	RELEASE(item);
}

- (void) bringForward: (id)sender onItem: (ETLayoutItem *)item
{
	ETLayoutItemGroup *parent = [item parentItem];
	
	if ([item isEqual: [parent lastItem]])
		return;

	int currentIndex = [parent indexOfItem: item];

	RETAIN(item);
	[item removeFromParent];
	[parent insertItem: item atIndex: currentIndex + 1];
	RELEASE(item);
}

- (void) bringToFront: (id)sender onItem: (ETLayoutItem *)item
{
	ETLayoutItemGroup *parent = [item parentItem];
	
	if ([item isEqual: [parent lastItem]])
		return;

	RETAIN(item);
	[item removeFromParent];
	[parent addItem: item];
	RELEASE(item);
}

- (void) ungroup: (id)sender onItem: (ETLayoutItem *)item
{
	if ([item isGroup])
		[(ETLayoutItemGroup *)item unmakeGroup];
}

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
		uti = (ETUTI *)[[item representedObject] type];
	}
	else
	{
		uti = [item type];
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
	return [[item type] conformsToType: [self allowedPickTypeForItem: item]];
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
	return [[(NSObject *)droppedObject type] conformsToType: [self allowedDropTypeForItem: dropTarget]];
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
