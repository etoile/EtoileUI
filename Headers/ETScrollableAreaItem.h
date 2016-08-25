/** <title>ETScrollableAreaItem</title>

	<abstract>ETDecoratorItem subclass which makes content scrollable.</abstract>

	Copyright (C) 2009 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  March 2009
	License:  Modified BSD  (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <EtoileUI/ETDecoratorItem.h>

@class COObjectGraphContext;
// FIXME: Don't expose NSScrollView in the public API.
@class NSScrollView;

/** A decorator which can be used to make content scrollable.

With the AppKit widget backend, the underlying view is an NSScrollView object.

You must not alter the underlying NSScrollView object with -setContentView:.

Non-flipped coordinates are untested with ETScrollableAreaItem i.e. when the 
decorated item returns NO to -isFlipped. */
@interface ETScrollableAreaItem : ETDecoratorItem
{
	@private
	NSUInteger _oldDecoratedItemAutoresizingMask; /* Autoresizing mask to restore */
	BOOL _ensuresContentFillsVisibleArea;
	id _deserializedScrollView;
}

+ (ETScrollableAreaItem *) itemWithScrollView: (NSScrollView *)scrollView
                           objectGraphContext: (COObjectGraphContext *)aContext;

- (instancetype) initWithScrollView: (NSScrollView *)aScrollView
       objectGraphContext: (COObjectGraphContext *)aContext NS_DESIGNATED_INITIALIZER;

@property (nonatomic, readonly) NSRect visibleRect;
@property (nonatomic, readonly) NSRect visibleContentRect;

@property (nonatomic) BOOL hasVerticalScroller;
@property (nonatomic) BOOL hasHorizontalScroller;

@property (nonatomic) BOOL ensuresContentFillsVisibleArea;

// TODO: May be nicer to override -contentRect in ETScrollableAreaItem so that 
// the content rect origin reflects the current scroll position.

/**  @taskunit Framework Private */

@property (nonatomic, readonly) NSScrollView *scrollView;

@end
