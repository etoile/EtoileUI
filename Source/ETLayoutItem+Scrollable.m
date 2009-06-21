/*  <title>ETLayoutItem+Scrollable</title>

	ETLayoutItem+Scrollable.m

	<abstract>Syntactic sugar to insert and remove scrollers very easily on a 
	layout item.</abstract>

	Copyright (C) 2009 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  April 2009

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
#import "ETLayoutItem+Scrollable.h"
#import "ETLayout.h"
#import "ETScrollableAreaItem.h"
#import "ETCompatibility.h"

/* First instance created by calling private method -setShowsScrollView: */
const NSString *kETCachedScrollableAreaDecoratorItem = @"cachedScrollViewDecoratorItem";

@interface ETLayoutItem (ScrollablePrivate)
- (void) setShowsScrollView: (BOOL)scroll;
- (void) cacheScrollViewDecoratorItem: (ETScrollableAreaItem *)decorator;
- (ETScrollableAreaItem *) cachedScrollViewDecoratorItem;
- (ETScrollableAreaItem *) createScrollViewDecoratorItem;
@end


@implementation ETLayoutItem (Scrollable)

- (BOOL) letsLayoutControlsScrollerVisibility
{
	return NO;
}

- (void) setLetsLayoutControlsScrollerVisibility: (BOOL)layoutControl
{
	// FIXME: Implement or remove
}

/* About the container scroll view and layouts

   From API viewpoint, it makes little sense to keep these scroller methods if
   we offer a direct access to the underlying scroll view. However a layout view 
   may want to heavily alter the scroll view in a way that only works in this 
   specific layout case. That's why layouts have the choice to use or not the 
   scroll view set up and cached by the container.
   It also makes easier to support AppKit views/controls wrapped in a layout. 
   For example NSBrowser has a method like -setHasHorizontalScroller: but isn't 
   wrapped inside a scroll view. Setting up and tearing down the container 
   scroll view to be reused by a NSTableView-based layout or a NSTextView-based 
   layout would also introduce an extra chunk of non-trivial code.
   We only keep in sync (with the container scroll view) basic properties like 
   scroller visibility, when a layout uses its own scroll view. They are the 
   only scroll view settings which are very commonly altered independently of 
   the presentation (the layout in EtoileUI case). 
   NOTE: Another approach would be move this logic into ETScrollView but obvious 
   benefits have to be found. */

/** Returns YES when the vertical scroller of the current scroll view managed 
by the receiver or its layout is visible, otherwise returns NO. */
- (BOOL) hasVerticalScroller
{
	return [[self scrollView] hasVerticalScroller];
}

/** Sets the vertical scroller visibility of the current scroll view that can 
be owned either by the receiver or its layout.

Even if both vertical and horizontal scroller are made invisible, this method
won't remove the scrollable area decorator managed by the receiver from the 
decorator chain. */
- (void) setHasVerticalScroller: (BOOL)scroll
{
	if (scroll)
	{
		[self setShowsScrollView: YES];
	}
	[[self scrollView] setHasVerticalScroller: scroll];

	/* Update NSBrowser, NSOutlineView enclosing scroll view etc. */
	[[self layout] syncLayoutViewWithItem: self];
}

/** Returns YES when the horizontal scroller of the current scroll view managed 
by the receiver or its layout is visible, otherwise returns NO. */
- (BOOL) hasHorizontalScroller
{
	return [[self scrollView] hasHorizontalScroller];
}

/** Sets the horizontal scroller visibility of the current scroll view that can 
be owned either by the receiver or its layout.

Even if both vertical and horizontal scrollers are made invisible, this method
won't remove the scrollable area decorator managed by the receiver from the 
decorator chain. */
- (void) setHasHorizontalScroller: (BOOL)scroll
{
	if (scroll)
	{
		[self setShowsScrollView: YES];
	}
	[[self scrollView] setHasHorizontalScroller: scroll];

	/* Update NSBrowser, NSOutlineView enclosing scroll view etc. */
	[[self layout] syncLayoutViewWithItem: self];
}

