/*
	Copyright (C) 2008 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  December 2008
	License:  Modified BSD (see COPYING)
 */

#import <EtoileFoundation/Macros.h>
#import "ETMoveTool.h"
#import "ETApplication.h"
#import "ETEvent.h"
#import "ETEventProcessor.h"
#import "ETGeometry.h"
#import "ETActionHandler.h"
#import "ETLayoutItem.h"
#import "ETLayoutItemGroup.h"
#import "ETLayout.h"
#import "ETPickDropActionHandler.h"
#import "ETPickDropCoordinator.h"
#import "ETSelectTool.h" /* For Pick and Drop Integration */
#import "ETCompatibility.h"

@implementation ETMoveTool

- (id) initWithObjectGraphContext: (COObjectGraphContext *)aContext
{
	self = [super initWithObjectGraphContext: aContext];
	if (self == nil)
		return nil;

	[self setCursorName: kETToolCursorNameOpenHand];
	_shouldProduceTranslateActions = YES;
	return self;
}

- (void) didBecomeInactive
{
	[super didBecomeInactive];
	[self clearMoveState];
}

#pragma mark Interaction Settings -

/** Returns whether the receiver should produce translate actions rather than 
drag actions in reaction to a drag event.<br />
When the owner layout doesn't allow translate actions, returns NO and any value 
previously set with -setShouldProduceTranslateActions: is ignored.

For example, when the owner layout is computed, translate actions are not 
allowed.

By default, returns YES. */
- (BOOL) shouldProduceTranslateActions
{
	return (_shouldProduceTranslateActions && [[[self targetItem] layout] isComputedLayout] == NO);
}

/** Sets whether the receiver should produce translate actions rather than drag 
actions in reaction to a drag event.

See also -shouldProduceTranslateActions. */
- (void) setShouldProduceTranslateActions: (BOOL)translate
{

	_shouldProduceTranslateActions = translate;
}

#pragma mark Event Handlers -

/* Passes events only to the decorator items bound to the target item.

When the hit item is not the target item, we don't care whether it uses a widget 
view or not, but we do not want to have this widget view receives events, we 
just want to move the whole item. By passing a nil item to 
-trySendEvent:toWidgetViewOfItem:, the event won't be sent and will be able to 
handle it on our side.

However target item decorators have to receive events, otherwise a target item 
inside a scrollable area item would have scrollers that don't react to events 
when they are expected to. */
- (void) trySendEventToWidgetView: (ETEvent *)anEvent
{
	ETLayoutItem *hitItem = [self hitTestWithEvent: anEvent];
	ETLayoutItem *item = (hitItem == [self targetItem] ? hitItem : (ETLayoutItem *)nil);
	BOOL backendHandled = [[ETEventProcessor sharedInstance] trySendEvent: anEvent
													   toWidgetViewOfItem: item];

	if (backendHandled)
		[anEvent markAsDelivered];
}

/** Ends a translation underway. */
- (void) mouseUp: (ETEvent *)anEvent
{
	if ([self isTranslating])
	{
		[self endTranslate];
		[anEvent markAsDelivered];
	}
	else /* Try deliver the event to a target item decorator */
	{
		[self trySendEventToWidgetView: anEvent];
	}
}

/** Initiates a new translation or updates a translation underway. */
- (void) mouseDragged: (ETEvent *)anEvent
{
	ETLayoutItem *hitItem = [self hitTestWithEvent: anEvent];

	BOOL isBackgroundHit = [hitItem isEqual: [self targetItem]];
	BOOL startMove = ([self isMoving] == NO && isBackgroundHit == NO);

	if (startMove)
	{
		BOOL startTranslate = [self shouldProduceTranslateActions];

		if (startTranslate)
		{
			 // FIXME: Should be in screen coordinates...
			[self beginTranslateItem: hitItem atPoint: [anEvent locationInWindow]];
		}
		else /* Start drag */
		{
			[self beginDragItem: hitItem withEvent: anEvent];
		}
		[anEvent markAsDelivered];
	}
	else if ([self isTranslating])
	{
		[self translateToPoint: [anEvent locationInWindow]]; // FIXME: Should be in screen coordinates...
		[anEvent markAsDelivered];
	}
	else /* Try deliver the event to a target item decorator */
	{
		[self trySendEventToWidgetView: anEvent];
	}
}

