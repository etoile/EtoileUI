/*
	ETEvent.h
	
	EtoileUI-native event class that represents events to be dispatched and 
	handled in the layout item tree.
 
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

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

@class ETLayoutItem;

// WARNING: Very unstable API.

/** Shorcut to convert a backend event into a native EtoileUI event. */
#define ETEVENT(evt, drag, pick) [ETEvent eventWithBackendEvent: (void *)evt type: [evt type] pickingMask: pick draggingInfo: drag layoutItem: nil]

/** These constants allows to encode the pick and drop combinations that 
characterize drag/drop vs copy/cut/paste in EtoileUI. Read -setPickingMask: for 
the details. */
enum {
	ETNonePickingMask = 0,
	ETPickPickingMask = 2,
	ETCopyPickingMask = 4,
	ETCutPickingMask = 8,
	ETDragPickingMask = 16,
	ETDropPickingMask = 32,
	ETPastePickingMask = 64
// NOTE: May be we should have distinct picking and dropping mask.
};

/** EtoileUI uses ETEvent objects to represent events to be dispatched and 
handled in the layout item tree. These events usually represent device events 
(mouse, keyboard etc.). When they get dispatched, they can be refined into more 
specialized actions such as cut/copy/paste with the pickingMask property, as 
explained below.
 
With EtoileUI event handling model, layout items don't receive ETEvent objects, 
but those events are passed to the active instrument or tool which turns them 
into actions. Only actions rather than raw events are delivered to the targeted 
layout items. See ETInstrument and ETActionHandler. A layout item can also be 
attached to the event. For example, this can be used to easily keep track of 
the item initially targeted by the event. -[ETInstrument hitTestWithEvent:] does 
that: the layout item on which the dispatch is expected, is attached to the 
event.

Every EtoileUI events are created by processing the events emitted by the widget 
backend, and wrapping them into a native ETEvent instance. The wrapped event 
can be retrieved through -backendEvent. 

For now, only AppKit is supported as a backend, so -backendEvent will always 
return an NSEvent. Moreover the event types are the same than NSEventType enum, 
this is expected to change though. */
@interface ETEvent : NSObject
{
	NSEvent *_backendEvent; // TODO: Move that in a subclass specific to each backend
	ETLayoutItem *_layoutItem;
	id <NSDraggingInfo> _draggingInfo; // TODO: Should be backend-agnostic, may be move in a subclass...

	NSEventType _type; // TODO: Should be backend-agnostic, probably ETEventType with our own enum...
	unsigned int _pickingMask;
	BOOL _isUIEvent;
}

+ (ETEvent *) eventWithBackendEvent: (void *)evt 
                               type: (NSEventType)type
                        pickingMask: (unsigned int)pickMask 
                       draggingInfo: (id)drag
                         layoutItem: (ETLayoutItem *)item;         
+ (ETEvent *) enterEventWithEvent: (ETEvent *)anEvent;
+ (ETEvent *) exitEventWithEvent: (ETEvent *)anEvent;

- (BOOL) isUIEvent;
- (NSEventType) type;
- (id) layoutItem;
- (void) setLayoutItem: (id)anItem;
- (void) setPickingMask: (unsigned int)pickMask;
- (unsigned int) pickingMask;

- (id) draggingInfo;
- (NSPoint) draggingLocation;

- (void *) backendEvent;

- (NSPoint) locationInWindow;
- (int) windowNumber;

// FIXME: Remove by not relying on it in our code... it exposes a class that 
// is only valid for the AppKit backend.
- (NSWindow *) window;

@end
