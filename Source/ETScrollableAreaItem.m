/* 
	Copyright (C) 2009 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  March 2009
	License:  Modified BSD  (see COPYING)
 */

#import <EtoileFoundation/Macros.h>
#import "ETScrollableAreaItem.h"
#import "ETView.h"
#import "ETGeometry.h"
#import "ETLayoutItem.h"
#import "NSObject+EtoileUI.h"
#import "ETCompatibility.h"

// TODO: Support to center the content in the clip view automatically. 
// We could add -setContentCentered: and -isContentCentered and write a 
// NSClipView subclass to implement it. 
// An alternative could be a layout that automatically centers the layout item 
// content, when the scrollable area item resize invokes 
// -[decoratedItem needsLayoutUpdate]. In fact, that's more or less what a 
// layout such as ETFlowLayout already does when bound to an item group 
// decorated by a scrollable area item.
// Yet another alternative is to use a wrapper view whose minimum size is the 
// decorated item contentSize and adjust the decorated item supervisor view 
// autoresizing mask

/* To understand ETScrollableAreaItem, here is what you should know about 
NSScrollView and which is only partially documented in both GNUstep and Cocoa...

NSScrollView uses flipped coordinates which means the clip view origin is 
always (0, 0) even when the horizontal scroller is visible.

NSScrollView doesn't resize its document view automatically 
when it gets itself resized, unless the document view autoresizing mask was set 
to NSViewWidthSizable and NSViewHeightSizable.

NSScrollView doesn't use the document view frame origin at all, even to position 
the document view inside the clip view. You can invoke -setFrameOrigin: on the 
document view and the origin will be updated, but this won't result in any 
visible change.
The document view bounds origin value is ignored in a similar way.

NSScrollView clip view observes the document view frame size and the document 
bounds size and updates both the document visible area and the scrollers to 
reflect their new values.

For ETScrollableAreaItem, the content view must also never change because we 
observe it. 

We usually refer to the -[NSScrollView contentView] as the clip view. In 
ETScrollableAreaItem terminology, the content is equivalent to the document view 
and the visible content to the content view. This terminology choice was made 
to be consistent with the rest of EtoileUI and was considered acceptable because    
NSScrollView terminology isn't not really clear (especially when you consider 
the role played by -contentView in other AppKit view classes). */
@implementation ETScrollableAreaItem

- (NSScrollView *) scrollView
{
	return (NSScrollView *)[[self supervisorView] mainView];
}

- (id) init
{
	return [self initWithSupervisorView: nil];
}

- (id) initWithSupervisorView: (ETView *)aView
{
	ETScrollView *supervisorView = AUTORELEASE([[ETScrollView alloc] initWithMainView: nil layoutItem: (ETLayoutItem *)self]);
	self = [super initWithSupervisorView: supervisorView];
	if (nil == self)
		return nil;

	_ensuresContentFillsVisibleArea = YES;

	//ETLog(@"Scroll view %@", [self scrollView]);

	return self;
}

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver: self];
	[super dealloc];
}

/** Ensures the content fills the clip view area when the latter is resized, 
usually through its enclosing scroll view getting resized. */
- (void) clipViewFrameDidChange: (NSNotification *)notif
{
	ETDebugLog(@"Clip view resized to %@", NSStringFromSize([self visibleContentRect].size));

	ETUIItem *decoratedItem = [self decoratedItem];

	/* Will immediately call back -decoratedItemRectChanged:.
	   We want the decorated item content bounds to be synchronized with its 
	   supervisorView, therefore we must call -[ETView setFrame:] since 
	   -setFrameSize: doesn't handle the synchronization on Mac OS X.

	   TODO: We should rather use a dedicated API to reduce dependency on the 
	   supervisor view concept... .e.g. [decoratedItem setDecorationRect:], 
	   but -setDecorationRect: meaning is currently incompatible and needs to 
	   be relaxed. */
	[[decoratedItem supervisorView] setFrame: 
		ETMakeRect([[decoratedItem supervisorView] frame].origin, [self visibleContentRect].size)];

	if ([decoratedItem isLayoutItem])
	{
		/* Will call back -decoratedItemRectChanged: when the layout is done and 
		   the new layout size was set on our decorated item with -setContentSize:. */
		[(ETLayoutItem *)decoratedItem updateLayout];
	}
}

- (void) saveAndOverrideAutoresizingMaskOfDecoratedItem: (ETUIItem *)item
{
	// FIXME: Move -addObserver: in the initializer once ETScrollView 
	// initializer isn't used externally and won't overwrite the decorator 
	// supervisor view. Presently ETScrollView and ETScrollableAreaItem 
	// initializers invokes each other in a very ugly way and can overwrite 
	// their state.
	[[NSNotificationCenter defaultCenter] addObserver: self
	                                         selector: @selector(clipViewFrameDidChange:)
	                                             name: NSViewFrameDidChangeNotification
	                                           object: [self supervisorView]];

	[[[self lastDecoratorItem] supervisorView] setAutoresizingMask: 
		[[item supervisorView] autoresizingMask]];
	[[item supervisorView] setAutoresizingMask: NSViewNotSizable];
}

