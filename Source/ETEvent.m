/*
	Copyright (C) 2007 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  January 2007
	License:  Modified BSD (see COPYING)
 */

#ifndef GNUSTEP
#import <Carbon/Carbon.h>
#endif
#import <EtoileFoundation/Macros.h>
#import "ETEvent.h"
#import "ETApplication.h"
#import "ETGeometry.h"
#import "ETDecoratorItem.h"
#import "ETLayoutItem+Factory.h"
#import "ETView.h"
#import "ETWindowItem.h"
#import "NSWindow+Etoile.h"
#import "ETCompatibility.h"

static const int ETUntypedEvent = 0;

@implementation ETEvent

/** Returns an autoreleased EtoileUI native event that wraps and corresponds to 
the widget backend event passed as evt. */
+ (ETEvent *) eventWithBackendEvent: (void *)evt
                               type: (NSEventType)type
                        pickingMask: (unsigned int)pickMask 
                       draggingInfo: (id)drag
                         layoutItem: (ETLayoutItem *)item     
{
	ETEvent *event = AUTORELEASE([[self alloc] init]);

	ASSIGN(event->_backendEvent, (NSEvent *)evt);
	[event setLayoutItem: item];
	ASSIGN(event->_draggingInfo, drag);

	[event setPickingMask: pickMask];
	event->_isUIEvent = YES;

	return event;
}

/** Returns an autoreleased EtoileUI mouse enter event which is identical to 
anEvent, event type put aside. */
+ (ETEvent *) enterEventWithEvent: (ETEvent *)anEvent
{
	ETEvent *copiedEvent = [anEvent copy];
	copiedEvent->_type = NSMouseEntered;
	return AUTORELEASE(copiedEvent);
}

/** Returns an autoreleased EtoileUI mouse exit event which is identical to 
anEvent, event type and layout item put aside. */
+ (ETEvent *) exitEventWithEvent: (ETEvent *)anEvent
					  layoutItem: (ETLayoutItem *)exitedItem;
{
	ETEvent *copiedEvent = [anEvent copy];
	copiedEvent->_type = NSMouseExited;
	[copiedEvent setLayoutItem: exitedItem];
	return AUTORELEASE(copiedEvent);
}

DEALLOC(DESTROY(_draggingInfo); DESTROY(_layoutItem); DESTROY(_backendEvent))

- (id) copyWithZone: (NSZone *)zone
{
	ETEvent *copiedEvent = [[[self class] alloc] init];

	ASSIGN(copiedEvent->_backendEvent, _backendEvent);
	[copiedEvent setLayoutItem: [self layoutItem]];
	ASSIGN(copiedEvent->_draggingInfo, _draggingInfo);

	copiedEvent->_type = _type;
	[copiedEvent setPickingMask: [self pickingMask]];
	copiedEvent->_isUIEvent = _isUIEvent;
	
	return copiedEvent;
}

- (NSString *) description
{
	// TODO: Improve
	return [(NSEvent *)[self backendEvent] description];
}

/** Returns the type of the EtoileUI event. If a custom type was not used to 
instantiate the event object, then the type matches the one of the backend event. */
- (NSEventType) type
{
	if (_type == ETUntypedEvent)
		return [(NSEvent *)_backendEvent type];

	return _type;
}

/** Returns YES when the event originates from user interaction at UI level, 
otherwise returns NO when the event is created directly in code to be used like 
a notification object.
 
FIXME: Implement... should be set when the event is created with a widget 
backend event as parameter. */
- (BOOL) isUIEvent
{
	return _isUIEvent;
}

/* Event Dispatch Status */

/** Returns whether the event has been handled or not yet. */
- (BOOL) wasDelivered
{
	return _wasDelivered;
}

/** Marks the event as now handled. */
- (void) markAsDelivered
{
	_wasDelivered = YES;
}

/** Returns the layout item attached to the EtoileUI event. 
 
See -setLayoutItem:. */
- (id) layoutItem
{
	return _layoutItem;
}

/** Returns the event location in the layout item coordinate space, this point 
usually corresponds to the hit test that was done by ETInstrument and 
memorized in the receiver with -setLocationInLayoutItem:.
If -layoutItem returns nil or doesn't match the hit test of the event, a null 
point will be returned.
 
See -setLayoutItem:. */
- (NSPoint) locationInLayoutItem
{
	return _locationInLayoutItem;
}

/** Sets the event location in the layout item coordinate space, this point 
usually corresponds to the hit test that was done by ETInstrument and 
memorized in the receiver by calling this method.
If -layoutItem returns nil or doesn't match the hit test of the event, a null 
point will be returned.
 
See -setLayoutItem:. */
- (void) setLocationInLayoutItem: (NSPoint)aPoint
{
	_locationInLayoutItem = aPoint;
}

