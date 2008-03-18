/*  <title>ETEvent</title>

	ETEvent.m
	
	<abstract>NSEvent subclass providing additional support for pick and 
	drop.</abstract>
 
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

#import <EtoileUI/ETEvent.h>
#import <EtoileUI/ETCompatibility.h>

@interface ETEvent (Private)
#ifdef GNUSTEP
+ (ETEvent *) _eventWithGSEvent: (NSEvent *)evt;
#endif
@end


@implementation ETEvent

#ifdef GNUSTEP
+ (ETEvent *) _eventWithGSEvent: (NSEvent *)evt
{	
	id event = nil;

	if (NSEventMaskFromType([evt type]) & GSMouseEventMask)
	{
		event = [ETEvent mouseEventWithType: [evt type] 
									  location: [evt locationInWindow]
								 modifierFlags: [evt modifierFlags] 
								     timestamp: [evt timestamp] 
								  windowNumber: [evt windowNumber] 
								       context: [evt context] 
								   eventNumber: [evt eventNumber] 
								    clickCount: [evt clickCount] 
									  pressure: [evt pressure]];
	}
	else if (NSEventMaskFromType([evt type]) & GSKeyEventMask)
	{
		event = [ETEvent keyEventWithType: [evt type] 
									  location: [evt locationInWindow]
								 modifierFlags: [evt modifierFlags] 
								     timestamp: [evt timestamp] 
								  windowNumber: [evt windowNumber] 
								       context: [evt context] 
									characters: [evt characters]
				   charactersIgnoringModifiers: [evt charactersIgnoringModifiers]
				                     isARepeat: [evt isARepeat]
									   keyCode: [evt keyCode]];
	}
	else if (NSEventMaskFromType([evt type]) & GSOtherEventMask)
	{
		event = [ETEvent otherEventWithType: [evt type] 
									  location: [evt locationInWindow]
								 modifierFlags: [evt modifierFlags] 
								     timestamp: [evt timestamp] 
								  windowNumber: [evt windowNumber] 
								       context: [evt context] 
								   subtype: [evt subtype] 
								    data1: [evt data1] 
									  data2: [evt data2]];	
	}
	else
	{
		ETLog(@"WARNING: Cannot turn %@ into an ETEvent instance", evt);
	}
	
	return event;
}
#endif

+ (ETEvent *) eventWithEvent: (NSEvent *)evt 
                 pickingMask: (unsigned int)pickMask 
				draggingInfo: (id)drag
{
#ifdef GNUSTEP
	ETEvent *event = (ETEvent *)[ETEvent _eventWithGSEvent: evt];
#else
	ETEvent *event = (ETEvent *)[ETEvent eventWithEventRef: [evt eventRef]];
#endif

	ASSIGN(event->_draggingInfo, drag);
	[event setPickingMask: pickMask];
	event->_isUIEvent = YES;
	
	return event;
}

- (void) dealloc
{
	DESTROY(_draggingInfo);

	[super dealloc];
}

/** Returns YES when the event originates from user interaction at UI level, 
	otherwise returns NO when the event is created directly in code to be used
	like a notification object. */
- (BOOL) isUIEvent
{
	return _isUIEvent;
}

- (void) setPickingMask: (unsigned int)pickMask
{
	_pickingMask = pickMask;
}

- (unsigned int) pickingMask
{
	return _pickingMask;
}

- (id) draggingInfo
{
	return _draggingInfo;
}

- (NSPoint) draggingLocation
{
	return [[self draggingInfo] draggingLocation];
}

- (void) forwardInvocation: (NSInvocation *)inv
{
    SEL aSelector = [inv selector];
	id drag = [self draggingInfo];
 
    if ([drag respondsToSelector: aSelector])
	{
        [inv invokeWithTarget: drag];
	}
    else
	{
        [self doesNotRecognizeSelector: aSelector];
	}
}

@end
