/*
	Copyright (C) 2009 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  April 2009
	License:  Modified BSD (see COPYING)
 */

#ifndef GNUSTEP
#import <Carbon/Carbon.h>
#endif
#import <EtoileFoundation/ETCollection.h>
#import "ETPickDropCoordinator.h"
#import "ETEvent.h"
#import "ETInstrument.h"
#import "ETLayoutItem.h"
#import "ETLayoutItemGroup.h"
#import "ETPickboard.h"
#import "ETPickDropActionHandler.h"
#import "ETStyle.h"
#import "ETStyleGroup.h"
#import "ETCompatibility.h"

@interface ETPickDropCoordinator (Private)
- (void) reset;

- (BOOL) ignoreModifierKeysWhileDragging;
- (unsigned int) draggingSourceOperationMaskForLocal: (BOOL)isLocal;
- (void) draggedImage: (NSImage *)anImage beganAt: (NSPoint)aPoint;
- (void) draggedImage: (NSImage *)draggedImage movedTo: (NSPoint)screenPoint;
- (void) draggedImage: (NSImage *)anImage
              endedAt: (NSPoint)aPoint 
            operation: (NSDragOperation)operation;

- (ETLayoutItem *) dropTargetForDrag: (id <NSDraggingInfo>)dragInfo;
- (void) insertDropIndicator: (ETDropIndicator *)indicator 
               forDropTarget: (ETLayoutItem *)dropTarget;
- (void) removeDropIndicatorForDropTarget: (ETLayoutItem *)dropTarget;
- (void) updateDropIndicator: (id <NSDraggingInfo>)dragInfo
              withDropTarget: (ETLayoutItem *)dropTarget;
- (ETLayoutItem *) hitTest: (id <NSDraggingInfo>)dragInfo;
- (BOOL) synthetizeIfNeededDragEnterAndExit: (id <NSDraggingInfo>)drag 
                                   withItem: (ETLayoutItem *)draggedItem
               andReturnsDragEnterOperation: (NSDragOperation *)dragOp;
- (void) cleanUpAfterDragOperation: (id <NSDraggingInfo>)dragInfo
                withLastDropTarget: (ETLayoutItem *)dropTarget;
@end


@implementation ETPickDropCoordinator

// TODO: We will need to support retrieving registered coordinators per 
// instrument/pointer when multiple pointers will be usable at the same time.

static ETPickDropCoordinator *sharedInstance = nil;

/** Returns the default pick and drop coordinator. */
+ (id) sharedInstance
{
	return [self sharedInstanceWithEvent: [sharedInstance pickEvent]];
}

/** Returns the default pick and drop coordinator reinitialized with a new 
event. */
+ (id) sharedInstanceWithEvent: (ETEvent *)anEvent
{
	if (sharedInstance == nil)
	{
		// TODO: Rework to look up the class to instantiate based on the 
		// linked/configured widged backend.
		sharedInstance = [[ETPickDropCoordinator alloc] init];
	}
	ASSIGN(sharedInstance->_event, anEvent);

	return sharedInstance; 
}

/** Returns the modifier that instruments should check to know when they should 
ignore pick and drop allowed types.

Returns NSShiftKeyMask by default.

When this modifier is pressed, drag an drop is enabled everywhere in the UI. */
+ (unsigned int) forceEnablePickAndDropModifier
{
	return NSShiftKeyMask;
}

/* Keep in sync with -reset when needed */
- (void) dealloc
{
	DESTROY(_event);
	DESTROY(_dragSource);
	DESTROY(_dragInfo);
	DESTROY(_previousDropTarget);
	DESTROY(_previousHoveredItem);
	[super dealloc];
}

/* Discards all drag session related data currently cached or maintained by the 
receiver. 

This method must be called when a drag session ends, otherwise the next one 
would be messed up. */
- (void) reset
{
	DESTROY(_event);
	DESTROY(_dragSource);
	DESTROY(_dragInfo);
	DESTROY(_previousDropTarget);
	DESTROY(_previousHoveredItem);
}