/** Sets the layout item attached to the EtoileUI event.
 
The purpose of the attached item is up to the caller. If the caller API is 
public, the purpose must be documented in this API. This would be the case with 
an ETInstrument subclass that is available in a framework. 
TODO: Rewrite later if we finally make use of it in a different way. */
- (void) setLayoutItem: (id)anItem
{
	ASSIGN(_layoutItem, anItem);
}

/** Sets the pick an drop mask attached to the EtoileUI event. This mask encodes 
the pick and drop combinations that characterize drag/drop vs copy/cut/paste. */
- (void) setPickingMask: (unsigned int)pickMask
{
	_pickingMask = pickMask;
}

/** Returns the pick an drop mask attached to the EtoileUI event. 

See -setPickingMask:. */
- (unsigned int) pickingMask
{
	return _pickingMask;
}

/* Input Device Data */

/** Returns the click count when the EtoileUI event type matches a click-like 
input, otherwise raises an exception. */
- (int) clickCount
{
	return [(NSEvent *)_backendEvent clickCount];
}

/** Returns the pressed key characters when the EtoileUI event type matches 
a keyboard-like input. */
- (NSString *) characters
{
	return [(NSEvent *)_backendEvent characters];
}

/** Returns the key modifier combinations pressed when the event was produced. 

The key combo is encoded as a bit field. */
- (unsigned int) modifierFlags
{
	return [(NSEvent *)_backendEvent modifierFlags];
}

/** Returns the item bound to the window content view. When the view has no 
ETUIItem bound to it, returns nil.

e.g. with a scroll view as content view, the content item is expected to be a 
scrollable area item, not the ETLayoutItem object it decorates and which exists
in the layout item tree as a window layer child. The scrollable area item has 
no parent per se. You can retrieve the layout item with 
[contentItem firstDecoratedItem]. */
- (ETUIItem *) contentItem
{
	id contentView = [self contentView];
	
	if (contentView == nil || [contentView isKindOfClass: [ETView class]] == NO)
		return nil;
	
	return (ETUIItem *)[contentView layoutItem];
}

/** Returns the item that represents the window per se. When the window 
content view has no ETUIItem bound to it, returns nil. */
- (ETWindowItem *) windowItem
{
	ETUIItem *contentItem = [self contentItem];
	ETWindowItem *windowItem = [contentItem lastDecoratorItem];

	if (windowItem != nil)
	{
		NSParameterAssert([windowItem isKindOfClass: [ETWindowItem class]]);
		/* The backend window can be an open/save panel without an EtoileUI 
		   representation, that's why we do the next checks only when 
		   windowItem is not nil. */ 
		NSParameterAssert([(NSEvent *)_backendEvent window] == [windowItem window]);
		NSParameterAssert([windowItem isFlipped] == [contentItem isFlipped]);
	}
	else
	{
		NSParameterAssert(contentItem == nil);
	}

	return windowItem;
}

/** Returns the location of the pointer in the window item coordinate space (the 
window frame).

When [[self windowItem] isFlipped] returns YES as it is usually the case, the 
returned point will be expressed in flipped coordinates.<br />
Decorator items keep -isFlipped in sync with the item they decorate and 
layout items are instantiated with -isFlipped equals to YES. Hence 
-[ETWindowItem isFlipped] usually returns YES.

When the event has no associated window, returns a null point. */
- (NSPoint) locationInWindowItem
{
	ETDecoratorItem *windowItem = [self windowItem];

	if (windowItem == nil)
		return ETNullPoint;

	NSPoint windowItemLoc = [(NSEvent *)_backendEvent locationInWindow];
	if ([windowItem isFlipped])
	{
		windowItemLoc.y = [windowItem decorationRect].size.height - windowItemLoc.y;
	}	
	NSRect windowBounds = ETMakeRect(NSZeroPoint, [windowItem decorationRect].size);
	BOOL outsideWindow = (NSMouseInRect(windowItemLoc, windowBounds, [windowItem isFlipped]) == NO);
	
	if (outsideWindow)
		return ETNullPoint;

	return windowItemLoc;
}

/** Returns the location of the pointer in the window content item coordinate 
space (the window content rect).

When the event has no associated window, returns a null point.

See -contentItem. */
- (NSPoint) locationInWindowContentItem
{
	ETWindowItem *windowItem = [self windowItem];
	BOOL hasNoWindow = (windowItem == nil);

	if (hasNoWindow)
		return ETNullPoint;

	return [windowItem convertDecoratorPointToContent: [self locationInWindowItem]];
}

