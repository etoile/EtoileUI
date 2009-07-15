/** <title>ETScrollableAreaItem</title>

	<abstract>ETDecoratorItem subclass which makes content scrollable.</abstract>

	Copyright (C) 2009 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  March 2009
	License:  Modified BSD  (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <EtoileUI/ETDecoratorItem.h>
#import <EtoileUI/ETView.h>

/** A decorator which can be used to make content scrollable.

With the AppKit widget backend, the underlying view is an NSScrollView object. */
@interface ETScrollableAreaItem : ETDecoratorItem

- (NSRect) visibleRect;
- (NSRect) visibleContentRect;

- (BOOL) hasVerticalScroller;
- (void) setHasVerticalScroller: (BOOL)scroll;
- (BOOL) hasHorizontalScroller;
- (void) setHasHorizontalScroller: (BOOL)scroll;

// TODO: May be be nicer to override -contentRect in ETScrollableAreaItem 
// so that the content rect origin reflects the current scroll position.

@end

/* Private stuff (legacy to be eliminated) */

@interface ETScrollView : ETView
{
	NSScrollView *_mainView;
}

- (id) initWithMainView: (id)scrollView layoutItem: (ETLayoutItem *)item;

@end
