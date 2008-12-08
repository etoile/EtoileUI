/*  <title>ETLayoutItem+Events</title>

	ETLayoutItem+Events.m
	
	<abstract>The EtoileUI event handling model for the layout item tree. Also 
	defines the Pick and Drop model.</abstract>
 
	Copyright (C) 2007 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  November 2007
 
	Redistribution and use in source and binary forms, with or without
	modification, are permitted provided that the following conditions are met:

	* Redistributions of source code must retain the above copyright notice,
	  this list of conditions and the following disclaimer.
	* Redistributions in binary form must reproduce the above copyright notice,
	  this list of conditions and the following disclaimer in the documentation
	  and/or other materials provided with the distribution.
	* Neither the name of the Etoile project nor the names of its contributors
	  may be used to endorse or promote products derived from this software
	  without specific prior written permission.

	THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
	AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
	IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
	ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
	LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
	CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
	SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
	INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
	CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
	ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
	THE POSSIBILITY OF SUCH DAMAGE.
 */

#import <EtoileFoundation/NSObject+Model.h>
#import <EtoileFoundation/ETCollection.h>
#import <EtoileUI/ETLayoutItem+Events.h>
#import <EtoileUI/ETLayoutItemGroup.h>
#import <EtoileUI/ETPickboard.h>
#import <EtoileUI/ETEvent.h>
#import <EtoileUI/ETContainer.h>
#import <EtoileUI/ETCompatibility.h>

#define FORWARDER [self eventForwarder]

// TODO: When factoring out (ETEventHandler) in a standalone class, introduce 
// -eventForwarder that returns the layout item presently known as 'self'
@interface ETLayoutItem (ETEventHandlerPrivate)
- (NSArray *) selectedItems;
- (ETContainer *) container;
@end


@implementation ETLayoutItem (Events)

/** Returns the layout item that forwards events to the receiver. */
- (ETLayoutItem *) eventForwarder { return self; }

/* Returns the layout of the event forwarder when available, otherwise returns 
   nil. */
- (ETLayout *) layout
{
	if ([FORWARDER isGroup])
	{
		return [(ETLayoutItemGroup *)FORWARDER layout];
	}
	else
	{	
		return nil;
	}
}

/* Returns the selected items within the event forwarder when available, 
   otherwise returns nil. */
- (NSArray *) selectedItems
{
	if ([FORWARDER isGroup])
	{
		return [(ETLayoutItemGroup *)FORWARDER selectedItemsInLayout];
	}
	else
	{	
		return [NSArray array];
	}
}

/* Returns the container of the event forwarder when available, otherwise 
   returns nil. */
- (ETContainer *) container
{
	if ([FORWARDER isGroup] == NO)
		return nil;

	return [FORWARDER container];
}

- (IBAction) copy: (id)sender
{
	ETLog(@"Copy receives in %@", self);
	
	id event = ETEVENT([NSApp currentEvent], nil, ETCopyPickingMask);
	
	[self handlePick: event forItem: nil layout: [self  layout]];
}

- (IBAction) paste: (id)sender
{
	ETLog(@"Paste receives in %@", self);

	id event = ETEVENT([NSApp currentEvent], nil, ETPastePickingMask);
	id pastedItem = [[ETPickboard localPickboard] popObject];
	
	[self handleDrop: event forItem: pastedItem on: self];
}

- (IBAction) cut: (id)sender
{
	ETLog(@"Cut receives in %@", self);

	id event = ETEVENT([NSApp currentEvent], nil, ETCutPickingMask);
		
	[self handlePick: event forItem: nil layout: [self layout]];
}

- (BOOL) allowsDragging
{
	return [[self closestAncestorContainer] allowsDragging];
}

- (BOOL) allowsDropping
{
	return [[self closestAncestorContainer] allowsDropping];
}

- (BOOL) shouldRemoveItemsAtPickTime
{
	id container = [[self baseItem] container];
	
	if (container != nil)
		return [container shouldRemoveItemsAtPickTime];
		
	return NO;
}

- (void) mouseDown: (ETEvent *)event on: (id)item
{
	if ([self hasValidRepresentedPathBase])
	{
		 // For example ETFreeLayout could intercept click to disable standard interaction
		 // unlike ETUILayout. This case would also involve layout preemption of events.
		//[self handleClickForItem: item];
	}
	else
	{
		[[self parentLayoutItem] mouseDown: event on: item];
	}
}

- (void) mouseUp: (ETEvent *)event on: (id)item;
{	
	if ([self hasValidRepresentedPathBase])
	{
		// ?
	}
	else
	{
		[[self parentLayoutItem] mouseUp: event on: item];
	}
}