/** Returns the location of the pointer in the coordinate space of the window 
layer.

This coordinate space is equivalent the screen coordinate space, minus the menu 
bar and that it uses flipped coordinates unless specifed otherwise on ETWindowLayer. */
- (NSPoint) location
{
	NSWindow *window = [(NSEvent *)_backendEvent window];
	NSPoint windowLayerLoc = ETNullPoint;

	if (window == nil)
	{
		windowLayerLoc = [(NSEvent *)_backendEvent locationInWindow];
	}
	else
	{
		windowLayerLoc = [window convertBaseToScreen: [(NSEvent *)_backendEvent locationInWindow]];
	}

	/* -locationInWindow is in bottom left coordinates even when the content 
	   view is flipped, that's why we only need to alter the point when the 
	   window layer uses flipped coordinates. */
	if ([[ETLayoutItem windowGroup] isFlipped])
	{
		// TODO: Extract screen size logic into ETWindowLayer. See also -[ETWindowItem decorationRect].
		BOOL isFullScreenFrame = NSEqualRects([[NSScreen mainScreen] visibleFrame], [[NSScreen mainScreen] frame]);
		float menuBarHeight = (isFullScreenFrame ? 0 : [[ETApp mainMenu] menuBarHeight]);
		windowLayerLoc.y = [[NSScreen mainScreen] frame].size.height - windowLayerLoc.y - menuBarHeight;
	}

	return windowLayerLoc;
}

/* Widget Backend Integration */

/** Returns whether the event is located within the window title bar or border. 
This includes the resize indicator which overlaps the content view on Mac OS X. */
- (BOOL) isWindowDecorationEvent
{
	NSWindow *window = [(NSEvent *)_backendEvent window];

	if (window == nil)
		return NO;

	NSPoint contentRelativeLoc = [self locationInWindowContentItem];
	BOOL outsideWindow = (NSPointInRect(contentRelativeLoc, [window frameRectInContent]) == NO);

	if (outsideWindow)
		return NO;
	
	NSView *contentView = [window contentView];
	BOOL outsideContentView = ([contentView mouse: contentRelativeLoc
	                                       inRect: [contentView bounds]] == NO);

#ifdef GNUSTEP
	return outsideContentView;
#else
	/* We use content view frame and not bounds, because the resize indicator is 
	   not a subview. The resize indicator is drawn by NSThemeFrame itself. */
	NSRect resizeIndicatorRect = NSMakeRect([contentView width] - 16, 0, 16, 16);
	if ([contentView isFlipped])
	{
		resizeIndicatorRect.origin.y = [contentView height] - 16;
	}
	BOOL insideResizeIndicator = [contentView mouse: contentRelativeLoc 
	                                         inRect: resizeIndicatorRect];

	return (outsideContentView || insideResizeIndicator);
#endif
}

/** Returns the widget backend event that was used to construct to the receiver. 

You should avoid to use this method to simplify the portability of your code to 
other widget backends that might be written in future. */
- (void *) backendEvent
{
	return (void *)_backendEvent;
}

/** Returns a window identifier that encodes the window on which the event 
occured. The returned value is backend-specific. */
- (int) windowNumber
{
	return [(NSEvent *)_backendEvent windowNumber];
}

/** Returns the window content view bound to the content item. */
- (id) contentView
{
	return [[(NSEvent *)_backendEvent window] contentView];
}

/* Deprecated */

/** Returns the location of the pointer expressed in non-flipped coordinates 
relative to the window content.
 
For the AppKit backend, the window content is the content view. */
- (NSPoint) locationInWindow
{
	return [(NSEvent *)_backendEvent locationInWindow];
}

- (NSWindow *) window
{
	return [(NSEvent *)_backendEvent window];
}

/** Returns the object that contains all the drag or drop infos, if the current 
event has triggered a drag or drop action. */
- (id) draggingInfo
{
	return _draggingInfo;
}

// TODO: May be we don't really need it...
- (NSPoint) draggingLocation
{
	return [_draggingInfo draggingLocation];
}

// FIXME: Far from ideal... Once we know better what the ETEvent API should be
// to support other backends and other EtoileUI needs, we should remove this hack.
- (void) forwardInvocation: (NSInvocation *)inv
{
    SEL aSelector = [inv selector];;

    if ([(id)_draggingInfo respondsToSelector: aSelector])
	{
        [inv invokeWithTarget: _draggingInfo];
	}
	else if ([(NSEvent *)_backendEvent respondsToSelector: aSelector])
	{
        [inv invokeWithTarget: (NSEvent *)_backendEvent];
	}
	else
	{
        [self doesNotRecognizeSelector: aSelector];
	}
}

@end
