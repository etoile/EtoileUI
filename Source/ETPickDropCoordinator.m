/*
	Copyright (C) 2009 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  April 2009
	License:  Modified BSD (see COPYING)
 */

#ifndef GNUSTEP
#import <Carbon/Carbon.h>
#endif
#import <EtoileFoundation/Macros.h>
#import <EtoileFoundation/ETCollection.h>
#import <EtoileFoundation/ETCollection+HOM.h>
#import <EtoileFoundation/ETKeyValuePair.h>
#import <EtoileFoundation/NSObject+HOM.h>
#import <EtoileFoundation/NSObject+Model.h>
#import <EtoileFoundation/NSMapTable+Etoile.h>
#import "ETPickDropCoordinator.h"
#import "ETEvent.h"
#import "ETGeometry.h"
#import "EtoileUIProperties.h"
#import "ETTool.h"
#import "ETLayoutItem.h"
#import "ETLayoutItemFactory.h"
#import "ETLayoutItemGroup.h"
#import "ETLayoutItemGroup+Mutation.h"
#import "ETPickboard.h"
#import "ETPickDropActionHandler.h"
#import "ETSelectTool.h" /* For -shouldRemoveItemsAtPickTime */
#import "ETStyle.h"
#import "ETStyleGroup.h"
#import "ETCompatibility.h"

@interface ETPickDropCoordinator (Private)
- (id) initWithEvent: (ETEvent *)anEvent;
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
// tool/pointer when multiple pointers will be usable at the same time.

static ETPickDropCoordinator *sharedInstance = nil;

/** Returns the default pick and drop coordinator. */
+ (id) sharedInstance
{
	if (nil == sharedInstance)
	{
		return [self sharedInstanceWithEvent: nil];
	}
	return sharedInstance;
}

/** Returns the default pick and drop coordinator reinitialized with a new 
event. */
+ (id) sharedInstanceWithEvent: (ETEvent *)anEvent
{
	if (sharedInstance == nil)
	{
		// TODO: Rework to look up the class to instantiate based on the 
		// linked/configured widged backend.
		sharedInstance = [[ETPickDropCoordinator alloc] initWithEvent: anEvent];
	}

	return [sharedInstance initWithEvent: anEvent];
}

- (id) initWithEvent: (ETEvent *)anEvent
{
	SUPERINIT
	[self reset];
	ASSIGN(_event, anEvent);
	return self;
}

/** Returns the modifier that tools should check to know when they should 
ignore pick and drop allowed types.

Returns NSShiftKeyMask by default.

When this modifier is pressed, drag an drop is enabled everywhere in the UI. */
+ (unsigned int) forceEnablePickAndDropModifier
{
	return NSShiftKeyMask;
}

- (BOOL) isPickDropEnabledForAllItems
{
	return _pickDropEnabledForAllItems;
}

- (void) setPickDropEnabledForAllItems: (BOOL)enabled
{
	_pickDropEnabledForAllItems = enabled;
}

- (void) dealloc
{
	[self reset];
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
	_currentDropIndex = ETUndeterminedIndex;
	_wereItemsRemovedAtPickTime = YES;
	_insertionShift = ETUndeterminedIndex;
}