// TODO: Evaluates whether we really need to keep public the following methods 
// exposing NSScrollView directly. Would be cleaner to provide a ready to use 
// ETScrollView in the UI builder and the related inspector to configure it.

/** Returns the scroll view managed by the receiver to let you modify its 
settings. 

This underlying scroll view is wrapped inside an ETScrollView instance, 
itself referenced by a layout item that can be inserted and removed in the 
decorator chain by calling hide/unhide methods. */
- (NSScrollView *) scrollView
{
	id cachedDecorator = [self cachedScrollViewDecoratorItem];
	
	if (cachedDecorator == nil)
	{
		[self cacheScrollViewDecoratorItem: [self createScrollViewDecoratorItem]];
		cachedDecorator = [self cachedScrollViewDecoratorItem];
	}

	return (NSScrollView *)[[cachedDecorator supervisorView] mainView];
}

/** Hides or shows the cached scrollable area item based on whether the current 
layout controls the scrollers visibility or not.

You should never need to call this method which is used internally. */
- (void) updateScrollableAreaItemVisibility
{
	ETLayout *layout = [self layout];

	if ([layout hasScrollers])
	{
		NSAssert([layout isScrollable], @"A layout which returns YES "
		 "with -hasScrollers must return YES with -isScrollable");
	}

	BOOL hideScrollableAreaItem = ([layout isScrollable] == NO || [layout hasScrollers]);
	BOOL showScrollableAreaItem =  ([layout isScrollable] && [layout hasScrollers] == NO);

	if (hideScrollableAreaItem)
	{
		[self hidesScrollViewDecoratorItem];
	}
	else if (showScrollableAreaItem && [self isScrollViewShown])
	{
		[self unhidesScrollViewDecoratorItem];		
	}
}

- (void) cacheScrollViewDecoratorItem: (ETScrollableAreaItem *)decorator
{
	SET_PROPERTY(decorator, kETCachedScrollableAreaDecoratorItem);
}

- (ETScrollableAreaItem *) cachedScrollViewDecoratorItem
{
	return GET_PROPERTY(kETCachedScrollableAreaDecoratorItem);
}

/* When a new scroll view decorator is inserted in the decorator chain we cache 
   it. -unhidesScrollViewDecoratorItem triggers this call back. */
- (void) didChangeDecoratorOfItem: (ETUIItem *)item
{
	NSParameterAssert([item isLayoutItem]);
	if ([(ETLayoutItem *)item firstScrollViewDecoratorItem] != nil)
		[self cacheScrollViewDecoratorItem: [(ETLayoutItem *)item firstScrollViewDecoratorItem]];

	// TODO: We might cache the position of the first scroll view decorator in  
	// the decorator chain in order to be able to reinsert it at the same 
	// position in -unhidesScrollViewDecoratorItem. We currently only support 
	// reinserting it in the first position.
}

/* Returns whether the scroll view of the current container is really used. If
   the container shows currently an AppKit control like NSTableView as display 
   view, the built-in scroll view of the table view is used instead of the one
   provided by the container. 
   It implies you can never have -hasScrollView returns NO and -isScrollViewShown 
   returns YES. There is no such exception with all other boolean combinations. */
- (BOOL) isScrollViewShown
{
	return _scrollViewShown;
}

- (BOOL) isContainerScrollViewInserted
{
	return ([self firstScrollViewDecoratorItem] != nil);
}

/** Inserts a scroll view as the first decorator item bound to the receiver 
	layout item if no scroll view decorator can be found in the decorator chain. 
	If such a decorator already exists, does nothing.
	The receiver container caches a scroll view decorator, hence it is possible 
	to remove/insert the scroll view in the decorator chain by calling 
	hide/unhide methods without losing the scroll view settings.
	When no scroll view decorator has already been cached, behind the scene, 
	this method creates a ETScrollView instance and builds a decorator item with 
	this view. This new scroll view decorator item is finally inserted as the 
	first decorator. */