#pragma mark Interaction Status -

/** Returns whether an item is currently translated or dragged by the receiver. */
- (BOOL) isMoving
{
	return ([self isTranslating] || [self isDragging]);
}

/** Returns the layout item currently translated or dragged.

Might return nil. */
- (id) movedItem
{
	return _draggedItem;
}

#pragma mark Translate Action Producer -

/** Begins a translation with an item item at a given point in the target item 
coordinate space. */
- (void) beginTranslateItem: (ETLayoutItem *)item atPoint: (NSPoint)aPoint
{
	ETAssert(_shouldProduceTranslateActions);
	_draggedItem = item;
	_dragStartLoc = aPoint;
	_lastDragLoc = _dragStartLoc;

	[[_draggedItem actionHandler] beginTranslateItem: _draggedItem];
}

/** Translates the item, on which the receiver is currently acting upon, to the 
given point in the target item coordinate space. */
- (void) translateToPoint: (NSPoint)eventLoc
{
	NSSize dragDelta = NSZeroSize;

	dragDelta.width = eventLoc.x - _lastDragLoc.x;
	dragDelta.height = eventLoc.y - _lastDragLoc.y;	
	if ([[_draggedItem parentItem] isFlipped])
	{
		dragDelta.height = -dragDelta.height;
	}
	_lastDragLoc = eventLoc;

	[self translateByDelta: dragDelta];
}

/** Broadcasts the translation to the item on which the receiver is currently 
acting upon.

This method can be overriden to alter the broadcast. */
- (void) translateByDelta: (NSSize)aDelta
{
	ETAssert(_shouldProduceTranslateActions);
	[[_draggedItem actionHandler] handleTranslateItem: _draggedItem 
                                              byDelta: aDelta];
	// TODO: Post translate notification
}

- (void) clearMoveState
{
	_draggedItem = nil;
	_dragStartLoc = NSZeroPoint;
	_lastDragLoc = NSZeroPoint;
}

/** Ends the translation. */
- (void) endTranslate
{
	[[_draggedItem actionHandler] endTranslateItem: _draggedItem];

	ETAssert(_shouldProduceTranslateActions);
	[self clearMoveState];
}

/** Returns whether an item is currently translated by the receiver. */
- (BOOL) isTranslating
{
	return (_draggedItem != nil && _shouldProduceTranslateActions);
}

#pragma mark Drag Action Producer -

- (void) beginDragItem: (ETLayoutItem *)item withEvent: (ETEvent *)anEvent
{
	ETTool *pickTool = [ETTool activeTool];
	[[item actionHandler] handleDragItem: item
	                       forceItemPick: [[pickTool ifResponds] forcesItemPick]
	                shouldRemoveItemsNow: [[pickTool ifResponds] shouldRemoveItemsAtPickTime]
	                         coordinator: [ETPickDropCoordinator sharedInstanceWithEvent: anEvent]];

	// FIXME: Would be better to use... but we need the coordinator calls back 
	// -endDrag then.
	//[[_draggedItem actionHandler] handleDragItem: _draggedItem
	//                                 coordinator: [ETPickDropCoordinator sharedInstance]];
}

- (void) endDrag
{

}

/** Returns whether an item is currently dragged by the receiver. */
- (BOOL) isDragging
{
	return (_draggedItem != nil && _shouldProduceTranslateActions == NO);
}

#pragma mark Targeted Action Handler -

/** Returns the action handler of the item currently dragged if a drag session 
is underway, otherwise returns nil.

This method can be overriden to customize the items to which the actions are 
sent. */
- (id) actionHandler
{
	return [_draggedItem actionHandler];
}

@end
