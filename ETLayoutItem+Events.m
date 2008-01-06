/*  <title>ETLayoutItem+Events</title>

	ETLayoutItem+Events.m
	
	<abstract>Description forthcoming.</abstract>
 
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

#import <EtoileUI/ETLayoutItem+Events.h>
#import <EtoileUI/ETLayoutItemGroup.h>
#import <EtoileUI/ETPickboard.h>
#import <EtoileUI/ETCompatibility.h>


@implementation ETLayoutItem (Events)

- (BOOL) allowsDragging
{
	return [[self closestAncestorContainer] allowsDragging];
}

- (BOOL) allowsDropping
{
	return [[self closestAncestorContainer] allowsDropping];
}

- (void) mouseDown: (NSEvent *)event on: (id)item
{
	if ([self representedPathBase] != nil)
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

- (void) mouseDragged: (NSEvent *)event on: (id)item
{
	if ([self allowsDragging] == NO)
		return;

	if ([self representedPathBase] != nil)
	{
		ETLog(@"Allowed dragging on selection");
		[self handleDrag: event forItem: item];
	}
	else
	{
		[[self parentLayoutItem] mouseDragged: event on: item];
	}
}

// NOTE: ETOutlineLayout would override this method to call 
// -selectedItemsIncludingRelatedDescendants instead of -selectedItems	
//[pickboard pushObject: [ETPickCollection pickCollectionWithObjects: [self selectedItems]];
- (void) handleDrag: (NSEvent *)event forItem: (id)item
{
	id layout = nil;
	
	if ([self isGroup])
		layout = [(ETLayoutItemGroup *)self layout];
	
	if (layout != nil && [layout respondsToSelector: @selector(handleDrag:forItem:)])
	{
		[layout handleDrag: event forItem: item];
	}
	else
	{
		NSArray *selectedItems = [self selectedItems];
		// TODO: pickboard shouldn't be harcoded but rather customizable
		id pboard = [ETPickboard localPickboard];
		
		/* If the dragged item is part of a selection which includes more than
		   one item, we put a pick collection on pickboard */
		if ([selectedItems count] > 1 && [selectedItems containsObject: item])
		{
			[pboard pushObject: [ETPickCollection pickCollectionWithObjects: selectedItems]];
		}
		else
		{
			[pboard pushObject: item];
		}
		
		// TODO: Call back -handlePick:forItems:pickboard: which takes care of calling
		// pick and drop source methods when a source exists.
		
		/* We need to put something on the pasteboard otherwise AppKit won't 
		   allow the drag */
		pboard = [NSPasteboard pasteboardWithName: NSDragPboard];
		[pboard declareTypes: [NSArray arrayWithObject: ETLayoutItemPboardType] owner: nil];
		
		// TODO: Implements pasteboard compatibility to integrate with 
		// non-native Etoile code
		//NSData *data = [NSKeyedArchiver archivedDataWithRootObject: item];
		//[pboard setData: data forType: ETLayoutItemPboardType];
		
		[self beginDrag: event forItem: item image: nil];
	}
}

/* ETLayoutItem specific method to create a new drag and passing the request to data source */
- (void) beginDrag: (NSEvent *)event forItem: (id)item image: (NSImage *)customDragImage
{
	id layout = nil;
	
	if ([self isGroup])
		layout = [(ETLayoutItemGroup *)self layout];
	
	if (layout != nil && [layout respondsToSelector: @selector(beginDrag:forItem:image:)])
	{
		[layout beginDrag: event forItem: item image: customDragImage];
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
							event: event 
					   pasteboard: [NSPasteboard pasteboardWithName: NSDragPboard]
						   source: self
						slideBack: YES];
	}
}

- (NSDragOperation) handleDragMove: (id)dragInfo forItem: (id)item
{
	//ETLog(@"Drag move receives in dragging destination %@", self);
	
	if ([self allowsDropping] == NO)
		return NSDragOperationNone;
	
	return NSDragOperationPrivate;
}

