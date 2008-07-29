/*
	ETEvent.h
	
	NSEvent subclass providing additional support for pick and drop.
 
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

#define ETEVENT(evt, drag, pick) [ETEvent eventWithEvent: evt pickingMask: pick draggingInfo: drag]

// NOTE: May be we should have distinct picking and dropping mask.
enum {
	ETNonePickingMask = 0,
	ETPickPickingMask = 2,
	ETCopyPickingMask = 4,
	ETCutPickingMask = 8,
	ETDragPickingMask = 16,
	ETDropPickingMask = 32,
	ETPastePickingMask = 64
};

@interface ETEvent : NSEvent //<NSDraggingInfo>
{
	unsigned int _pickingMask;
	id <NSDraggingInfo> _draggingInfo;
	BOOL _isUIEvent;
}

+ (ETEvent *) eventWithEvent: (NSEvent *)event 
                 pickingMask: (unsigned int)pickMask 
				draggingInfo: (id)drag;

- (BOOL) isUIEvent;
- (void) setPickingMask: (unsigned int)pickMask;
- (unsigned int) pickingMask;

- (id) draggingInfo;
- (NSPoint) draggingLocation;

@end
