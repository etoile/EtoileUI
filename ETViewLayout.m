//
//  ETViewLayout.m
//  FlowAutolayoutExample
//
//  Created by Quentin Mathé on 26/12/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "ETViewLayout.h"
#import "ETViewLayoutLine.h"
#import "ETContainer.h"
#import "GNUstep.h"

@interface ETContainer (PackageVisibility)
- (NSArray *) layoutItems;
- (void) cacheLayoutItems: (NSArray *)cache;
- (NSArray *) layoutItemCache;
- (int) checkSourceProtocolConformance;
@end

/*
 * Private methods
 */

@interface ETViewLayout (Private)

- (void) renderInContainer: (ETContainer *)container;
- (NSArray *) layoutItemsFromFlatSource;
- (NSArray *) layoutItemsFromTreeSource;

/* Utility methods */
- (NSRect) lineLayoutRectForViewAtIndex: (int)index;
- (NSPoint) locationForViewAtIndex: (int)index;
- (NSView *) viewIndexAtPoint: (NSPoint)location;
- (NSRange) viewRangeForLineLayoutWithIndex: (int)lineIndex;

@end

/*
 * Main implementation
 */

@implementation ETViewLayout

- (id) init
{
	self = [super init];
    
	if (self != nil)
	{
		_container = nil;
		_delegate = nil;
		_layoutSizeCustomized = NO;
		_maxSizeLayout = NO;
    }
    
	return self;
}

- (void) dealloc
{
	[super dealloc];
}

- (void) setContainer: (ETContainer *)newContainer
{
	// NOTE: The container is our owner and retains us... A simple assignement 
	// allows to avoid retain cycle.
	_container = newContainer;
}

/** Returns the view where the layout happens (by computing location of a subview series). */
- (ETContainer *) container;
{
	return _container;
}


- (BOOL) isAllContentVisible
{
	return NO;
}

- (void) adjustLayoutSizeToSizeOfContainer: (ETContainer *)container
{

}

- (void) adjustLayoutSizeToContentSize
{
	if ([self isAllContentVisible])
		return;
	
	if (_maxSizeLayout == NO)
	{
		_maxSizeLayout = YES;
		[self render];
		_maxSizeLayout = NO;
	}
	else
	{
		[self render];
	}
}

/** By default layout size is equal to container frame size. When the container 
	uses a scroll view, layout size is set to the max size computed for the 
	content. Whether the size is computed in horizontal, vertical direction
	or both depends of the container scroller settings, the layout kind and 
	finally layout settings. 
	If you call -setUsesCustomLayoutSize:, the layout size won't be adjusted anymore by
	layout and container together until you delegate it again by calling
	-setUsesCustomLayoutSize: with NO as parameter. */ 
- (void) setUsesCustomLayoutSize: (BOOL)flag
{
	_layoutSizeCustomized = flag;
}

- (BOOL) usesCustomLayoutSize
{
	return _layoutSizeCustomized;
}

- (void) setLayoutSize: (NSSize)size
{
	_layoutSize = size;
}

- (NSSize) layoutSize
{
	return _layoutSize;
}

- (void) setContentSizeLayout: (BOOL)flag
{
	_maxSizeLayout = flag;
}

- (BOOL) isContentSizeLayout
{
	return _maxSizeLayout;
}

- (void) setDelegate: (id)delegate
{
	_delegate = delegate;
}

- (id) delegate
{
	return _delegate;
}

- (NSArray *) layoutItemsFromSource
{
	switch ([[self container] checkSourceProtocolConformance])
	{
		case 1:
			NSLog(@"Will -layoutItemsFromFlatSource");
			return [self layoutItemsFromFlatSource];
			break;
		case 2:
			NSLog(@"Will -layoutItemsFromTreeSource");
			return [self layoutItemsFromTreeSource];
			break;
		default:
			NSLog(@"WARNING: source protocol is incorrectly supported by %@.", [[self container] source]);
	}
	
	return nil;
}

- (NSArray *) layoutItemsFromFlatSource
{
	NSMutableArray *itemsFromSource = [NSMutableArray array];
	ETLayoutItem *layoutItem = nil;
	int nbOfItems = [[[self container] source] numberOfItemsInContainer: [self container]];
	
	for (int i = 0; i < nbOfItems; i++)
	{
		layoutItem = [[[self container] source] itemAtIndex: i inContainer: [self container]];
		[itemsFromSource addObject: layoutItem];
	}
	
	return itemsFromSource;
}

- (NSArray *) layoutItemsFromTreeSource
{
	return nil;
}

