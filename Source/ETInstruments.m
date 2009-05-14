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
#import "ETLayoutItem+Events.h"
#import "ETLayoutItem.h"
#import "ETLayoutItemGroup.h"
#import "ETLayout.h"
#import "ETPickDropCoordinator.h"
#import "ETCompatibility.h"
#import "ETStyleRenderer.h"
#import "NSView+Etoile.h"

#define SELECTION_BY_RANGE_KEY_MASK NSShiftKeyMask
#define SELECTION_BY_ONE_KEY_MASK NSCommandKeyMask

@implementation ETArrowTool

+ (NSString *) baseClassName
{
	return @"Tool";
}

/** Delivers click and double click to the item currently hovered by the 
pointer. */
- (void) mouseUp: (ETEvent *)anEvent
{
	[self trySendEventToWidgetView: anEvent];
	if ([anEvent wasDelivered])
		return;

	ETLayoutItem *item = [anEvent layoutItem];
	NSParameterAssert(item != nil);

	ETDebugLog(@"Mouse up with arrow tool on item %@", item);

	if ([anEvent clickCount] == 1)
	{
		[[item actionHandler] handleClickItem: item];
		[anEvent markAsDelivered];
	}
	else if ([anEvent clickCount] == 2)
	{
		[[item actionHandler] handleDoubleClickItem: item];
		[anEvent markAsDelivered];
	}
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
	[self trySendEventToWidgetView: anEvent];
	if ([anEvent wasDelivered])
		return;

	ETLayoutItem *item = [anEvent layoutItem];
	NSParameterAssert(item != nil);

	BOOL isBackgroundHit = [item isEqual: [self targetItem]];
	BOOL startDrag = ([self isPickDropForcedWithEvent: anEvent] && isBackgroundHit == NO);

	if (startDrag)
	{
		// TODO: Each pointer/instrument (in multi-pointer perspective) should 
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
	return self;
}

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
		BOOL startTranslate = ([[[self targetItem] layout] isComputedLayout] == NO);

		if (startTranslate)
		{
			 // FIXME: Should be in screen coordinates...
			[self beginTranslateItem: hitItem atPoint: [anEvent locationInWindow]];
		}
		else /* Start drag */
		{
			[self beginDragItem: hitItem withEvent: anEvent];
		}
	}
	else if ([self isTranslating])
	{
		[self translateToPoint: [anEvent locationInWindow]]; // FIXME: Should be in screen coordinates...
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
	_isTranslateMode = YES;
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
	[[_draggedItem actionHandler] handleTranslateItem: _draggedItem 
                                              byDelta: aDelta];
	// TODO: Post translate notification
}

/** Ends the translation. */
- (void) endTranslate
{
	_isTranslateMode = NO;
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


@implementation ETBucketTool

+ (NSString *) baseClassName
{
	return @"Tool";
}

/** Initializes and returns a new paint bucket tool which is set up with orange 
as stroke color and brown as fill color. */
- (id) init
{
	SUPERINIT
	[self setStrokeColor: [NSColor orangeColor]];
	[self setFillColor: [NSColor brownColor]];
	return self;
}

- (void) dealloc
{
    DESTROY(_fillColor);
    DESTROY(_strokeColor);
    [super dealloc];
}

/** Returns the fill color associated with the receiver. */
- (NSColor *) fillColor
{
    return AUTORELEASE([_fillColor copy]); 
}

/** Sets the fill color associated with the receiver. */
- (void) setFillColor: (NSColor *)color
{
	ASSIGN(_fillColor, [color copy]);
}

/** Returns the stroke color associated with the receiver. */
- (NSColor *) strokeColor
{
    return AUTORELEASE([_strokeColor copy]); 
}

/** Sets the stroke color associated with the receiver. */
- (void) setStrokeColor: (NSColor *)color
{
	ASSIGN(_strokeColor, [color copy]);
}

/** Returns the paint action produced by the receiver, either stroke or fill. */
- (ETPaintMode) paintMode
{
	return _paintMode;
}

/** Sets the paint action produced by the receiver, either stroke or fill. */
- (void) setPaintMode: (ETPaintMode)aMode
{
	_paintMode = aMode;
}

/* Outside of the boundaries doesn't count because the parent instrument will 
be reactivated when we exit our owner layout. */
- (void) mouseUp: (ETEvent *)anEvent
{	
	ETLayoutItem *item = [self hitTestWithEvent: anEvent];
	ETActionHandler *actionHandler = [item actionHandler];

	ETDebugLog(@"Mouse up with %@ on item %@", self, item);

	if ([self paintMode] == ETPaintModeFill && [actionHandler canFill: item])
	{
		[actionHandler handleFill: item withColor: [self fillColor]];
	}
	else if ([self paintMode] == ETPaintModeStroke && [actionHandler canStroke: item])
	{
		[actionHandler handleStroke: item withColor: [self strokeColor]];
	}
}

- (NSMenu *) menuRepresentation
{
	NSMenu *menu = AUTORELEASE([[NSMenu alloc] initWithTitle: _(@"Bucket Tool Options")]);
	NSMenu *modeSubmenu = AUTORELEASE([[NSMenu alloc] initWithTitle: _(@"Bucket Tool Paint Mode")]);

	[menu addItemWithSubmenu: modeSubmenu];

	[modeSubmenu addItemWithTitle: _(@"Fill")
	                target: self
	                action: @selector(changePaintMode:)
	         keyEquivalent: @""];

	[modeSubmenu addItemWithTitle: _(@"Stroke")
	                target: self
	                action: @selector(changePaintMode:)
	         keyEquivalent: @""];

	[menu addItemWithTitle:  _(@"Choose Colors…")
	                target: self
	                action: @selector(chooseColors:)
	         keyEquivalent: @""];

	return menu;
}

- (void) changePaintMode: (id)sender
{
	 // TODO: Implement
}

- (void) changeColor: (id)sender
{
	NSColor *newColor = nil; // TODO: Finish to implement

	if ([self paintMode] == ETPaintModeFill)
	{
		[self setFillColor: newColor];
	}
	else if ([self paintMode] == ETPaintModeStroke)
	{
		[self setStrokeColor: newColor];
	}
}

@end
