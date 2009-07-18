/* 
	Copyright (C) 2009 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  March 2009
	License:  Modified BSD  (see COPYING)
 */

#import <EtoileFoundation/Macros.h>
#import "ETScrollableAreaItem.h"
#import "ETView.h"
#import "ETCompatibility.h"


@implementation ETScrollableAreaItem

- (id) init
{
	return [self initWithSupervisorView: nil];
}

- (id) initWithSupervisorView: (ETView *)aView
{
	ETScrollView *supervisorView = AUTORELEASE([[ETScrollView alloc] initWithMainView: nil layoutItem: (ETLayoutItem *)self]);
	return [super initWithSupervisorView: supervisorView];
}

- (NSScrollView *) scrollView
{
	return (NSScrollView *)[[self supervisorView] mainView];
}


/* Patches the size to be sure it will never be smaller than the clip view 
size, otherwise a click on the content background to unselect might not work 
and custom content background or overlay won't draw over the entire visible area. */
- (NSSize) decoratedItemRectChanged: (NSRect)rect
{
	NSSize sizeToCoverClipView = rect.size;

	if (rect.size.height < [self visibleContentRect].size.height)
		sizeToCoverClipView.height = [self visibleContentRect].size.height;

	if (rect.size.width < [self visibleContentRect].size.width)
		sizeToCoverClipView.width = [self visibleContentRect].size.width;

	[[[self scrollView] documentView] setFrameSize: sizeToCoverClipView];
	return sizeToCoverClipView;
}

/** Returns the rect that corresponds to the visible part of the content and 
expressed in the receiver content coordinate space (relative to the content 
rect). */
- (NSRect) visibleRect
{
	return [[self scrollView] documentVisibleRect];
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
	//[[self layout] syncLayoutViewWithItem: self];
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
	//[[self layout] syncLayoutViewWithItem: self];
}

@end


@implementation ETScrollView : ETView

- (id) initWithFrame: (NSRect)frame layoutItem: (ETLayoutItem *)item
{
	return [self initWithMainView: AUTORELEASE([[NSScrollView alloc] initWithFrame: frame]) 
	                   layoutItem: item];
}

- (id) initWithMainView: (id)aScrollView layoutItem: (ETLayoutItem *)item
{
	ETLayoutItem *newItem = item;
	NSScrollView *scrollView = aScrollView;

	if (newItem == nil)
	{
		newItem = AUTORELEASE([[ETScrollableAreaItem alloc] init]);
	}
	if (scrollView == nil)
	{
		scrollView = AUTORELEASE([[NSScrollView alloc] init]);
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
