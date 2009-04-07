/*  <title>ETScrollableAreaItem</title>

	ETScrollableAreaItem.m
	
	<abstract>ETDecoratorItem subclass which makes content scrollable.</abstract>
 
	Copyright (C) 2009 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  March 2009
 
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
#import "ETScrollableAreaItem.h"
#import "ETView.h"
#import "ETCompatibility.h"


@implementation ETScrollableAreaItem

- (id) init
{
	return [super initWithSupervisorView: nil];
}

- (NSScrollView *) scrollView
{
	return (NSScrollView *)[[self supervisorView] mainView];
}

- (void) decoratedItemRectChanged: (NSRect)rect
{
	[[[self scrollView] documentView] setFrameSize: rect.size]; // May be should be -setFrameSize:
}

/** Returns the rect that corresponds to the visible part of the content and 
expressed in the receiver coordinate space (relative to the decoration rect). */
- (NSRect) visibleContentRect
{
	return [[[self scrollView] contentView] frame];
}

/** Returns YES when the vertical scroller of the current scrollable area is 
visible, otherwise returns NO. */
- (BOOL) hasVerticalScroller
{
	return [[self scrollView] hasVerticalScroller];
}

/** Sets the vertical scroller visibility of the current scrollable area.

Even if both vertical and horizontal scroller are made invisible, this method 
won't remove the receiver from the decorator chain it currently belongs to. */
- (void) setHasVerticalScroller: (BOOL)scroll
{
	[[self scrollView] setHasVerticalScroller: scroll];
	
	/* Updated NSBrowser, NSOutlineView enclosing scroll view etc. */
	//[self syncDisplayViewWithContainer];
}

/** Returns YES when the horizontal scroller of the current scrollable area view 
is visible, otherwise returns NO. */
- (BOOL) hasHorizontalScroller
{
	return [[self scrollView] hasHorizontalScroller];
}

/** Sets the horizontal scroller visibility of the current scrollable area.

For additional notes, see also -setHasVerticalScroller:. */
- (void) setHasHorizontalScroller: (BOOL)scroll
{
	[[self scrollView] setHasHorizontalScroller: scroll];
	
	/* Updated NSBrowser, NSOutlineView enclosing scroll view etc. */
	//[self syncDisplayViewWithContainer];
}

@end


@implementation ETScrollView : ETView

- (id) initWithFrame: (NSRect)frame layoutItem: (ETLayoutItem *)item
{
	NSScrollView *realScrollView = [[NSScrollView alloc] initWithFrame: frame];

	self = [self initWithMainView: realScrollView layoutItem: item];
	RELEASE(realScrollView);
	
	return self;
}

- (id) initWithMainView: (id)scrollView layoutItem: (ETLayoutItem *)item
{
	ETLayoutItem *newItem = item;

	if (newItem == nil)
	{
		newItem = AUTORELEASE([[ETScrollableAreaItem alloc] init]);
	}

	NSAssert([newItem isKindOfClass: [ETScrollableAreaItem class]], @"The item "
		"used to initialize an ETScrollView must be an ETScrollableAreaItem");

	self = [super initWithFrame: [scrollView frame] layoutItem: newItem];

	if (self != nil)
	{
		[self setAutoresizingMask: [scrollView autoresizingMask]];
		[scrollView setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];

		/* Will be destroy in -[ETView dealloc] */
		ASSIGN(_mainView, scrollView);
		[self addSubview: _mainView];
		[self tile];
	}
	
	return self;	
}

- (void) dealloc
{
	DESTROY(_mainView);
	
	[super dealloc];
}

- (NSView *) mainView
{
	return _mainView;
}

- (NSView *) wrappedView
{
	return [(NSScrollView *)[self mainView] documentView]; 
}

/* Embed the wrapped view inside the receiver scroll view */
- (void) setContentView: (NSView *)view temporary: (BOOL)temporary
{
	NSAssert2([[self mainView] isKindOfClass: [NSScrollView class]], 
		@"_mainView %@ of %@ must be an NSScrollView instance", 
		[self mainView], self);

	if (view != nil)
	{
		[self setAutoresizingMask: [view autoresizingMask]];
	}
	else
	{
		/* Restore autoresizing mask */
		[[(NSScrollView *)[self mainView] documentView] 
			setAutoresizingMask: [self autoresizingMask]];	
	}

	/* Retain the view in case it must be removed from a superview and nobody
	   else retains it */
	RETAIN(view);
	[(NSScrollView *)[self mainView] setDocumentView: view];
	RELEASE(view);
}

@end