/** Starts a drag session to provide visual feedback throughout the dragging. 
customDragImage can be used to supercede the item icon that represents the 
dragged item from the beginning of the drag to the end. 

When item has a base item and this base item layout is not nil, this method
tries to delegate the expected behavior by forwarding the message to the layout 
(e.g. this method is implemented by ETTableLayout to disable the current 
method behavior). */
- (void) beginDragItem: (ETLayoutItem *)item image: (NSImage *)customDragImage
{
	NILARG_EXCEPTION_TEST(item)

	ETLayout *layout = [[item baseItem] layout];

	// TODO: Rethink the selector sent to the layout
	if (layout != nil && [layout respondsToSelector: @selector(beginDrag:forItem:image:layout:)])
	{
		[layout beginDrag: [self pickEvent] forItem: item image: customDragImage layout: layout];
	}
	else
	{
		NSParameterAssert([self pickEvent] != nil);

		ASSIGN(_dragSource, [item parentItem]);
	
		id dragSupervisor = [[self pickEvent] window];
		NSImage *dragIcon = customDragImage;
		
		if (dragIcon == nil)
			dragIcon = [item icon];
		
		// FIXME: Draw drag image made of all dragged items and not just first one
		[dragSupervisor dragImage: dragIcon
							   at: [[self pickEvent] locationInWindow]
						   offset: NSZeroSize
							event: (NSEvent *)[[self pickEvent] backendEvent] 
					   pasteboard: [NSPasteboard pasteboardWithName: NSDragPboard]
						   source: self
						slideBack: YES];
	}
}

/** Returns whether the current drop is a paste or the end of a drag. */
- (BOOL) isPasting
{
	// TODO: Improve... May be ([[self pickEvent] pickingMask] & ETDragPickingMask) == NO)
	// or ([[self dropEvent] pickingMask] & ETPastePickingMask) == NO)
	return ([self pickEvent] == nil); 
}

/** Returns whether a drag is currently underway. */
- (BOOL) isDragging
{
	return ([self pickEvent] != nil); 
}

/** Returns whether pick/drop are required and must be allowed without 
checking the allowed pick and drop types. 

See also +forceEnablePickAndDropModifier. */
- (BOOL) isPickDropForced
{
	return (([self modifierFlags] & [[self class] forceEnablePickAndDropModifier]) != 0);
}

/** Returns the current modifier flags consistently whether or not a drag 
session is underway. */
- (unsigned int) modifierFlags
{
	if ([self isDragging])
	{
		return [self dragModifierFlags];
	}
	else
	{
		return [[NSApp currentEvent] modifierFlags];
	}
}

/* Drag Session Infos */

/** Returns the pick event that initiated the drag session or leaded to the 
current drop. */
- (ETEvent *) pickEvent
{
	return _event;
}

/** Returns the parent item which the dragged item was belonging to or still 
belongs when -shouldRemoveItemsAtPickTime returns NO. */
- (ETLayoutItem *) dragSource
{
	return _dragSource;
}

/** Returns the key modifier combinations pressed within a drag session. 

The key combo is encoded as a bit field. */
- (unsigned int) dragModifierFlags
{
#ifndef GNUSTEP
	/* We query the hardware directly with Carbon, not pretty but it seems there 
	   is no way to get a DragRef within a Cocoa drag session. With a DragRef, 
	   we could use GetDragModifiers() which seems to be hardware-independent. */
	UInt32 carbonModifiers = GetCurrentKeyModifiers();
	unsigned int cocoaModifiers = 0;

	if (carbonModifiers & cmdKey)
	{
		cocoaModifiers |= NSCommandKeyMask;
	}
	if (carbonModifiers & shiftKey)
	{
		cocoaModifiers |= NSShiftKeyMask;
	}
	if (carbonModifiers & alphaLock)
	{
		cocoaModifiers |= NSAlphaShiftKeyMask;
	}
	if (carbonModifiers & optionKey)
	{
		cocoaModifiers |= NSAlternateKeyMask;
	}
	if (carbonModifiers & controlKey)
	{
		cocoaModifiers |= NSControlKeyMask;
	}

	return cocoaModifiers;
#else
	// FIXME: Find out how to query the key modifiers on GNUstep
	return [[self pickEvent] modifierFlags];
#endif
}

/** Returns the operations allowed on drop based on what the drag source 
action handler requests with -[ETActionHandler dragSourceOperationMaskForLocal:], 
and the modifiers currently pressed if 
-[ETActionHandler ignoreModifierKeysWhileDragging] returns NO. 

The aforementioned methods return values can be altered with their related 
setters in the ETActionHandler bound to the drag source. */
- (unsigned int) dragOperationMask
{
	// FIXME: Should rather be [_dragInfo draggingSourceOperationMask];
	return [self draggingSourceOperationMaskForLocal: YES];
}

