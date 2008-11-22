/*  ETContainer+EventHandling.m
	
	Bridge between GNUstep/Cocoa and EtoileUI event handling model.
 
	Copyright (C) 2007 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  July 2008
 
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

#import <EtoileFoundation/NSIndexSet+Etoile.h>
#import <EtoileUI/ETContainer.h>
#import <EtoileUI/ETLayoutItem.h>
#import <EtoileUI/ETLayoutItem+Events.h>
#import <EtoileUI/ETEvent.h>
#import <EtoileUI/ETLayoutItemGroup.h>
#import <EtoileUI/ETPickboard.h>
#import <EtoileUI/ETCompatibility.h>

#define SELECTION_BY_RANGE_KEY_MASK NSShiftKeyMask
#define SELECTION_BY_ONE_KEY_MASK NSCommandKeyMask

@interface ETContainer (ETEventHandling)
- (void) mouseDown: (NSEvent *)event;
- (void) mouseDoubleClick: (NSEvent *)event item: (ETLayoutItem *)item;

/* Dragging Support */
- (id) itemForEvent: (NSEvent *)event;
- (id) itemForLocationInWindow: (NSPoint)loc;
- (void) drawDragInsertionIndicator: (id <NSDraggingInfo>)drag;
- (void) updateDragInsertionIndicator;
@end

/* By default ETContainer implements data source methods related to drag and 
   drop. This is a convenience you can override by implementing drag and
   drop related methods in your own data source. DefaultDragDataSource is
   typically used when -allowsInternalDragging: returns YES. */
@implementation ETContainer (ETContainerDraggingSupport)

- (void) mouseUp: (NSEvent *)event
{
	ETDebugLog(@"Mouse up in %@", self);
	
	id item = [self itemForEvent: event];

	[item mouseUp: ETEVENT(event, nil, 0) on: item];
}

- (void) mouseDown: (NSEvent *)event
{
	ETDebugLog(@"Mouse down in %@", self);
	
	if ([self displayView] != nil) /* Layout object is wrapping an AppKit control */
	{
		NSLog(@"WARNING: %@ should have catch mouse down %@", [self displayView], event);
		return;
	}
	
	NSPoint localPosition = [self convertPoint: [event locationInWindow] fromView: nil];
	ETLayoutItem *newlyClickedItem = [[self layout] itemAtLocation: localPosition];
	int newIndex = NSNotFound;
	
	if (newlyClickedItem != nil)
		newIndex = [self indexOfItem: newlyClickedItem];
	
	/* Update selection if needed */
	ETDebugLog(@"Update selection on mouse down");
	
	if (newIndex == NSNotFound && [self allowsEmptySelection])
	{
			[self setSelectionIndex: newIndex];
	}
	else if (newIndex != NSNotFound && [[self selectionIndexes] containsIndex: newIndex] == NO)
	{
		NSMutableIndexSet *indexes = [self selectionIndexes];
		
		if (([event modifierFlags] & SELECTION_BY_ONE_KEY_MASK
		  || [event modifierFlags] & SELECTION_BY_RANGE_KEY_MASK)
		  && ([self allowsMultipleSelection]))
		{
			[indexes invertIndex: newIndex];
			[self setSelectionIndexes: indexes];
		}
		else /* Only single selection has to be handled */
		{
			[indexes addIndex: newIndex];
			[self setSelectionIndex: newIndex];
		}
	}
	
	/*NSMutableIndexSet *selection = [self selectionIndexes];
		
	[selection addIndex: [self indexOfItem: _doubleClickedItem]];
	[self setSelectionIndexes: selection];*/

	/* Handle possible double click */
	if ([event clickCount] > 1) 
		[self mouseDoubleClick: event item: newlyClickedItem];

	[newlyClickedItem handleMouseDown: ETEVENT(event, nil, 0) forItem: newlyClickedItem layout: [self layout]];
}

- (void) mouseDoubleClick: (NSEvent *)event item: (ETLayoutItem *)item
{
	ETDebugLog(@"Double click detected on item %@ in %@", item, self);
	
	ASSIGN(_doubleClickedItem, item);
	[[NSApplication sharedApplication] sendAction: [self doubleAction] to: [self target] from: self];
}

/* Drag Utility */

