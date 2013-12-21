/*
	Copyright (C) 2008 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  December 2008
	License:  Modified BSD (see COPYING)
 */

#import <EtoileFoundation/Macros.h>
#import "ETArrowTool.h"
#import "ETApplication.h"
#import "ETEvent.h"
#import "ETActionHandler.h"
#import "ETLayoutItem.h"
#import "ETLayoutItemGroup.h"
#import "ETLayout.h"
#import "ETPickDropActionHandler.h"
#import "ETPickDropCoordinator.h"
#import "ETSelectTool.h"
#import "ETCompatibility.h"

@implementation ETArrowTool

- (void) didBecomeInactive
{
	[super didBecomeInactive];
	DESTROY(_firstTouchedItem);
	_isTrackingTouch = NO;
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

The drag request can be handled with 
 -[ETActionHandler handleDragItem:forceItemPick:shouldRemoveItemsNow:coordinator:]. */
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
		ETTool *pickTool = [ETTool activeTool];
		[[item actionHandler] handleDragItem: item
							   forceItemPick: [[pickTool ifResponds] forcesItemPick]
		                shouldRemoveItemsNow: [[pickTool ifResponds] shouldRemoveItemsAtPickTime]
		                         coordinator: [ETPickDropCoordinator sharedInstanceWithEvent: anEvent]];
		[anEvent markAsDelivered];
	}
}

@end