// TODO: Keep or remove... Based on whether we want to extend the public API 
// a bit or not.
- (NSPoint) dragLocationInWindow
{
	return [_dragInfo draggingLocation];
}

/* NSDraggingSource informal protocol */

- (BOOL) ignoreModifierKeysWhileDragging
{
	return NO; //[[_dragSource actionHandler] ignoreModifierKeysWhileDragging];
}

- (unsigned int) draggingSourceOperationMaskForLocal: (BOOL)isLocal
{
	return NSDragOperationEvery;//[[_dragSource actionHandler] draggingSourceOperationMaskForLocal: isLocal];
}

- (void) draggedImage: (NSImage *)anImage beganAt: (NSPoint)aPoint
{
	NSPoint itemRelativeLoc = aPoint; // FIXME: Relative...

	[[[self dragSource] actionHandler] handleDragItem: [self dragSource]
	                                     beginAtPoint: itemRelativeLoc
	                                      coordinator: self];
}

- (void) draggedImage: (NSImage *)draggedImage movedTo: (NSPoint)screenPoint
{
	ETLayoutItem *dropTarget = nil; // FIXME: Do a hit test

	[[[self dragSource] actionHandler] handleDragItem: [self dragSource]
	                                       moveToItem: dropTarget
	                                      coordinator: self];
}

- (void) draggedImage: (NSImage *)anImage
              endedAt: (NSPoint)aPoint 
            operation: (NSDragOperation)operation
{
	ETLayoutItem *dropTarget = [self dropTargetForDrag: _dragInfo];

	[[[self dragSource] actionHandler] handleDragItem: [self dragSource]
	                                        endAtItem: dropTarget
	                                     wasCancelled: (operation == NSDragOperationNone)
	                                      coordinator: self];
}

/* Returns the window layer when the drag is exiting a window without 
entering a new one. */
- (ETLayoutItem *) dropTargetForDrag: (id <NSDraggingInfo>)dragInfo
{
	ETEvent *event = ETEVENT([NSApp currentEvent], dragInfo, ETDragPickingMask);
	ETLayoutItem *dropTarget = [[ETInstrument instrument] hitTestWithEvent: event];
	// FIXME: We should receive the dragged item as an argument, otherwise 
	// the next line might returns nil in case this item has already been 
	// popped. See e.g. -performDragOperation: where the line ordering matters.
	id pickedObject = [[ETPickboard localPickboard] firstObject];
	BOOL isOpaqueGroup = ([dropTarget isGroup] && [dropTarget layout] != nil 
		&& [[dropTarget layout] isOpaque]);
	NSPoint dropPoint = [event locationInLayoutItem];

	if (isOpaqueGroup)
	{
		dropTarget = [[dropTarget layout] itemAtLocation: dropPoint];
		dropPoint = [dropTarget convertPointFromParent: dropPoint];
	}

	_currentDropIndex = ETUndeterminedIndex;

	// FIXME: Use NSParameterAssert(dropTarget != nil && draggedItem != nil);
	// Fix to be done explained in -concludeDragOperation:.

	/* When the drop target item doesn't accept the drop we retarget it. It 
	   commonly occurs in the following cases: 
	   -isGroup returns NO
	   -allowsDropping returns NO
	   location outside of the drop on rect. */
	return [[dropTarget actionHandler] handleValidateDropObject: pickedObject 
	                                                    atPoint: dropPoint
	                                              proposedIndex: &_currentDropIndex
	                                                     onItem: dropTarget
	                                                coordinator: [ETPickDropCoordinator sharedInstance]];
}

- (ETDropIndicator *) dropIndicatorForDropTarget: (ETLayoutItem *)dropTarget
{
	return [[dropTarget styleGroup] firstStyleOfClass: [ETDropIndicator class]];
}

/* Inserts the drop indicator style in the style group of the given drop target 
item. */
- (void) insertDropIndicator: (ETDropIndicator *)indicator 
               forDropTarget: (ETLayoutItem *)dropTarget
{
	BOOL hasDropIndicatorAlready = ([[dropTarget styleGroup] 
		firstStyleOfClass: [ETDropIndicator class]] != nil);

	if (hasDropIndicatorAlready)
		return;

	ETLog(@"Insert drop indicator for %@", dropTarget);

	[[dropTarget styleGroup] addStyle: indicator];
}