/** This method is short-circuited by view-based layouts that come with their
	own drag and drop implementation. For example ETTableLayout handles the drag
	directly by catching the event, calling -[ETLayoutItem handleDrag:forItem:] 
	on the layout context and getting -[ETTableLayout beginDrag:forItem:image:] 
	invoked as a call back. 
	Layouts should -invoke -[ETLayoutItem handleDrag:forItem:] then they will
	receive -handleDrag:forItem:, -beginDrag:forItem:image: as call backs in
	case they decide to implement these methods. */
- (void) mouseDragged: (ETEvent *)event on: (id)item
{
	if ([self allowsDragging] == NO)
		return;

	if ([self hasValidRepresentedPathBase])
	{
		id layout = nil;
		
		ETLog(@"Allowed dragging on selection");
		
		// NOTE: layout = [[item parentLayoutItem] layout] could make more sense
		if ([self isGroup])
			layout = [(ETLayoutItemGroup *)self layout];

		[self handleDrag: event forItem: item layout: layout];
	}
	else
	{
		[[self parentLayoutItem] mouseDragged: event on: item];
	}
}

- (void) handleMouseDown: (ETEvent *)event forItem: (id)item layout: (id)layout
{
	if (layout != nil && [layout respondsToSelector: @selector(handleMouseDown:forItem:layout:)])
	{
		[layout handleMouseDown: event forItem: item layout: layout];
	}
	else
	{
		// ?
	}
}

- (void) handleClick: (ETEvent *)event forItem: (id)item layout: (id)layout
{
	if (layout != nil && [layout respondsToSelector: @selector(handleClick:forItem:layout:)])
	{
		[layout handleClick: event forItem: item layout: layout];
	}
	else
	{
		// ?
	}
}