- (NSDragOperation) handleDragEnter: (id)dragInfo forItem: (id)item
{
	ETLog(@"Drag enter receives in dragging destination %@", self);

	if ([self allowsDropping] == NO)
		return NSDragOperationNone;
	
	return NSDragOperationPrivate;
}

- (void) handleDragExit: (id)dragInfo forItem: (id)item
{

}

- (void) handleDragEnd: (id)dragInfo forItem: (id)item
{

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

- (int) dropIndexAtLocation: (NSPoint)localDropPosition forItem: (id)item on: (id)dropTargetItem
{
	id layout = [self isGroup] ? [(ETLayoutItemGroup *)self layout] : nil;
	
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
			dropTargetRect = [[self layout] displayRectOfItem: hoveredItem];
			if (localDropPosition.x > NSMidX(dropTargetRect))
				dropIndex++;
		}
		else
		{
			 /* When drop occurs on the receiver itself which is the item 
			    handling the drop. For example, this item could be a container 
				with a flow layout and the drop occured on a empty area where
				no child items are displayed. */
			dropIndex = [self numberOfItems] - 1;
		}
			
		return dropIndex;
	}
}

- (void) insertDroppedObject: (id) movedItem atIndex: (int)index
{
	NSAssert2(index >= 0, @"Insertion index %d must be superior or equal to zero in %@ -insertDroppedObject:atIndex:", index, self);
	int insertionIndex = index;
	int pickIndex = [self indexOfItem: movedItem];
	BOOL isLocalPick = ([movedItem parentLayoutItem] == self);
	BOOL itemAlreadyRemoved = NO; // NOTE: Feature to be implemented
	
	RETAIN(movedItem);

	//[self setAutolayout: NO];
	 /* Dropped item is visible where it was initially located.
		If the flag is YES, dropped item is currently invisible. */
	if (itemAlreadyRemoved == NO)
	{
		ETLog(@"For drop, removes item at index %d", pickIndex);
		/* We remove the item to handle the case where it is moved to another
		   index within the existing parent. */
		if (isLocalPick)
		{
			[self removeItem: movedItem];
			if (insertionIndex > pickIndex)
				insertionIndex--;
		}
	}
	//[self setAutolayout: YES];

	ETLog(@"For drop, insert item at index %d", insertionIndex);

	[self insertItem: movedItem atIndex: insertionIndex];
	//[self setSelectionIndex: insertionIndex];

	RELEASE(movedItem);
}

/** You can override this method to change how drop is handled. The parameter
	item represents the dragged item which just got dropped on the receiver. */
- (BOOL) handleDrop: (id)dragInfo forItem: (id)item on: (id)dropTargetItem;
{
	if ([self representedPathBase] != nil)
	{
		NSPoint loc = [[self container] convertPoint: [dragInfo draggingLocation] fromView: nil];
		int dropIndex = [self dropIndexAtLocation: loc forItem: item on: dropTargetItem];

		// FIXME: Handle pick collection too.
		if (dropIndex != NSNotFound)
		{
			[dropTargetItem insertDroppedObject: item atIndex: dropIndex];
			return YES;
		}
		else
		{
			NSAssert2([dropTargetItem isGroup], @"Drop target %@ must be a "
				@"layout item group to accept dropped item %@ as a child",
				dropTargetItem, item);
			[dropTargetItem insertDroppedObject: item atIndex: [dropTargetItem numberOfItems]];
			return NO;
		}
	}
	else
	{
		return [[self parentLayoutItem] handleDrop: dragInfo forItem: item on: dropTargetItem];
	}
}

- (BOOL) handlePick: (NSEvent *)event forItems: (NSArray *)items pickboard: (ETPickboard *)pboard
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
	if (isLocal)
	{
		return NSDragOperationPrivate; //Move
	}
	else
	{
		return NSDragOperationNone;
	}
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
@end