/** Starts a drag session to provide visual feedback throughout the dragging.

customDragImage can be used to supercede the item icon that represents the 
dragged item from the beginning of the drag to the end.

aLayout must be the opaque layout in which the dragged item is presented or its 
parent item layout when no opaque layout is in use higher in the item tree.

Will raise an NSInvalidArgumentException when either the item or layout is nil.

When the item is presented in an opaque layout which returns YES to 
-hasBuiltInDragAndDropSupport, returns immediately.

See also -hasBuiltInDragAndDropSupport. */
- (void) beginDragItem: (ETLayoutItem *)item image: (NSImage *)customDragImage 
	inLayout: (ETLayout *)aLayout
{
	NILARG_EXCEPTION_TEST(item);
	NILARG_EXCEPTION_TEST(aLayout);
	NSParameterAssert([self pickEvent] != nil);

	/* To be sure -reset has been called */
	ETAssert(_dragSource == nil);

	// TODO: Might be better to use the base item or the parent item...
	ASSIGN(_dragSource, (ETLayoutItem *)[aLayout layoutContext]);
	ETAssert(_dragSource != nil);

	if ([[ETTool activeTool] respondsToSelector: @selector(shouldRemoveItemsAtPickTime)])
	{
		_wereItemsRemovedAtPickTime = [[ETTool activeTool] shouldRemoveItemsAtPickTime];
	}

	if ([[aLayout ifResponds] hasBuiltInDragAndDropSupport])
	{
		return;
	}

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

/** Returns whether the current drop is a paste or the end of a drag. */
- (BOOL) isPasting
{
	return ([self pickEvent] == nil && ([[self pickEvent] pickingMask] & ETPastePickingMask)); 
}

/** Returns whether a drag is currently underway. */
- (BOOL) isDragging
{
	return ([self pickEvent] != nil && ([[self pickEvent] pickingMask] & ETDragPickingMask)); 
}

/** Returns whether pick/drop are required and must be allowed without 
checking the allowed pick and drop types. 

See also +forceEnablePickAndDropModifier. */
- (BOOL) isPickDropForced
{
	BOOL isPickDropForcedByKey = 
		(([self modifierFlags] & [[self class] forceEnablePickAndDropModifier]) != 0);
	return (isPickDropForcedByKey || [self isPickDropEnabledForAllItems]);
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
	if (_dragInfo != nil)
	{
		ETAssert(_dragSource != nil);
	}
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
- (unsigned int) dragOperationMaskForDestinationItem: (ETLayoutItem *)item
{
	// TODO: Could need to be tweaked when pick and drop is forced or enabled 
	// for all items
	NSDragOperation op = [[[self dragSource] actionHandler] 
		dragOperationMaskForDestinationItem: item coordinator: self];

	if ([self ignoreModifierKeysWhileDragging])
		return op;

	NSUInteger modifiers = [self modifierFlags];

	if (modifiers & NSAlternateKeyMask)
	{
		op &= NSDragOperationCopy;
	}
	if (modifiers & NSCommandKeyMask)
	{
		op &= NSDragOperationGeneric;
	}
	if (modifiers & NSControlKeyMask)
	{
		op &= NSDragOperationLink;
	}
	return op;
}

/** Returns the current drag (and drop) location expressed in the item 
coordinate space.

If the item doesn't share a common ancestor item with the drag source, 
returns a ETNullPoint;

When the pick and drop operation is not a drag, returns a ETNullPoint too. */
- (NSPoint) dragLocationInDestinationItem: (ETLayoutItem *)item
{
	if ([self isDragging] && [[item rootItem] isEqual: [[self dragSource] rootItem]] == NO)
		return ETNullPoint;

	ETLayoutItemGroup *windowGroup = [[ETLayoutItemFactory factory] windowGroup];
	ETEvent *currentDragEvent = ETEVENT([NSApp currentEvent], _dragInfo, ETDragPickingMask);

	return [item convertRect: ETMakeRect([currentDragEvent location], NSZeroSize)
	                fromItem: windowGroup].origin;
}

/* NSDraggingSource informal protocol */

- (BOOL) ignoreModifierKeysWhileDragging
{
	return [[[self dragSource] actionHandler] ignoreModifierKeysWhileDragging];
}

/* Will be called when the drop target is a widget not integrated with EtoileUI 
pick and drop, or when the drop target is located in another process.

For example, ETTableLayout and ETOutlineLayout might call back this method in 
the cases described above. */
- (unsigned int) draggingSourceOperationMaskForLocal: (BOOL)isLocal
{
	// NOTE: Don't use -dragInfo, because the NSDraggingInfo object won't exist  
	// yet the first time this method is called
	ETLayoutItem *dropTarget = [self dropTargetForDrag: _dragInfo];

	return [[[self dragSource] actionHandler] dragOperationMaskForDestinationItem: dropTarget
	                                                                  coordinator: self];
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
	ETLayoutItem *dropTarget = [self dropTargetForDrag: _dragInfo];

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
	[self reset];
}

/* Returns the window layer when the drag is exiting a window without 
entering a new one. */
- (ETLayoutItem *) dropTargetForDrag: (id <NSDraggingInfo>)dragInfo
{
	ETEvent *event = ETEVENT([NSApp currentEvent], dragInfo, ETDragPickingMask);
	ETLayoutItem *dropTarget = [[ETTool tool] hitTestWithEvent: event];

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
	id hint = [self hintFromObject: &pickedObject];
	return [[dropTarget actionHandler] handleValidateDropObject: pickedObject 
	                                                       hint: hint
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
	ETLayoutItem *hoveredItem = [[ETTool tool] hitTestWithEvent: dragEvent];
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
		if (dropOn)
		{
			indicator = [[dropTarget layout] dropIndicator];
		}
		else
		{
			indicator = [[[dropTarget parentItem] layout] dropIndicator];
		}
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
	return [[ETTool tool] hitTestWithEvent: 
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
	ASSIGN(_dragInfo, (id)drag);
	/* item can be nil, -itemAtLocation: doesn't return the receiver itself */
	id item = [self dropTargetForDrag: drag]; 

	dragOp = [[item actionHandler] handleDragMoveOverItem: item 
	                                             withItem: draggedItem
	                                          coordinator: self];
	NSLog(@"Drag op %i", dragOp);
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
	NSDictionary *metadata = [[ETPickboard localPickboard] firstObjectMetadata];
	id droppedObject = [[ETPickboard localPickboard] popObjectAsPickCollection: YES];

	NSParameterAssert(droppedObject != nil);

	ASSIGN(_dragInfo, (id)dragInfo); // May be... ASSIGN(_dropEvent, [ETApp current
	BOOL dropSuccess = [[dropTarget actionHandler] handleDropCollection: droppedObject
	                                                           metadata: metadata
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

/** Returns whether the dragged items were removed immediately when they were picked.

By default, returns YES. During in a drag session only, can return NO.

See also -shouldRemoveItemsAtPickTime in ETTool subclasses that implements 
it such as ETSelectTool. */
- (BOOL) wereItemsRemovedAtPickTime
{
	return _wereItemsRemovedAtPickTime;
}

- (NSUInteger) prepareInsertionForObject: (id)droppedObject 
                                metadata: (NSDictionary *)metadata
                                 atIndex: (NSUInteger)index
                             inItemGroup: (ETLayoutItemGroup *)itemGroup
{
	NSParameterAssert(nil != itemGroup);
	NSParameterAssert(index >= 0);

	BOOL isShiftComputed = (_insertionShift != ETUndeterminedIndex);

	if (isShiftComputed)
	{
		return index - _insertionShift;
	}

	if ([self wereItemsRemovedAtPickTime] || [droppedObject isLayoutItem] == NO)
		return index;

	NSDragOperation op = [self dragOperationMaskForDestinationItem: itemGroup];

	if ((op & NSDragOperationMove) == NO)
		return index;

	 /* Dragged items are still visible where the pick occurred */

	NSMapTable *draggedItems = [metadata objectForKey: kETPickMetadataDraggedItems];
	ETAssert(draggedItems != nil);
	ETLayoutItem *targetedItem = ([itemGroup count] > index ? [itemGroup itemAtIndex: index] : nil);

	RETAIN(targetedItem);
	NSUInteger oldIndex = index;

	// NOTE: NSMapTable doesn't support the collection protocol yet
	[[[draggedItems allValues] mappedCollection] removeFromParent];

	NSUInteger newIndex = [itemGroup indexOfItem: targetedItem];
	RELEASE(targetedItem);

	_insertionShift = (newIndex != NSNotFound ? oldIndex - newIndex : 0);
	ETAssert(_insertionShift >= 0);

	return index - _insertionShift;
}

- (id) insertedObjectForDroppedObject: (id)droppedObject 
                                 hint: (id *)aHint
                          inItemGroup: (ETLayoutItemGroup *)itemGroup 
{
	NSDragOperation op = [self dragOperationMaskForDestinationItem: itemGroup];
	id object = nil;

	// TODO: Support other operations in a sensible way
	if (op &  NSDragOperationMove || op & NSDragOperationGeneric)
	{
		object = droppedObject;
	}
	else if (op & NSDragOperationCopy)
	{
		if ([droppedObject respondsToSelector: @selector(deepCopy)])
		{
			object = [droppedObject deepCopy];
		}
		else
		{
			// TODO: Should we just let -copy raises its exception abruptly if 
			// the object cannot be copied...
			object = [droppedObject copy];
		}

		if (*aHint != nil)
		{
			*aHint = [ETKeyValuePair pairWithKey: [*aHint key] value: object];
		}
	}
	return object;
}

- (id) hintFromObject: (id *)object
{
	// TODO: Introduce a more versatile hint support (not just limited to ETKeyValuePair)
	if ([*object isKeyValuePair])
	{
		id hint = *object;
		*object = [hint value];
		return hint;
	}
	return nil;
}

/** Inserts the dropped object at the given index in the item group.

When the dropped object is:
<list>
<item>a pick collection, each element is inserted</item>
<item>a layout item, it gets inserted as is</item/>
<item>another object kind, a layout item is instantiated based on the template 
item, and the object is set as its represented object or its value, then the 
item is inserted.</item>
</list>

See ETController to set the template item and 
-[NSObject(Model) isCommonObjectValue] in EtoileFoundation to know whether 
the object will be treated as a value or a represented object. */
- (void) insertDroppedObject: (id)droppedObject 
                        hint: (id)aHint 
                    metadata: (NSDictionary *)metadata
                     atIndex: (NSUInteger)index
                 inItemGroup: (ETLayoutItemGroup *)itemGroup 
{
	ETLog(@"DROP - Insert dropped object %@ at %d into %@", droppedObject, index, itemGroup);

	id insertedHint = aHint;
	id insertedObject = [self insertedObjectForDroppedObject: droppedObject
	                                                    hint: &insertedHint
	                                             inItemGroup: itemGroup];
												
	ETAssert(insertedObject != nil);

	NSUInteger insertionIndex = [self prepareInsertionForObject: insertedObject 
	                                                   metadata: metadata 
	                                                    atIndex: index 
	                                                inItemGroup: itemGroup];

	BOOL box = ([insertedObject isLayoutItem] 
		&& [[itemGroup actionHandler] boxingForcedForDroppedItem: insertedObject 
		                                                metadata: metadata]);

	BOOL sameBaseItemForSourceAndDestination = 
		[[itemGroup baseItem] isEqual: [[self dragSource] baseItem]];

	if (sameBaseItemForSourceAndDestination)
	{
		NSMapTable *draggedItems = [metadata objectForKey: kETPickMetadataDraggedItems];
		BOOL isDrag = (draggedItems != nil);

		if (isDrag)
		{
			insertedObject = [draggedItems objectForKey: droppedObject];
			// TODO: A bit ugly, remove the lookup with the hint. Put the hint in 
			// the metadata rather than pushing it on the pickboard.
			if (insertedObject == nil)
			{
				insertedObject = [draggedItems objectForKey: aHint];
			}
			box = NO;
		}
	}

	ETAssert(insertedObject != nil);

	ETLayoutItem *insertedItem = [itemGroup insertObject: insertedObject 
	                                             atIndex: insertionIndex 
	                                                hint: insertedHint 
	                                        boxingForced: box];

	ETAssert(insertedItem != nil);

	[insertedItem setPosition: [self dragLocationInDestinationItem: itemGroup]];
}

@end
