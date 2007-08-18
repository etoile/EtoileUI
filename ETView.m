/* <title>ETView.m</title>
	
	<abstract>NSView replacement class with extra facilities like delegated drawing.</abstract>
 
	Copyright (C) 2007 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  August 2007
 
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

#import <EtoileUI/ETView.h>
#import <EtoileUI/GNUstep.h>


@implementation ETView

- (void) dealloc
{
	DESTROY(_renderer);
	
	[super dealloc];
}

- (void) setRenderer: (id)renderer
{
	ASSIGN(_renderer, renderer);
}

- (id) renderer
{
	return _renderer;
}

- (void) drawRect: (NSRect)rect
{
	[super drawRect: rect];

	/* Now we must draw layout items without view... using either a cell or 
	   their own renderer. Layout item are smart enough to avoid drawing their
	   view when they have one. */
	// FIXME: Turned off this invocation of the rendering chain to avoid drawing
	// selection out of bounds because the selected view doesn't receive 
	// -lockFocus
	//if ([[self renderer] respondsToSelector: @selector(render:)])
		//[[self renderer] render: nil];
}

- (void) setWrappedView: (NSView *)view
{
	[self setAutoresizesSubviews: YES];
	
	if (view != nil)
	{
		[view setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
		[self addSubview: view];
		_wrappedView = view;
	}
	else
	{
		[_wrappedView removeFromSuperview];
		_wrappedView = nil;
	}
}

- (NSView *) wrappedView
{
	return _wrappedView;
}

- (void) displayIfNeeded
{
	NSLog(@"-displayIfNeeded");
	[super displayIfNeeded];
}

- (void) displayIfNeededInRect:(NSRect)aRect
{
	NSLog(@"-displayIfNeededInRect:");
	[super displayIfNeededInRect: aRect];
}

- (void) displayIfNeededInRectIgnoringOpacity:(NSRect)aRect
{
	NSLog(@"-displayIfNeededInRectIgnoringOpacity:");
	[super displayIfNeededInRectIgnoringOpacity: aRect];
}

- (void) display
{	
	NSLog(@"-display");
	[super display];
}

- (void) displayRect:(NSRect)aRect
{
	NSLog(@"-displayRect:");
	[super displayRect: aRect];
}

- (void) displayRectIgnoringOpacity:(NSRect)aRect
{
	NSLog(@"-displayRectIgnoringOpacity:");
	[super displayRectIgnoringOpacity: aRect];
}

#ifdef GNUSTEP
- (void) displayRectIgnoringOpacity: (NSRect)aRect 
                          inContext: (NSGraphicsContext *)context
{
	NSLog(@"-displayRectIgnoringOpacity:inContext:");
	[super displayRectIgnoringOpacity: aRect inContext: context];

	/* We always composite the rendering chain on top of each view -drawRect: 
	   drawing sequence. */
	if ([[self renderer] respondsToSelector: @selector(render:)])
		[[self renderer] render: nil];
}
#else

// FIXME: This isn't really safe because Cocoa may use other specialized 
// methods to update the display. They are named _recursiveDisplayXXX.
// NOTE: Very often NSView instance which has been sent a display message will 
// call this method on its subviews. These subviews will do the same with their own 
// subviews. Here is the other method often used in the same way:
//_recursiveDisplayRectIfNeededIgnoringOpacity:isVisibleRect:rectIsVisibleRectForView:topView:
// The previous method usually follows the message on next line:
//_displayRectIgnoringOpacity:isVisibleRect:rectIsVisibleRectForView:
- (void) _recursiveDisplayAllDirtyWithLockFocus: (BOOL)lockFocus visRect: (NSRect)aRect
{
	//NSLog(@"-_recursiveDisplayAllDirtyWithLockFocus:visRect:");
	[super _recursiveDisplayAllDirtyWithLockFocus: lockFocus visRect: aRect];
	
	/* We always composite the rendering chain on top of each view -drawRect: 
	   drawing sequence (triggered by display-like methods). */
	if ([[self renderer] respondsToSelector: @selector(render:)])
		[[self renderer] render: nil];
}
#endif

@end