- (void) unhidesScrollViewDecoratorItem 
{
	if ([self isContainerScrollViewInserted])
		return;

	id scrollDecorator = [self cachedScrollViewDecoratorItem];	
	
	/* If no scroll view exists we create one even when a display view is in use
	   simply because we use the container scroll view instance to store all
	   scroller settings. We update any scroller settings defined in a display
	   view with that of the newly created scroll view.  */
	if (scrollDecorator == nil)
		scrollDecorator = [self createScrollViewDecoratorItem];

	// NOTE: Will call back -didChangeScrollDecoratorOfItem: which takes care of 
	// caching the scroll decorator
	[self setDecoratorItem: scrollDecorator];
	//[_scrollView setAutoresizingMask: [self autoresizingMask]];
		
	// TODO: This should be handled rather on scroll view decorator 
	// insertion and probably in ETLayoutItem itself
	[[self layout] setContentSizeLayout: YES];
}

- (void) hidesScrollViewDecoratorItem 
{
	if ([self isContainerScrollViewInserted] == NO)
		return;
		
	NSAssert([[self scrollView] superview] != nil, @"A scroll view without "
		@"superview cannot be hidden");

	id scrollDecorator = [self firstScrollViewDecoratorItem];
	id nextDecorator = [scrollDecorator decoratorItem];	
		
	[[scrollDecorator decoratedItem] setDecoratorItem: nextDecorator];
	//[self setAutoresizingMask: [_scrollView autoresizingMask]];
	
	// NOTE: The assertion below was added to ensure [self setFrame: 
	// [_scrollView frame]]; was correctly applied, it may be better to move
	// it in decorator handling of ETLayoutItem. As it is, it doesn't make 
	// much sense anymore because it is valid only when the scroll view is 
	// the first decorator of the layout item bound to the container.
	// WARNING: More about next line and following assertion can be read here: 
	// <http://www.cocoabuilder.com/archive/message/cocoa/2006/9/29/172021>
	// Stop also to receive any view/window notifications in ETContainer code 
	// before turning scroll view on or off.
	#if 0
	// This test will never work unless you retain scrollDecorator before 
	// removing it
	NSAssert1(NSEqualRects([self frame], [[scrollDecorator supervisorView] frame]), 
		@"Unable to update the frame of container %@, you must stop watch "
		@"any notifications posted by container before hiding or showing "
		@"its scroll view (Cocoa bug)", self);
	#endif

	// TODO: This should be handled rather on scroll view decorator 
	// removal and probably in ETLayoutItem itself
	[[self layout] setContentSizeLayout: NO];
}

- (void) setShowsScrollView: (BOOL)show
{
	if (_scrollViewShown == show)
		return;

	// FIXME: Asks layout whether it handles scroll view itself or not. If 
	// needed like with table layout, delegate scroll view handling.
	BOOL layoutHandlesScrollView = ([[self layout] isWidget]); //([self layoutView] != nil);
	
	_scrollViewShown = show;

	if (layoutHandlesScrollView)
	{
		[[self layout] syncLayoutViewWithItem: self];	
	}
	else
	{
		if (show)
		{
			[self unhidesScrollViewDecoratorItem];
		}
		else
		{
			[self hidesScrollViewDecoratorItem];
		}
	}
}

- (ETScrollableAreaItem *) createScrollViewDecoratorItem
{
	ETScrollView *scrollViewWrapper = nil;
	
	scrollViewWrapper = [[ETScrollView alloc] initWithFrame: [self frame]];
	AUTORELEASE(scrollViewWrapper);

	NSScrollView *scrollView = (NSScrollView *)[scrollViewWrapper mainView];
	BOOL noVisibleScrollers = ([scrollView hasVerticalScroller] == NO &&
		[scrollView hasHorizontalScroller] == NO);
	NSAssert2(noVisibleScrollers, @"New scrollview %@ wrapper is expected have "
		"no visible scrollers to be used by %@", scrollViewWrapper, self);

	return (ETScrollableAreaItem *)[scrollViewWrapper layoutItem];
}

@end
