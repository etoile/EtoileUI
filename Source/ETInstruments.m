/*
	Copyright (C) 2008 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  December 2008
	License:  Modified BSD (see COPYING)
 */

#import <EtoileFoundation/Macros.h>
#import "ETInstruments.h"
#import "ETApplication.h"
#import "ETEvent.h"
#import "ETEventProcessor.h"
#import "ETFreeLayout.h"
#import "ETGeometry.h"
#import "ETHandle.h"
#import "ETActionHandler.h"
#import "ETLayoutItem.h"
#import "ETLayoutItemGroup.h"
#import "ETLayout.h"
#import "ETPickDropActionHandler.h"
#import "ETPickDropCoordinator.h"
#import "ETCompatibility.h"

#define SELECTION_BY_RANGE_KEY_MASK NSShiftKeyMask
#define SELECTION_BY_ONE_KEY_MASK NSCommandKeyMask

@implementation ETArrowTool

+ (NSString *) baseClassName
{
	return @"Tool";
}

- (void) mouseDown: (ETEvent *)anEvent
{
	[self tryActivateItem: nil withEvent: anEvent];
	[self trySendEventToWidgetView: anEvent];
	if ([anEvent wasDelivered])
	{
		return;
	}
	/* The field editor has not received the event with -trySendEventToWidgetView:, 
	   the event is not directed towards it. */
	[self tryRemoveFieldEditorItemWithEvent: anEvent];

	ETLayoutItem *item = [anEvent layoutItem];
	NSParameterAssert(item != nil);
	NSParameterAssert(_isTrackingTouch == NO);
	NSParameterAssert(_firstTouchedItem == nil);
	
	_isTrackingTouch = [[item actionHandler] handleBeginTouch: anEvent 
	                                                  atPoint: [anEvent locationInLayoutItem]
	                                                   onItem: item];
	if (_isTrackingTouch)
	{
		ASSIGN(_firstTouchedItem, item);
	}
	[anEvent markAsDelivered];
}

/** Delivers click and double click to the item currently hovered by the 
pointer. */
- (void) mouseUp: (ETEvent *)anEvent
{
	/* Don't try to activate an item or remove the field editor. We does that
	   in -mouseDown: time which precedes -mouseUp:. */
	[self trySendEventToWidgetView: anEvent];
	if ([anEvent wasDelivered])
		return;

	ETLayoutItem *item = [anEvent layoutItem];
	NSParameterAssert(item != nil);

	ETDebugLog(@"Mouse up with arrow tool on item %@", item);

	if (_isTrackingTouch)
	{
		[[_firstTouchedItem actionHandler] handleEndTouch: anEvent onItem: _firstTouchedItem];
		[anEvent markAsDelivered];
	}
	else if ([anEvent clickCount] == 1)
	{
		[[item actionHandler] handleClickItem: item atPoint: [anEvent locationInLayoutItem]];
		[anEvent markAsDelivered];
	}
	else if ([anEvent clickCount] == 2)
	{
		[[item actionHandler] handleDoubleClickItem: item];
		[anEvent markAsDelivered];
	}

	_isTrackingTouch = NO;
	DESTROY(_firstTouchedItem);
}

- (BOOL) isPickDropForcedWithEvent: (ETEvent *)anEvent
{
	return ([anEvent type] == NSLeftMouseDragged && 
		([anEvent modifierFlags] & [ETPickDropCoordinator forceEnablePickAndDropModifier]));
}