- (void) handlePick: (ETEvent *)event forItem: (id)item layout: (id)layout
{
	if (layout != nil && [layout respondsToSelector: @selector(handlePick:forItem:layout:)])
	{
		[layout handlePick: event forItem: item layout: layout];
	}
	else
	{
		NSArray *selectedItems = [self selectedItems];
		// TODO: pickboard shouldn't be harcoded but rather customizable
		id pboard = [ETPickboard localPickboard];
		id pick = nil;
		
		/* No selection exists, we will pick the receiver
		   NOTE: otherwise we set a picked item when none exists to ensure
		   [selectedItems containsObject: item] can succeed when the pick isn't
		   a drag. A better solution could be introduce a ETPointerPickingMask 
		   (or ETMousePickingMask). */
		if (item == nil)
			item = [selectedItems isEmpty] ? (id)self : [selectedItems firstObject];

		/* If the dragged item is part of a selection which includes more than
		   one item, we put a pick collection on pickboard. But if the dragged
		   item isn't part of the selection, we don't put the selected items on
		   the pickboard. */
		if ([selectedItems count] > 1 && [selectedItems containsObject: item])
		{
			NSArray *pickedItems = nil;
			
			if ([event pickingMask] & ETCopyPickingMask)
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
			if ([event pickingMask] & ETCopyPickingMask)
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
	}
}

// NOTE: ETOutlineLayout would override this method to call 
// -selectedItemsIncludingRelatedDescendants instead of -selectedItems	
//[pickboard pushObject: [ETPickCollection pickCollectionWithCollection: [self selectedItems]];
- (void) handleDrag: (ETEvent *)event forItem: (id)item layout: (id)layout
{
	if (layout != nil && [layout respondsToSelector: @selector(handleDrag:forItem:layout:)])
	{
		[layout handleDrag: event forItem: item layout: layout];
	}
	else
	{
		[self handlePick: event forItem: item layout: layout];
		
		/* We need to put something on the pasteboard otherwise AppKit won't 
		   allow the drag */
		NSPasteboard *pboard = [NSPasteboard pasteboardWithName: NSDragPboard];
		[pboard declareTypes: [NSArray arrayWithObject: ETLayoutItemPboardType] owner: nil];
		
		// TODO: Implements pasteboard compatibility to integrate with 
		// non-native Etoile code
		//NSData *data = [NSKeyedArchiver archivedDataWithRootObject: item];
		//[pboard setData: data forType: ETLayoutItemPboardType];
		
		[self beginDrag: event forItem: item image: nil layout: layout];
	}
}

/* ETLayoutItem specific method to create a new drag and passing the request to 
   data source. */
- (void) beginDrag: (ETEvent *)event forItem: (id)item 
	image: (NSImage *)customDragImage layout: (id)layout
{
	if (layout != nil && [layout respondsToSelector: @selector(beginDrag:forItem:image:layout:)])
	{
		[layout beginDrag: event forItem: item image: customDragImage layout: layout];
	}
	else
	{
		id dragSupervisor = [event window];
		NSImage *dragIcon = customDragImage;
		
		if (dragIcon == nil)
			dragIcon = [item icon];
		
		// FIXME: Draw drag image made of all dragged items and not just first one
		[dragSupervisor dragImage: dragIcon
							   at: [event locationInWindow]
						   offset: NSZeroSize
							event: (NSEvent *)[event backendEvent] 
					   pasteboard: [NSPasteboard pasteboardWithName: NSDragPboard]
						   source: self
						slideBack: YES];
	}
}

- (NSDragOperation) handleDragMove: (id)dragInfo forItem: (id)item
{
	//ETLog(@"DRAG DEST - Drag move receives in dragging destination %@", self);
	
	if ([self allowsDropping] == NO)
		return NSDragOperationNone;
	
	return [dragInfo draggingSourceOperationMask];
}

- (NSDragOperation) handleDragEnter: (id)dragInfo forItem: (id)item
{
	ETLog(@"DRAG DEST - Drag enter receives in dragging destination %@", self);

	if ([self allowsDropping] == NO)
		return NSDragOperationNone;
	
	return [dragInfo draggingSourceOperationMask];
}

- (void) handleDragExit: (id)dragInfo forItem: (id)item
{
	ETLog(@"DRAG DEST - Drag exit receives in dragging destination %@", self);
}

- (void) handleDragEnd: (id)dragInfo forItem: (id)item on: (id)dropTargetItem
{
	ETLog(@"DRAG DEST - Drag end receives in dragging destination %@", self);
}

- (BOOL) acceptsDropAtLocationInWindow: (NSPoint)loc
{
	NSPoint itemRelativeLoc = loc; // FIXME: Convert to local coordinates
	
	return ([self isGroup]
	     && [self allowsDropping]
		 && (NSPointInRect(itemRelativeLoc, [self dropOnRect]) == NO));
}

- (NSRect) dropOnRect
{
	return NSZeroRect;
}

/** You can override this method to change how drop is handled. The parameter
	item represents the dragged item which just got dropped on the receiver. */
- (BOOL) handleDrop: (id)dragInfo forItem: (id)item on: (id)dropTargetItem;
{
	ETLog(@"DROP - Handle drop %@ for %@ on %@ in %@", dragInfo, item, dropTargetItem, self);

	if ([self hasValidRepresentedPathBase])
	{
		int dropIndex = NSNotFound;

		if (dragInfo != nil) /* If the drop isn't a paste */
		{
			NSPoint loc = [[self container] convertPoint: [dragInfo draggingLocation] fromView: nil];
			dropIndex = [self itemGroup: (ETLayoutItemGroup *)self dropIndexAtLocation: loc forItem: item on: dropTargetItem];
		}
		
		NSAssert2([dropTargetItem isGroup], @"Drop target %@ must be a layout "
			@"item group to accept dropped item %@ as a child", dropTargetItem, 
			item);
				
		// FIXME: Handle pick collection too.
		if (dropIndex != NSNotFound)
		{
			[self itemGroup: dropTargetItem insertDroppedObject: item atIndex: dropIndex];
			return YES;
		}
		else
		{

			[self itemGroup: dropTargetItem insertDroppedObject: item atIndex: [dropTargetItem numberOfItems]];
			return NO;
		}
	}
	else
	{
		return [[self parentLayoutItem] handleDrop: dragInfo forItem: item on: dropTargetItem];
	}
}

- (BOOL) handlePick: (ETEvent *)event forItems: (NSArray *)items pickboard: (ETPickboard *)pboard
{
	id source = [[self container] source];
	BOOL pickValidated = YES;
	
	if (source != nil 
	 && [source respondsToSelector: @selector(container:handlePick:forItems:pickboard:)])
	{
		pickValidated = [source container: [self container] handlePick: event forItems: items pickboard: pboard];
	}
	else
	{
		// TODO: Implement removal of the picked items at pick time when the
		// the developer requests it by calling a method like
		// -setRemovesItemAtPickTime. For now, items are removed from their  
		// parent on drop.
	}
	
	return pickValidated;
}

- (BOOL) handleAcceptDrop: (id)dragInfo forItems: (NSArray *)items on: (id)item pickboard: (ETPickboard *)pboard
{
	id source = [[self container] source];
	BOOL dropAccepted = YES;
	
	if (source != nil 
	 && [source respondsToSelector: @selector(container:handleAcceptDrop:forItems:on:pickboard:)])
	{
		dropAccepted = [source container: [self container] handleAcceptDrop: dragInfo forItems: items on: item pickboard: pboard];
	}
	else
	{

	}
	
	return dropAccepted;
}

- (BOOL) handleDrop: (id)dragInfo forItems: (NSArray *)items on: (id)item pickboard: (ETPickboard *)pboard
{
	id source = [[self container] source];
	BOOL dropValidated = YES;
	
	if (source != nil 
	 && [source respondsToSelector: @selector(container:handleDrop:forItems:on:pickboard:)])
	{
		dropValidated = [source container: [self container] handleDrop: dragInfo forItems: items on: item pickboard: pboard];
	}
	else
	{

	}
	
	return dropValidated;
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

- (void) draggedImage: (NSImage *)anImage beganAt: (NSPoint)aPoint
{
	//ETLog(@"DRAG SOURCE - Drag began receives in dragging source %@", self);
}

- (void) draggedImage: (NSImage *)draggedImage movedTo: (NSPoint)screenPoint
{
	//ETLog(@"DRAG SOURCE - Drag move receives in dragging source %@", self);
}

- (void) draggedImage: (NSImage *)anImage endedAt: (NSPoint)aPoint operation: (NSDragOperation)operation
{
	ETLog(@"DRAG SOURCE - Drag end receives in dragging source %@", self);
	
	if (operation == NSDragOperationNone)
	{
		id draggedObject = [[ETPickboard localPickboard] popObject];
		
		ETLog(@"Cancelled drag of %@ receives in dragging source %@", 
			draggedObject, self);
	}
}

- (int) itemGroup: (ETLayoutItemGroup *)itemGroup dropIndexAtLocation: (NSPoint)localDropPosition 
	forItem: (id)item on: (id)dropTargetItem
{
	id layout = [itemGroup layout];
	
	if (layout != nil && [layout respondsToSelector: @selector(dropIndexAtLocation:forItem:on:)])
	{
		return [layout dropIndexAtLocation: localDropPosition forItem: item on: dropTargetItem];
	}
	else
	{
		NSAssert2([dropTargetItem isGroup], @"Drop target item %@ must be a group "
			@"in event handler %@", dropTargetItem, self);
	
		id hoveredItem = [[(ETLayoutItemGroup *)dropTargetItem layout] itemAtLocation: localDropPosition];
		int dropIndex = NSNotFound;
		NSRect dropTargetRect = NSZeroRect;
		
		ETLog(@"Found item %@ as drop target and %@ as hovered item", 
			dropTargetItem, hoveredItem);
			
		NSAssert2([[dropTargetItem items] containsObject: hoveredItem], 
			@"Hovered item %@ must be a child of drop target item %@", 
			hoveredItem, dropTargetItem);
		
		/* Drop occured a child item of the receiver. For now the drop is 
		   automatically retargeted to insert the item to the right or the left
		   of the hovered item. */
		if (item != nil && [hoveredItem isEqual: self] == NO)
		{
			/* Find where the item should be inserted. Drop target item will
			   be the item where the dropped item is inserted. Hovered item
			   is the item which intersects the drop location. */
			dropIndex = [dropTargetItem indexOfItem: hoveredItem];
			
			/* Increase index if the insertion is located on the right of hoveredItem */
			// FIXME: Handle layout orientation, only works with horizontal layout
			// currently.
			dropTargetRect = [layout displayRectOfItem: hoveredItem];
			if (localDropPosition.x > NSMidX(dropTargetRect))
				dropIndex++;
		}
		else
		{
			 /* When drop occurs on the receiver itself which is the item 
			    handling the drop. For example, this item could be a container 
				with a flow layout and the drop occured on a empty area where
				no child items are displayed. */
			dropIndex = [itemGroup numberOfItems] - 1;
		}
			
		return dropIndex;
	}
}

- (void) itemGroup: (ETLayoutItemGroup *)itemGroup insertDroppedObject: (id)movedObject atIndex: (int)index
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

- (void) itemGroup: (ETLayoutItemGroup *)itemGroup insertDroppedItem: (id)movedItem atIndex: (int)index
{
	NSAssert2(index >= 0, @"Insertion index %d must be superior or equal to zero in %@ -insertDroppedObject:atIndex:", index, self);
	int insertionIndex = index;
	int pickIndex = [itemGroup indexOfItem: movedItem];
	BOOL isLocalPick = ([movedItem parentLayoutItem] == self);
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

/*

- (void) mouseDown: (NSEvent *)e
{
	id handlerItem = [self itemPremptsEvent: e];
	id item = 		itemAtLocation:;
	
	if (handlerItem == nil)
		handlerItem = item;
	
	[handlerItem mouseDown: e on: item];
}

- (id) itemPreemptsEvent:

- (BOOL) doesPreemptEvent
{
	[[self layout] doesPreemptsEvent];
}
*/

#if 0
		
- (void) handleDropForItem: (id)item
{

}

- (void) handleDropForObject: (id)object
{
	if ([[self allowedDroppingTypes] containsObject: [object type]] == NO)
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