- (void) removeDropIndicatorForDropTarget: (ETLayoutItem *)dropTarget
{
	ETDropIndicator *indicator = [self dropIndicatorForDropTarget: dropTarget];

	if (dropTarget == nil || indicator  == nil)
		return;

	/* Indicator is released -removeStyle:, hence we retrieve the rect before */
	NSRect prevIndicatorRect = [indicator previousIndicatorRect];
	
	[[dropTarget styleGroup] removeStyle: indicator];
	[dropTarget setNeedsDisplayInRect: prevIndicatorRect];
}


- (void) redisplayDropIndicatorIfNeeded: (ETDropIndicator *)indicator 
                          forDropTarget: (ETLayoutItem *)dropTarget
                                  force: (BOOL)forceDisplay 
{
	//ETLog(@"Try redisplay %@ %@", indicator, dropTarget);
	if (NSEqualRects([indicator currentIndicatorRect], [indicator previousIndicatorRect]) 
	 && forceDisplay == NO)
	{
		return;
	}

	/*ETLog(@"Redisplay drop indicator old %@ in %@ and new %@ in %@", 
		NSStringFromRect([indicator previousIndicatorRect]), _previousDropTarget, 
		NSStringFromRect([indicator currentIndicatorRect]), dropTarget);*/

	[dropTarget setNeedsDisplayInRect: [indicator previousIndicatorRect]];
	[dropTarget displayRect: [indicator currentIndicatorRect]];
}

- (void) updateDropIndicator: (id <NSDraggingInfo>)dragInfo
              withDropTarget: (ETLayoutItem *)dropTarget
{
	ETEvent *dragEvent = ETEVENT([NSApp currentEvent], dragInfo, ETDragPickingMask);
	ETLayoutItem *hoveredItem = [[ETInstrument instrument] hitTestWithEvent: dragEvent];
	BOOL dropOn = [hoveredItem isEqual: dropTarget];
	NSPoint locRelativeToDropTarget = [dragEvent locationInLayoutItem];

	//ETLog(@"Drop target %@ and event %@", dropTarget, dragEvent);

	if (dropOn == NO)
	{
		locRelativeToDropTarget = [hoveredItem convertPointToParent: [dragEvent locationInLayoutItem]];
	}

	/* Set up drop indicator */
	ETDropIndicator *indicator = nil;
	BOOL dropTargetChanged = ([dropTarget isEqual: _previousDropTarget] == NO);

	if (dropTargetChanged)
	{
		ETLog(@"Drop target changed from %@ to %@", _previousDropTarget, dropTarget);
		[self removeDropIndicatorForDropTarget: _previousDropTarget];
		indicator = AUTORELEASE([ETDropIndicator alloc]);	
	}
	else
	{
		indicator = [self dropIndicatorForDropTarget: dropTarget];
	}
	[indicator initWithLocation: locRelativeToDropTarget hoveredItem: hoveredItem isDropTarget: dropOn];

	[self insertDropIndicator: indicator forDropTarget: dropTarget];
	[self redisplayDropIndicatorIfNeeded: indicator 
	                       forDropTarget: dropTarget 
	                               force: NO];

	/* For the next time */
	ASSIGN(_previousDropTarget, dropTarget);
}

- (ETLayoutItem *) hitTest: (id <NSDraggingInfo>)dragInfo
{
	return [[ETInstrument instrument] hitTestWithEvent: 
		ETEVENT([NSApp currentEvent], dragInfo, ETDragPickingMask)];
}

- (BOOL) synthetizeIfNeededDragEnterAndExit: (id <NSDraggingInfo>)drag 
                                   withItem: (ETLayoutItem *)draggedItem
               andReturnsDragEnterOperation: (NSDragOperation *)dragOp
{
	ETLayoutItem *hoveredItem = [self hitTest: drag];
	BOOL hoveredItemIdentical = ([hoveredItem isEqual: _previousHoveredItem]);

	if (hoveredItemIdentical)
		return NO;

	[[_previousHoveredItem actionHandler] handleDragExitItem: _previousHoveredItem
	                                                withItem: draggedItem
	                                             coordinator: self];
	
	*dragOp = [[hoveredItem actionHandler] handleDragEnterItem: hoveredItem
	                                                 withItem: draggedItem
	                                               coordinator: self];
	return YES;
}

/* NSDraggingDestionation informal protocol */

