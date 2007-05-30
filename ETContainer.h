//
//  ETContainer.h
//  FlowAutolayoutExample
//
//  Created by Quentin Mathé on 26/12/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

@class ETLayoutItem, ETViewLayout;


// ETComponentView
@interface ETContainer : NSView 
{
	NSMutableArray *_layoutItems;
	ETViewLayout *_containerLayout;
	NSView *_displayView;
	NSScrollView *_scrollView;
	
	id _dataSource;
}

- (id) initWithFrame: (NSRect)rect views: (NSArray *)views;

- (void) updateLayout;

- (ETViewLayout *) layout;
- (void) setLayout: (ETViewLayout *)layout;

- (NSView *) displayView;

- (id) source;
- (void) setSource: (id)source;

- (BOOL) letsLayoutControlsScrollerVisibility;
- (void) setLetsLayoutControlsScrollerVisibility: (BOOL)layoutControl;
- (BOOL) hasVerticalScroller;
- (void) setHasVerticalScroller: (BOOL)scroll;
- (BOOL) hasHorizontalScroller;
- (void) setHasHorizontalScroller: (BOOL)scroll;

/*
- (ETLayoutAlignment) layoutAlignment;
- (void) setLayoutAlignment: (ETLayoutAlignment)alignment;

- (ETLayoutOverflowStyle) overflowStyle;
- (void) setOverflowStyle: (ETLayoutOverflowStyle);
*/

- (void) addItem: (ETLayoutItem *)item;
- (void) removeItem: (ETLayoutItem *)item;
- (void) removeItemAtIndex: (int)index;
- (ETLayoutItem *) itemAtIndex: (int)index;
- (void) addItems: (NSArray *)items;
- (void) removeItems: (NSArray *)items;
- (void) removeAllItems;

- (void) addView: (NSView *)view;
- (void) removeView: (NSView *)view;
- (void) removeViewAtIndex: (int)index;
- (NSView *) viewAtIndex: (int)index;
- (void) addViews: (NSArray *)views;
- (void) removeViews: (NSArray *)views;

/*- (void) addView: (NSView *)view withIdentifier: (NSString *)identifier;
- (void) removeViewForIdentifier:(NSString *)identifier;
- (NSView *) viewForIdentifier: (NSString *)identifier;*/

// Private use
- (void) setDisplayView: (NSView *)view;
- (BOOL) hasScrollView;
- (void) setHasScrollView: (BOOL)scroll;

@end

@interface ETContainer (ETContainerSource)

/* Basic index retrieval */
- (int) numberOfItemsInContainer: (ETContainer *)container;
- (ETLayoutItem *) itemAtIndex: (int)index inContainer: (ETContainer *)container;

/* Key and index path retrieval useful with containers displaying tree structure */
- (int) numberOfItemsAtPath: (NSString *)keyPath inContainer: (ETContainer *)container;
- (ETLayoutItem *) itemAtPath: (NSString *)keyPath inContainer: (ETContainer *)container;

/* Extra infos */
- (NSArray *) displayedItemPropertiesInContainer: (ETContainer *)container;
- (int) firstVisibleItemInContainer: (ETContainer *)container;
- (int) lastVisibleItemInContainer: (ETContainer *)container;

@end
