/** <title>ETLayoutItem+Scrollable</title>

	<abstract>Syntactic sugar to insert and remove scrollers very easily on a 
	layout item.</abstract>

	Copyright (C) 2009 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  April 2009
	License: Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <EtoileUI/ETLayoutItem.h>

/** This ETLayoutItem category manages ETScrollableAreaItem insertion and removal 
in the receiver decorator chain. You can use it rather than interacting directly 
with a scrollable area item you set up and remove manually.

You can set a scrollable area item with -setDecoratorItem: on a layout item and 
it will be then managed by this category. Which means methods like 
-[ETLayoutItem setHasVerticalScroller:] can still be used transparently.

The scrollable are item is also automatically removed or inserted, based on 
wether or not the receiver layout comes with built-in scroll support. e.g. 
widget layouts such as ETTableLayout or ETBrowserLayout.

By altering the scroller visibility with this category, you can be sure you 
won't have to reconfigure the scrollable area item even when you remove it or 
it gets removed. It will be reinserted when scrollers are reenabled, because 
scrollable area items handed to -[ETLayoutItem setDecoratorItem:] are cached. */
@interface ETLayoutItem (Scrollable)

- (BOOL) hasVerticalScroller;
- (void) setHasVerticalScroller: (BOOL)scroll;
- (BOOL) hasHorizontalScroller;
- (void) setHasHorizontalScroller: (BOOL)scroll;
- (BOOL) hasAnyVisibleScroller;
- (BOOL) isScrollViewShown; // TODO: Remove

- (BOOL) isScrollable;
- (void) setScrollable: (BOOL)show;

/* Framework Private */

- (void) updateScrollableAreaItemVisibility;

@end
