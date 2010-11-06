/*
	Copyright (C) 2009 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  April 2009
	License: Modified BSD (see COPYING)
 */

#import <EtoileFoundation/Macros.h>
#import "ETLayoutItem+Scrollable.h"
#import "ETLayout.h"
#import "ETScrollableAreaItem.h"
#import "NSObject+EtoileUI.h"
#import "ETCompatibility.h"

/* First instance created by calling private method -cachedScrollViewDecoratorItem */
const NSString *kETCachedScrollableAreaDecoratorItem = @"cachedScrollViewDecoratorItem";

@interface ETLayoutItem (ScrollablePrivate)
- (void) hidesScrollableAreaItem;
- (void) unhidesScrollableAreaItem;
- (void) cacheScrollableAreaItem: (ETScrollableAreaItem *)decorator;
- (ETScrollableAreaItem *) cachedScrollableAreaItem;
- (ETScrollableAreaItem *) createScrollableAreaItem;
@end


@implementation ETLayoutItem (Scrollable)

/** Returns YES when the vertical scroller of the current scroll view managed 
by the receiver or its layout is visible, otherwise returns NO. */
- (BOOL) hasVerticalScroller
{
	return [[self cachedScrollableAreaItem] hasVerticalScroller];
}

/** Sets the vertical scroller visibility of the current scrollable area that 
can be owned either by the receiver or its layout.

Even if both vertical and horizontal scroller are made invisible, this method
won't remove the scrollable area decorator managed by the receiver from the 
decorator chain. */
- (void) setHasVerticalScroller: (BOOL)scroll
{
	if (scroll)
	{
		[self setScrollable: YES];
	}
	[[self cachedScrollableAreaItem] setHasVerticalScroller: scroll];

	/* Update NSBrowser, NSOutlineView enclosing scroll view etc. */
	[[self layout] syncLayoutViewWithItem: self];
}

/** Returns YES when the horizontal scroller of the current scrollable area 
managed by the receiver or its layout is visible, otherwise returns NO. */
- (BOOL) hasHorizontalScroller
{
	return [[self cachedScrollableAreaItem] hasHorizontalScroller];
}

/** Sets the horizontal scroller visibility of the current scrollable area that 
can be owned either by the receiver or its layout.

Even if both vertical and horizontal scrollers are made invisible, this method
won't remove the scrollable area decorator managed by the receiver from the 
decorator chain. */
- (void) setHasHorizontalScroller: (BOOL)scroll
{
	if (scroll)
	{
		[self setScrollable: YES];
	}
	[[self cachedScrollableAreaItem] setHasHorizontalScroller: scroll];

	/* Update NSBrowser, NSOutlineView enclosing scroll view etc. */
	[[self layout] syncLayoutViewWithItem: self];
}

/** Returns whether the horizontal scroller, the vertical scroller or both are 
visible.

This method returns NO when no scroller is visible, even when 
-hasHorizontalScroller or -hasVerticalScroller return YES. */
- (BOOL) hasAnyVisibleScroller
{
	return ([self isScrollable] && 
		([self hasHorizontalScroller] || [self hasVerticalScroller]));
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
		[self hidesScrollableAreaItem];
	}
	else if (showScrollableAreaItem && [self isScrollable])
	{
		[self unhidesScrollableAreaItem];		
	}
}

- (void) cacheScrollableAreaItem: (ETScrollableAreaItem *)decorator
{
	SET_PROPERTY(decorator, kETCachedScrollableAreaDecoratorItem);
}

- (ETScrollableAreaItem *) cachedScrollableAreaItem
{
	ETScrollableAreaItem *decorator = GET_PROPERTY(kETCachedScrollableAreaDecoratorItem);

	if (nil == decorator)
	{
		decorator = AUTORELEASE([self createScrollableAreaItem]);
		[self cacheScrollableAreaItem: decorator];
	}

	return decorator;
}

/* When a scrollable area item becomes our decorator, we make it our cached 
scrollable area item. 

NOTE: -unhidesScrollViewDecoratorItem triggers this call back. */
- (void) didChangeDecoratorOfItem: (ETUIItem *)item
{
	NSParameterAssert([item isLayoutItem]);
	if ([[item decoratorItem] isScrollableAreaItem])
	{
		[self cacheScrollableAreaItem: (ETScrollableAreaItem *)[item decoratorItem]];
	}
}

- (BOOL) isScrollableAreaItemVisible
{
	return [[self decoratorItem] isScrollableAreaItem];
}

/* When no cached scrollable area item exists we create one even when the 
layout provides its own scrollers (returns YES to -[ETLayout hasScrollers]). 
We use this cached instance to store the scroll related settings and we 
synchronize those layouts with it every time a setting changed.  */
- (void) unhidesScrollableAreaItem 
{
	if ([self isScrollableAreaItemVisible])
		return;

	// NOTE: Will call back -didChangeScrollDecoratorOfItem:
	[self setDecoratorItem: [self cachedScrollableAreaItem]];
	if ([[self layout] hasScrollers])
	{
		[[self layout] syncLayoutViewWithItem: self];	
	}
	[[self layout] setIsContentSizeLayout: YES];
}

- (void) hidesScrollableAreaItem 
{
	if ([self isScrollableAreaItemVisible] == NO)
		return;

	ETScrollableAreaItem *scrollableAreaItem = [self scrollableAreaItem];
	ETDecoratorItem *nextDecorator = [scrollableAreaItem decoratorItem];	
		
	[[scrollableAreaItem decoratedItem] setDecoratorItem: nextDecorator];
	if ([[self layout] hasScrollers])
	{
		[[self layout] syncLayoutViewWithItem: self];	
	}
	[[self layout] setIsContentSizeLayout: NO];
}

/** Returns wether the receiver content is enclosed in a scrollable area.

See -setScrollable:. */
- (BOOL) isScrollable
{
	return _scrollViewShown;
}

/** Sets wether the receiver content is enclosed in a scrollable area.

When -hasAnyVisibleScrollers returns NO, scrollers won't become visible when the 
receiver is requested to become scrollable.

The scrollable area role can be embodied by:
<list>
<item>the decorator (i.e. [self decoratorItem] is a scrollable area item)</item> 
<item>the layout (i.e. the layout returns YES to -hasScrollers)</item>
</list> */
- (void) setScrollable: (BOOL)scrollable
{
	if (_scrollViewShown == scrollable)
		return;
	
	_scrollViewShown = scrollable;

	if ([[self layout] hasScrollers])
	{
		[[self layout] syncLayoutViewWithItem: self];	
	}
	else
	{
		if (scrollable)
		{
			[self unhidesScrollableAreaItem];
		}
		else
		{
			[self hidesScrollableAreaItem];
		}
	}
}

- (ETScrollableAreaItem *) createScrollableAreaItem
{
	ETScrollableAreaItem *decorator = [[ETScrollableAreaItem alloc] init];

	NSParameterAssert([decorator hasVerticalScroller] == NO 
		&& [decorator hasHorizontalScroller] == NO);

	return decorator;
}

@end