// FIXME: Handle layout orientation, only works with horizontal layout
// currently, in other words the insertion indicator is always vertical.
- (void) drawDragInsertionIndicator: (id <NSDraggingInfo>)drag
{
	NSPoint localDropPosition = [self convertPoint: [drag draggingLocation] fromView: nil];
	ETLayoutItem *hoveredItem = [[self layout] itemAtLocation: localDropPosition];
	NSRect hoveredRect = [[self layout] displayRectOfItem: hoveredItem];
	float itemMiddleWidth = hoveredRect.origin.x + hoveredRect.size.width / 2;
	float indicatorWidth = 4.0;
	float indicatorLineX = 0.0;
	NSRect indicatorRect = NSZeroRect;
	
	if ([self canDraw] == NO)
	{
		ETLog(@"WARNING: Impossible to draw drag insertion indicator in %@", self);
		return;
	}
	
	[self lockFocus];
	[[NSColor magentaColor] setStroke];
	[NSBezierPath setDefaultLineCapStyle: NSButtLineCapStyle];
	[NSBezierPath setDefaultLineWidth: indicatorWidth];
	
	/* Decides whether to draw on left or right border of hovered item */
	if (localDropPosition.x >= itemMiddleWidth)
	{
		indicatorLineX = NSMaxX(hoveredRect);
		//ETDebugLog(@"Draw right insertion bar");
	}
	else if (localDropPosition.x < itemMiddleWidth)
	{
		indicatorLineX = NSMinX(hoveredRect);
		//ETDebugLog(@"Draw left insertion bar");
	}
	else
	{
	
	}
	/* Computes indicator rect */
	indicatorRect = NSMakeRect(indicatorLineX - indicatorWidth / 2.0, 
		NSMinY(hoveredRect), indicatorWidth, NSHeight(hoveredRect));
		
	/* Insertion indicator has moved */
	if (NSEqualRects(indicatorRect, _prevInsertionIndicatorRect) == NO)
	{
		[self setNeedsDisplayInRect: NSIntegralRect(_prevInsertionIndicatorRect)];
		[self displayIfNeeded];
		// NOTE: Following code doesn't work...
		//[self displayIfNeededInRectIgnoringOpacity: _prevInsertionIndicatorRect];
	}
	
	/* Draws indicator */
	[NSBezierPath strokeLineFromPoint: NSMakePoint(indicatorLineX, NSMinY(hoveredRect))
							  toPoint: NSMakePoint(indicatorLineX, NSMaxY(hoveredRect))];
	[[self window] flushWindow];
	[self unlockFocus];
	
	_prevInsertionIndicatorRect = indicatorRect;
}

- (void) updateDragInsertionIndicator
{
	[self setNeedsDisplayInRect: NSIntegralRect(_prevInsertionIndicatorRect)];
	[self displayIfNeeded];
	// NOTE: Following code doesn't work...
	//[self displayIfNeededInRectIgnoringOpacity: _prevInsertionIndicatorRect];
}

- (id) itemForEvent: (NSEvent *)event
{
	return [self itemForLocationInWindow: [event locationInWindow]];
}

- (id) itemForLocationInWindow: (NSPoint)loc
{
	/* Convert drag location from window coordinates to the receiver coordinates */
	NSPoint localPoint = [self convertPoint: loc fromView: nil];
	
	// FIXME: Returned item can be nil when no layout exists (a null layout 
	// could be implemented) or when the item below the location is the receiver
	// container itself.
	return [[self layout] itemAtLocation: localPoint];
}

- (ETLayoutItem *) dropTargetForDrag: (id <NSDraggingInfo>)dragInfo
{
	id item = [self itemForLocationInWindow: [dragInfo draggingLocation]];
	
	/* When the drop target item doesn't accept the drop we retarget it. It 
	   commonly occurs in the following cases: 
	   -isGroup returns NO
	   -allowsDropping returns NO
	   location outside of the drop on rect. */
	if ([item acceptsDropAtLocationInWindow: [dragInfo draggingLocation]] == NO)
		item = [item parentLayoutItem];
	
	return item;
}

/* NSResponder Dragging Event */

// NOTE: this method isn't part of NSDraggingSource protocol but of NSResponder
- (void) mouseDragged: (NSEvent *)event
{
	ETDebugLog(@"Mouse dragged in %@", self);
	
	id item = [self itemForEvent: event];

	[item mouseDragged: ETEVENT(event, nil, ETDragPickingMask) on: item];
}

/* Dragging Destination 

   All dragging destination call backs are propagated to the drop target item 
   and not the hovered item. The drop target item is the dragging destination
   unlike the hovered item which is the top visible item right under the drag 
   location. The hovered item is different from the drop target item when the
   hovered item doesn't accept drop. */

/** This method can be called on the receiver when a drag exits. When a 
	view-based layout is used, existing the layout view results in entering
	the related container, that's probably a bug because the container should
	be fully covered by the layout view in all cases. */
