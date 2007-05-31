//
//  ETContainer.h
//  FlowAutolayoutExample
//
//  Created by Quentin Mathé on 26/12/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

@class ETLayoutItem, ETViewLayout, ETLayer, ETLayoutGroupItem;

/** Forwarding Chain 

	View returned by -[ETLayoutItem view] --> ETLayer (optional) -
	-> ETContainer --> ETLayout --> View returned by -[ETLayout displayView]
	
	By default, the forwarding chain is broken is two separate chains:
	
	-[ETLayoutItem view] --> ETLayer (optional) -> ETContainer
	
	and
	
	ETContainer --> ETLayout --> -[ETLayout displayView]
	
	The possibility to use the first separate chain and the whole one is still
	under evaluation.
	
 */


// ETComponentView
@interface ETContainer : NSView 
{
	/* Stores items when no source is used. May stores layers when no source is 
	   used, this is not yet decided. */
	NSMutableArray *_layoutItems;
	ETViewLayout *_containerLayout;
	NSView *_displayView;
	NSScrollView *_scrollView;
	
	id _dataSource;

	/* Used by ETViewLayout to know which items are displayed whether the 
	   container uses a source or simple provides items directly. */
	NSMutableArray *_layoutItemCache;
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

/* Primary methods to interact with layout item and container
   NOTE: Throw an exception when a source is used */

- (void) addItem: (ETLayoutItem *)item;
- (void) insertItem: (ETLayoutItem *)item atIndex: (int)index;
- (void) removeItem: (ETLayoutItem *)item;
- (void) removeItemAtIndex: (int)index;
- (ETLayoutItem *) itemAtIndex: (int)index;
- (void) addItems: (NSArray *)items;
- (void) removeItems: (NSArray *)items;
- (void) removeAllItems;

/* Facility Methods For View-based Layout Items
   NOTE: Throw an exception when a source is used */
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

/* Groups and Stacks */

/*- (ETLayoutGroupItem *) groupAllItems;
- (ETLayoutGroupItem *) groupItems: (NSArray *)items;
- (ETLayoutGroupItem *) ungroupItems: (ETLayoutGroupItem *)itemGroup;*/

// NOTE: Not sure it is worth to have these methods since we can stack a group
// by using ETLayoutGroupItem API
/*- (ETLayoutGroupItem *) stackAllItems;
- (ETLayoutGroupItem *) stackItems: (NSArray *)items;
- (ETLayoutGroupItem *) unstackItems: (ETLayoutGroupItem *)itemGroup;*/

/* Layers */

- (void) addLayer: (ETLayoutItem *)item;
- (void) insertLayer: (ETLayoutItem *)item atIndex: (int)layerIndex;
- (void) insertLayer: (ETLayoutItem *)item atZIndex: (int)z;
- (void) removeLayer: (ETLayoutItem *)item;
- (void) removeLayerAtIndex: (int)layerIndex;

/* Rendering Chain */

- (void) render;

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

// TODO: Extend the informal protocol to propogate group/ungroup actions in 
// they can be properly reflected on model side.

@end