- (NSDragOperation) draggingUpdated: (id <NSDraggingInfo>)drag
{
	/* First try whether it is a drag enter or exit */

	ETLayoutItem *draggedItem = [[ETPickboard localPickboard] firstObject];
	NSDragOperation dragOp = NSDragOperationEvery;
	/*BOOL isEnterExit = [self synthetizeIfNeededDragEnterAndExit: drag 
		withItem: draggedItem andReturnsDragEnterOperation: &dragOp];

	if (isEnterExit)
		return dragOp;*/

	/* Otherwise it is a drag move */
	ASSIGN(_dragInfo, drag);
	/* item can be nil, -itemAtLocation: doesn't return the receiver itself */
	id item = [self dropTargetForDrag: drag]; 
	if ([[item parentItem] indexOfItem: item] == 10)
	{
		ETLog(@"Blabla");
	}
	dragOp = [[item actionHandler] handleDragMoveOverItem: item 
	                                             withItem: draggedItem
	                                          coordinator: self];
	
	// NOTE: Testing non-nil layoutView is equivalent to
	// [[self layout] layoutView] != nil
	if (dragOp != NSDragOperationNone)// FIXME: && [[item supervisorView] layoutView] == nil)
		[self updateDropIndicator: drag withDropTarget: item];
		
	return dragOp;
}


- (NSDragOperation) draggingEntered: (id <NSDraggingInfo>)drag
{
	/* item can be nil, -itemAtLocation: doesn't return the receiver itself */
	id item = [self dropTargetForDrag: drag];
	id draggedItem = [[ETPickboard localPickboard] firstObject];

	// NOTE: We don't need to call -insertDropIndicator:forDropTarget: because 
	// -draggedEntered: is immediately followed by -draggingUpdated:.

	return 	[[item actionHandler] handleDragEnterItem: item withItem: draggedItem coordinator:	self];
}

- (void) draggingExited: (id <NSDraggingInfo>)drag
{
	ETLayoutItem *item = _previousDropTarget;
	ETLayoutItem *draggedItem = [[ETPickboard localPickboard] firstObject];
		
	[[item actionHandler] handleDragExitItem: item
	                                withItem: draggedItem 
	                             coordinator: [ETPickDropCoordinator sharedInstance]];

	// NOTE: To handle the case where we exit a window without entering a new 
	// one, then we reenter that window we just existed. If we let the ivar 
	// as is, -draggingUpdated: (see dropTargetChanged) will wrongly conclude we 
	// haven't exited the window when we reenter it .
	[self updateDropIndicator: drag withDropTarget: [self dropTargetForDrag: drag]];
}

- (void) draggingEnded: (id <NSDraggingInfo>)drag
{
	/* item can be nil, -itemAtLocation: doesn't return the receiver itself */
	id item = [self dropTargetForDrag: drag];
	id draggedItem = [[ETPickboard localPickboard] firstObject];
	
	[[item actionHandler] handleDragEndAtItem: item 
	                                 withItem: draggedItem 
	                             wasCancelled: YES 
	                              coordinator: [ETPickDropCoordinator sharedInstance]];

	[[ETPickboard localPickboard] popObject];
	[self cleanUpAfterDragOperation: drag withLastDropTarget: item];
	/*[self removeDropIndicatorForDropTarget: item];*/
	[self redisplayDropIndicatorIfNeeded: [self dropIndicatorForDropTarget: item]
	                       forDropTarget: item
								   force: YES];
	[self reset];
}

- (BOOL) prepareForDragOperation: (id <NSDraggingInfo>)drag
{
	return YES;
}

- (BOOL) performDragOperation: (id <NSDraggingInfo>)dragInfo
{
	ETLayoutItem *dropTarget = [self dropTargetForDrag: dragInfo];
	id droppedObject = [[ETPickboard localPickboard] popObject];

	NSParameterAssert(droppedObject != nil);

	ASSIGN(_dragInfo, dragInfo); // May be... ASSIGN(_dropEvent, [ETApp current
	BOOL dropSuccess = [[dropTarget actionHandler] handleDropObject: droppedObject
	                                                        atIndex: _currentDropIndex
	                                                         onItem: dropTarget 
	                                                    coordinator: self];
	return dropSuccess;
}

/* This method is called in replacement of -draggingEnded: when a drop has 
   occured. That's why it's not enough to clean insertion indicator in
   -draggingEnded:. Both methods called -handleDragEnd:forItem: on the 
   drop target item. */