- (void) render
{
	NSArray *itemDisplayViews = [[[self container] layoutItemCache] valueForKey: @"displayView"];
	NSArray *itemsForRendering = nil;

	/* We remove the display views of cached layout items (they are in current
	   in current implementation the displayed layout items). Note they may be 
	   invisible by being located outside of container bounds. */
	NSLog(@"Remove views of layout items currently displayed from their container");
	[itemDisplayViews makeObjectsPerformSelector: @selector(removeFromSuperview)];
	
	if ([[self container] source] != nil) /* Make layout with items provided by source */
	{
		if ([[[self container] layoutItems] count] > 0)
		{
			NSLog(@"Update layout from source, yet %d items owned by the "
				@"container already exists, it may be better to remove them "
				@"before setting source.", [[[self container] layoutItems] count]);
		}
		itemsForRendering = [self layoutItemsFromSource];
	}
	else /* Make layout with items directly provided by container */
	{
		NSLog(@"No source avaible, will make layout directly");
		itemsForRendering = [[self container] layoutItems];
	}	
	
	[[self container] cacheLayoutItems: itemsForRendering];
	
	/* Let layout delegate overrides default layout items rendering */
	if ([_delegate respondsToSelector: @selector(layout:renderLayoutItem:)])
	{
		NSEnumerator *e = [itemsForRendering objectEnumerator];
		ETLayoutItem *item = nil;
		
		while ((item = [e nextObject]) != nil)
		{
			[_delegate layout: self renderLayoutItem: item];
		}
	}
	else
	{
		[itemsForRendering makeObjectsPerformSelector: @selector(render)];
	}
	
	[self renderWithLayoutItems: itemsForRendering inContainer: [self container]];
}

/** You can adjust the layout size by passing a different container than the one 
	were the layout will be ultimately rendered. Also by passing nil, you can 
	let the layout computes its maximum size associated with current container 
	content. */

/** Run the layout computation which assigns a location in the view container
    to each view added to the flow layout manager. */
- (void) renderWithLayoutItems: (NSArray *)items inContainer: (ETContainer *)container
{
	NSArray *itemViews = [items valueForKey: @"displayView"];
	NSArray *layoutModel = nil;
	
	layoutModel = [self layoutModelForViews: itemViews inContainer: container];
	/* Now computes the location of every views by relying on the line by line 
	   decomposition already made. */
	[self computeViewLocationsForLayoutModel: layoutModel inContainer: container];
	
	/* Don't forget to remove existing display view if we switch from a layout 
	   which reuses a native AppKit control like table layout. */
	[container setDisplayView: nil];
	
	// TODO: Optimize by computing set intersection of visible and unvisible item display views
	NSLog(@"Remove views of next layout items to be displayed from their superview");
	[itemViews makeObjectsPerformSelector: @selector(removeFromSuperview)];
	
	NSMutableArray *visibleItemViews = [NSMutableArray array];
	NSEnumerator  *e = [layoutModel objectEnumerator];
	ETViewLayoutLine *line = nil;
	
	/* Flatten layout model by putting all views in a single array */
	while ((line = [e nextObject]) != nil)
	{
		[visibleItemViews addObjectsFromArray: [line views]];
	}
	
	e = [visibleItemViews objectEnumerator];
	NSView *visibleItemView = nil;
	
	while ((visibleItemView = [e nextObject]) != nil)
	{
		if ([[container subviews] containsObject: visibleItemView] == NO)
			[container addSubview: visibleItemView];
	}
}

/** Renders a collection of items by requesting lazily to source a subset of 
	them to be displayed. Parameter source must implement ETContainerSource
	informal protocol in a valid way as described in -[ETContainer setSource:].
	Take note you can pass nil for container as a mean to compute the whole
	layout size which can be then be retrieved by calling -layoutSize.
	This method is usually called by ETContainer and you should rarely need to
	do it by yourself. If you want to update the layout, just uses 
	-[ETContainer updateLayout]. */
- (void) renderWithSource: (id)source inContainer: (ETContainer *)container
{

}

/* 
 * Line-based layouts methods 
 */

/** Overrides this method to generate a layout line based on the container 
    constraints. Usual container constraints are size, vertical and horizontal 
	scrollers visibility. */
- (ETViewLayoutLine *) layoutLineForViews: (NSArray *)views inContainer: (ETContainer *)viewContainer
{
	return nil;
}

/** Overrides this method to generate a layout model based on the container 
    constraints. Usual container constraints are size, vertical and horizontal 
	scrollers visibility.
	A layout model is commonly an array of layouts lines where their position 
	indicates in which order these layout lines should be displayed. It's up to 
	you if you want to create a layout model with a more elaborated ordering 
	and rendering semantic. Finally the layout model is interpreted by 
	-computeViewLocationsForLayoutModel:inContainer:. */
- (NSArray *) layoutModelForViews: (NSArray *)views inContainer: (ETContainer *)viewContainer
{
	return nil;
}

/** Overrides this method to interpretate the layout model and compute view 
	locations accordingly. Most of the work of layout process happens in this
	method. */
- (void) computeViewLocationsForLayoutModel: (NSArray *)layoutModel inContainer: (ETContainer *)container
{

}

/* 
 * Utility methods
 */
 
- (NSRect) lineLayoutRectForViewAtIndex: (int)index { return NSZeroRect; }

- (NSPoint) locationForViewAtIndex: (int)index
{
    return NSZeroPoint;
}

- (NSView *) viewIndexAtPoint: (NSPoint)location
{
    return nil;
}

//- (NSRange) viewRangeForLineLayout:
- (NSRange) viewRangeForLineLayoutWithIndex: (int)lineIndex
{
    return NSMakeRange(0, 0);
}

@end
