/*  <title>ETEvent</title>

	ETEvent.m
	
	<abstract>EtoileUI-native event class that represents events to be 
	dispatched and handled in the layout item tree.</abstract>
 
	Copyright (C) 2007 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  January 2007
 
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

#import <EtoileFoundation/Macros.h>
#import "ETEvent.h"
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
anEvent, event type put aside. */
+ (ETEvent *) exitEventWithEvent: (ETEvent *)anEvent
{
	ETEvent *copiedEvent = [anEvent copy];
	copiedEvent->_type = NSMouseExited;
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

/** Returns the layout item attached to the EtoileUI event. 
 
See -setLayoutItem:. */
- (id) layoutItem
{
	return _layoutItem;
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

/** Returns the widget backend event that was used to construct to the receiver. 

You should avoid to use this method to simplify the portability of your code to 
other widget backends that might be written in future. */
- (void *) backendEvent
{
	return (void *)_backendEvent;
}

/** Returns the location of the pointer in the coordinate space of the window 
content.
 
For the AppKit backend, the window content is the content view. */
- (NSPoint) locationInWindow
{
	return [(NSEvent *)_backendEvent locationInWindow];
}

/** Returns a window identifier that encodes the window on which the event 
occured. The returned value is backend-specific. */
- (int) windowNumber
{
	return [(NSEvent *)_backendEvent windowNumber];
}

- (NSWindow *) window
{
	return [(NSEvent *)_backendEvent window];
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
