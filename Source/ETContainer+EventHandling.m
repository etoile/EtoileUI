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

#import "ETContainer.h"
#import "ETEvent.h"
#import "ETLayoutItem.h"
#import "ETLayoutItemGroup.h"
#import "ETPickDropCoordinator.h"
#import "ETPickboard.h"
#import "ETCompatibility.h"

/* By default ETContainer implements data source methods related to drag and 
   drop. This is a convenience you can override by implementing drag and
   drop related methods in your own data source. DefaultDragDataSource is
   typically used when -allowsInternalDragging: returns YES. */
@implementation ETContainer (ETContainerDraggingSupport)

- (void) mouseUp: (NSEvent *)event
{
	ETDebugLog(@"WARNING: Event processor should have catch mouse up %@ in %@", event, self);
}

- (void) mouseDown: (NSEvent *)event
{
	ETDebugLog(@"WARNING: Event processor should have catch mouse down %@ in %@", event, self);
}

@end