/** Delivers a drag request to the item currently hovered by the pointer.

The drag request can be handled with -[ETActionHandler handleDragItem:coordinator:]. */
- (void) mouseDragged: (ETEvent *)anEvent
{
	/* Don't try to activate an item or remove the field editor. We does that
	   in -mouseDown: time which precedes -mouseDragged:. */
	[self trySendEventToWidgetView: anEvent];
	if ([anEvent wasDelivered])
		return;

	ETLayoutItem *item = [anEvent layoutItem];
	NSParameterAssert(item != nil);

	BOOL isBackgroundHit = [item isEqual: [self targetItem]];
	BOOL startDrag = ([self isPickDropForcedWithEvent: anEvent] && isBackgroundHit == NO);

	if (_isTrackingTouch)
	{
		[[_firstTouchedItem actionHandler] handleContinueTouch: anEvent 
		                                               atPoint: [anEvent locationInLayoutItem]
		                                                onItem: _firstTouchedItem];
		[anEvent markAsDelivered];
	}
	else if (startDrag)
	{
		// TODO: Each pointer/tool (in multi-pointer perspective) should 
		// instantiate a new distinct coordinator.
		[[item actionHandler] handleDragItem: item 
			coordinator: [ETPickDropCoordinator sharedInstanceWithEvent: anEvent]];
		[anEvent markAsDelivered];
	}
}

@end


@implementation ETMoveTool

DEALLOC(DESTROY(_draggedItem))

+ (NSString *) baseClassName
{
	return @"Tool";
}

- (id) init
{
	SUPERINIT
	[self setCursor: [NSCursor openHandCursor]];
	_isTranslateMode = YES;
	return self;
}

- (id) copyWithZone: (NSZone *)aZone
{
	ETMoveTool *newTool = [super copyWithZone: aZone];
	newTool->_isTranslateMode = _isTranslateMode;
	return newTool;
}

/** Returns whether the receiver should produce translate actions rather than 
drag actions in reaction to a drag event.<br />
When the owner layout doesn't allow translate actions, returns NO and any value 
previously set with -setShouldProduceTranslateActions: is ignored.

For example, when the owner layout is computed, translate actions are not 
allowed.

By default, returns YES. */
- (BOOL) shouldProduceTranslateActions
{
	return (_isTranslateMode && [[[self targetItem] layout] isComputedLayout] == NO);
}

/** Sets whether the receiver should produce translate actions rather than drag 
actions in reaction to a drag event.

See also -shouldProduceTranslateActions. */
- (void) setShouldProduceTranslateActions: (BOOL)translate
{
	_isTranslateMode = translate;
}

// NOTE: We don't need to override -copyWithZone:

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

/** Returns whether an item is currently translated or dragged by the receiver. */
- (BOOL) isMoving
{
	return ([self isTranslating] || [self isDragging]);
}

/** Begins a translation with an item item at a given point in the target item 
coordinate space. */
- (void) beginTranslateItem: (ETLayoutItem *)item atPoint: (NSPoint)aPoint
{
	ETAssert(_isTranslateMode);
	ASSIGN(_draggedItem, item);
	_dragStartLoc = aPoint;
	_lastDragLoc = _dragStartLoc;
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
	ETAssert(_isTranslateMode);
	[[_draggedItem actionHandler] handleTranslateItem: _draggedItem 
                                              byDelta: aDelta];
	// TODO: Post translate notification
}

/** Ends the translation. */
- (void) endTranslate
{
	ETAssert(_isTranslateMode);
	DESTROY(_draggedItem);
	_dragStartLoc = NSZeroPoint;
	_lastDragLoc = NSZeroPoint;
}

/** Returns whether an item is currently translated by the receiver. */
- (BOOL) isTranslating
{
	return (_draggedItem != nil && _isTranslateMode);
}

/* Drag Action Producer */

- (void) beginDragItem: (ETLayoutItem *)item withEvent: (ETEvent *)anEvent
{
	[[item actionHandler] handleDragItem: item
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
	return (_draggedItem != nil && _isTranslateMode == NO);
}

/** Returns the action handler of the item currently dragged if a drag session 
is underway, otherwise returns nil.

This method can be overriden to customize the items to which the actions are 
sent. */
- (id) actionHandler
{
	return [_draggedItem actionHandler];
}

@end