- (NSDragOperation) draggingEntered: (id <NSDraggingInfo>)drag
{
	ETDebugLog(@"Drag enter receives in dragging destination %@", self);
	
	/* item can be nil, -itemAtLocation: doesn't return the receiver itself */
	id item = [self dropTargetForDrag: drag];
	id draggedItem = [[ETPickboard localPickboard] firstObject];

	return [item handleDragEnter: drag forItem: draggedItem];	
}

- (NSDragOperation) draggingUpdated: (id <NSDraggingInfo>)drag
{
	//ETDebugLog(@"Drag update receives in dragging destination %@", self);
	
	/* item can be nil, -itemAtLocation: doesn't return the receiver itself */
	id item = [self dropTargetForDrag: drag];
	id draggedItem = [[ETPickboard localPickboard] firstObject];
	NSDragOperation dragOp = NSDragOperationNone;
	
	dragOp = [item handleDragMove: drag forItem: draggedItem];	
	
	// NOTE: Testing non-nil displayView is equivalent to
	// [[self layout] layoutView] != nil
	if (dragOp != NSDragOperationNone && [self displayView] == nil)
		[self drawDragInsertionIndicator: drag];
		
	return dragOp;
}

- (void) draggingExited: (id <NSDraggingInfo>)drag
{
	ETDebugLog(@"Drag exit receives in dragging destination %@", self);
	
	/* item can be nil, -itemAtLocation: doesn't return the receiver itself */
	id item = [self dropTargetForDrag: drag];
	id draggedItem = [[ETPickboard localPickboard] firstObject];
		
	[item handleDragExit: drag forItem: draggedItem];
	
	/* Erases insertion indicator */
	[self updateDragInsertionIndicator];
}

- (void) draggingEnded: (id <NSDraggingInfo>)drag
{
	ETDebugLog(@"Drag end receives in dragging destination %@", self);
	
	/* item can be nil, -itemAtLocation: doesn't return the receiver itself */
	id item = [self dropTargetForDrag: drag];
	id draggedItem = [[ETPickboard localPickboard] firstObject];
	
	[item handleDragEnd: drag forItem: draggedItem on: nil];
	
	/* Erases insertion indicator */
	[self updateDragInsertionIndicator];
}

/* Will be called when -draggingEntered and -draggingUpdated have validated the drag
   This method is equivalent to -validateDropXXX data source method.  */
- (BOOL) prepareForDragOperation: (id <NSDraggingInfo>)drag
{
	ETDebugLog(@"Prepare drag receives in dragging destination %@", self);
	
	/* item can be nil, -itemAtLocation: doesn't return the receiver itself */
	id item = [self dropTargetForDrag: drag];
	id droppedItem = [[ETPickboard localPickboard] firstObject];
	
	// TODO: Drop target item can need to be retargeted when the container 
	// display item groups which doesn't have an associated container. If child
	// item group has an associated container, finding this item to pass it as
	// the drop target item is unecessary because this case never happens. The 
	// child container will catch the drop event and -prepareForDragOperation: 
	// will be called directly on it, letting no chance to handle it to the 
	// parent container.
	return [item handleDrop: drag forItem: droppedItem on: item];
}

/* Will be called when -draggingEntered and -draggingUpdated have validated the drag
   This method is equivalent to -acceptDropXXX data source method.  */
- (BOOL) performDragOperation: (id <NSDraggingInfo>)dragInfo
{
	ETDebugLog(@"Perform drag receives in dragging destination %@", self);
	
	id droppedItem = [[ETPickboard localPickboard] popObject];
	id item = [self dropTargetForDrag: dragInfo];

	return [item handleDrop: dragInfo forItem: droppedItem on: item];
}

/* This method is called in replacement of -draggingEnded: when a drop has 
   occured. That's why it's not enough to clean insertion indicator in
   -draggingEnded:. Both methods called -handleDragEnd:forItem: on the 
   drop target item. */
- (void) concludeDragOperation: (id <NSDraggingInfo>)drag
{
	ETDebugLog(@"Conclude drag receives in dragging destination %@", self);
	
	/* item can be nil, -itemAtLocation: doesn't return the receiver itself */
	id item = [self itemForLocationInWindow: [drag draggingLocation]];
	id droppedItem = [[ETPickboard localPickboard] firstObject];
		
	[item handleDragEnd: drag forItem: droppedItem on: item];
		
	/* Erases insertion indicator */
	[self updateDragInsertionIndicator];
}

@end
