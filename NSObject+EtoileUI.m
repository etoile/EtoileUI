/*
	NSObject+EtoileUI.m
	
	Description forthcoming.
 
	Copyright (C) 2007 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  September 2007
 
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

#import <EtoileUI/NSObject+EtoileUI.h>
#import <EtoileUI/ETObjectBrowserLayout.h>
#import <EtoileUI/ETCompatibility.h>


@implementation NSObject (EtoileUI)

/** Shows the receiver content in the object browser panel and allows to 
	navigate the whole Étoilé environment object graph (including outside the
	application the browsed object is part of). */
- (IBAction) browse: (id)sender
{
	ETObjectBrowser *browser = [[ETObjectBrowser alloc] init];

	ETLog(@"browse %@", self);
	[browser setBrowsedObject: self];
	[[browser panel] makeKeyAndOrderFront: self];
}

/** Shows the layout item representing the receiver by enforcing referential
	stability (more commonly named spatiality in the case of UI objects).
	If the receiver is a layout item, this layout item is simply brought to 
	front and made the first responder. 
	When the receiver is some other kind of objects, the object registry is 
	looked up to know whether there is a layout item bound to the receiver.
	If the lookup succeeds, the matching layout item is requested to display
	itself by sending -view: to it.
	If no visual representation exists, a new layout item is created and 
	bound to the receiver with the object registry. Then this layout item is
	made visible and active as described in the previous paragraph. */
- (IBAction) view: (id)sender
{
	// FIXME: Implement
}

/** Shows an inspector which provides informations about the receiver. The 
	inspector makes possible to edit the object state and behavior. For some
	objects, the built-in inspector could have been overriden by a third-party 
	inspector. By inspecting a third-party inspector, you can easily revert it
	or bring back the basic inspector. */
- (IBAction) inspect: (id)sender
{
	// FIXME: Implement
}

@end

@implementation NSResponder (EtoileUI)

- (IBAction) browse: (id)sender
{
	[super browse: sender];
	//[[self nextResponder] browse: sender];
}

- (IBAction) view: (id)sender
{
	[[self nextResponder] view: sender];
}

- (IBAction) inspect: (id)sender
{
	[[self nextResponder] inspect: sender];
}

@end