- (void) concludeDragOperation: (id <NSDraggingInfo>)dragInfo
{
	/* item can be nil, -itemAtLocation: doesn't return the receiver itself */
	 // FIXME: We should cache the drop target rather than retrieving it like 
	 // that because the dragged item is nil now in -dropTargetForDrag:.
	ETLayoutItem *hoveredItem = [self dropTargetForDrag: dragInfo];
	ETPickboard *droppedItem = [[ETPickboard localPickboard] firstObject];
		
	[[hoveredItem actionHandler] handleDragEndAtItem: hoveredItem 
	                                        withItem: droppedItem 
	                                    wasCancelled: NO 
	                                     coordinator: self];
	[self cleanUpAfterDragOperation: dragInfo withLastDropTarget: _previousDropTarget];//hoveredItem];
}

- (void) cleanUpAfterDragOperation: (id <NSDraggingInfo>)dragInfo 
                withLastDropTarget: (ETLayoutItem *)dropTarget
{
	NSRect prevIndicatorRect = [[self dropIndicatorForDropTarget: dropTarget] previousIndicatorRect];

	[self removeDropIndicatorForDropTarget: dropTarget];
	[self redisplayDropIndicatorIfNeeded: [self dropIndicatorForDropTarget: dropTarget]
	                       forDropTarget: dropTarget
	                               force: YES];
	[dropTarget setNeedsDisplayInRect: prevIndicatorRect];
	[self reset];
}

/* Drop Insertion */

- (void) itemGroup: (ETLayoutItemGroup *)itemGroup 
	insertDroppedObject: (id)movedObject atIndex: (int)index
{
	ETLog(@"DROP - Insert dropped object %@ at %d into %@", movedObject, index, itemGroup);

	if ([movedObject isKindOfClass: [ETPickCollection class]])
	{
		// NOTE: To keep the order of picked objects a reverse enumerator 
		// is needed to balance the shifting of the last inserted object occurring on each insertion
		NSEnumerator *e = [[movedObject contentArray] reverseObjectEnumerator];
		ETLayoutItem *movedItem = nil;
		
		while ((movedItem = [e nextObject]) != nil)
			[self itemGroup: itemGroup insertDroppedItem: movedItem atIndex: index];
	}
	else if ([movedObject isKindOfClass: [ETLayoutItem class]])
	{
		[self itemGroup: itemGroup insertDroppedItem: movedObject atIndex: index];
	}
	else
	{
		// FIXME: Implement insertion of arbitrary objects. All objects can be
		// dropped (NSArray, NSString, NSWindow, NSImage, NSObject, Class etc.)
	}
}

- (void) itemGroup: (ETLayoutItemGroup *)itemGroup 
	insertDroppedItem: (id)movedItem atIndex: (int)index
{
	NSAssert2(index >= 0, @"Insertion index %d must be superior or equal to zero in %@ -insertDroppedObject:atIndex:", index, self);
	int insertionIndex = index;
	int pickIndex = [itemGroup indexOfItem: movedItem];
	BOOL isLocalPick = ([movedItem parentItem] == [itemGroup baseItem]);
	BOOL itemAlreadyRemoved = NO; // NOTE: Feature to be implemented
	
	RETAIN(movedItem);

	//[self setAutolayout: NO];
	 /* Dropped item is visible where it was initially located.
		If the flag is YES, dropped item is currently invisible. */
	if (itemAlreadyRemoved == NO)
	{
		/* We remove the item to handle the case where it is moved to another
		   index within the existing parent. */
		if (isLocalPick)
		{
			ETLog(@"For drop, removes item at index %d", pickIndex);
			[itemGroup removeItem: movedItem];
			if (insertionIndex > pickIndex)
				insertionIndex--;
		}
	}
	//[self setAutolayout: YES];

	ETLog(@"For drop, insert item at index %d", insertionIndex);

	[itemGroup insertItem: movedItem atIndex: insertionIndex];
	//[self setSelectionIndex: insertionIndex];

	RELEASE(movedItem);
}

@end


#if 0
		
- (void) handleDropForItem: (id)item
{

}

- (void) handleDropForObject: (id)object
{
	if ([[self allowedDroppingTypes] containsObject: [object UTI]] == NO)
		return;
		
	
	if ([object isKindOfClass: [ETLayoutItem class]])
	{
		[self handleDropForItem: object];
	}
	else
	{
		if (layout != nil && [layout respondsToSelector: @selector(handleDropForObject:)])
		{
			[layout handleDropForObject: item];
		}
		else
		{
			// TODO: pickboard shouldn't be harcoded but rather customizable
			ETPickboard *pickboard = [ETPickboard activePickboard];

			[dropTargetItem insertItems: [pickboard popObjectCollection] atIndex: ];
		}
	}
}

#endif