/* Patches the size to be sure it will never be smaller than the clip view 
size, otherwise a click on the content background to unselect might not work 
and custom content background or overlay won't draw over the entire visible area. */
- (NSSize) decoratedItemRectChanged: (NSRect)rect
{
	NSSize sizeToCoverClipView = rect.size;

	ETDebugLog(@"Decorated item rect changed to %@", NSStringFromRect(rect));

	if (rect.size.height < [self visibleContentRect].size.height)
		sizeToCoverClipView.height = [self visibleContentRect].size.height;

	if (rect.size.width < [self visibleContentRect].size.width)
		sizeToCoverClipView.width = [self visibleContentRect].size.width;

	/* When a decorator is used, the item does not synchronize its geometry 
	   with its supervisor view, but ask its decorator item to handle that.
	   Usually by resizing the decorator itself, its supervisor view will 
	   resize the decorated item supervisor view (a decorated view autoresizing 
	   mask is normally set to NSViewWidthSizable and NSViewHeightSizable by 
	   -saveAndOverrideAutoresizingMaskOfDecoratedItem. In our case, we 
	   override it to be NSViewNotSizable. Which means we have to resize the 
	   decorated view on our own, otherwise a mismatch would exist between 
	   the decorated item and its supervisor view. This might result in the 
	   scrollers being wrongly inactive because the decorated view is truncated 
	   to clip rect. That's why the new decorated item size computed by the 
	   layout and receives as the rect parameter should be applied to the 
	   decorated view.
	   We can safely alter the decorated view size because we are already in 
	   a geometry syncrhonization phase (started by -setContentBounds:) and 
	   -shoudSynchronizeGeometry will return NO in [decoratedView setFrame:]
	   Finally when the decorated item is not a layout item but a decorator 
	   item, no geometry syncrhonization exits
	   -[ETDecoratedItem shouldSynchronizeGeometry] returns NO. */
	   
	[[[self decoratedItem] supervisorView] setFrameSize: sizeToCoverClipView];
	
	return sizeToCoverClipView;
}

/* Ensures that resizing the scroll view won't resize its content (aka document 
view), except when the visible content doesn't fill the clip view once the 
scroll view is resized. 

Take note that this method will be called back by -setFirstDecoratedItemFrame: 
when the receiver is set up as a decorator.*/
- (void) handleSetDecorationRect: (NSRect)aRect
{
	/* Will resize the clip view but not call back -decoratedItemRectChanged: 
	   because we just made the document view not automatically resizable. */
	[super handleSetDecorationRect: aRect];

	NSSize contentSize = [self contentRect].size;
	NSSize visibleContentSize = [self visibleContentRect].size;
	NSParameterAssert(contentSize.width >= visibleContentSize.width 
		&& contentSize.height >= visibleContentSize.height);
}

/** Returns the rect that corresponds to the visible part of the content and 
expressed in the receiver content coordinate space (relative to the content 
rect). */
- (NSRect) visibleRect
{
	return [[self scrollView] documentVisibleRect];
}

/** Returns the rect that corresponds to the visible part of the content and 
expressed in the receiver coordinate space (relative to the decoration rect).

For now, this area corresponds to the scrollable area or clip rect and can 
extend beyond the content rect when the whole content is visible (in other words 
when scrollers are disabled). This is subject to change though. */
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

/** Returns whether the decorated item size should be always be kept equal or 
superior to the visible content size. 

Returns YES by default. */
- (BOOL) ensuresContentFillsVisibleArea
{
	return _ensuresContentFillsVisibleArea;
}

/** Sets whether the decorated item size should be always be kept equal or 
superior to the visible content size. 

You might want to disable this behavior when you decorate a layout item whose 
size must remain fixed. A layout item that presents an image must probably 
never be resized when the scrollable area item is resized. */
- (void) setEnsuresContentFillsVisibleArea: (BOOL)flag
{
	_ensuresContentFillsVisibleArea = flag;
}

@end


@implementation ETScrollView : ETView

- (id) initWithFrame: (NSRect)frame layoutItem: (ETLayoutItem *)anItem
{
	return [self initWithMainView: AUTORELEASE([[NSScrollView alloc] initWithFrame: frame]) 
	                   layoutItem: anItem];
}

- (id) initWithMainView: (id)aScrollView layoutItem: (ETLayoutItem *)anItem
{
	ETLayoutItem *newItem = anItem;
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

	/* Retain the view in case it must be removed from a superview and nobody
	   else retains it */
	RETAIN(view);
	[(NSScrollView *)[self mainView] setDocumentView: view];
	RELEASE(view);
}

@end
