/*  <title>ETViewLayout</title>

	ETViewLayout.m
	
	<abstract>Description forthcoming.</abstract>
 
	Copyright (C) 2007 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  May 2007
 
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
 
#import "ETViewLayout.h"
#import "ETViewLayoutLine.h"
#import "ETContainer.h"
#import "ETLayoutItemGroup.h"
#import "NSView+Etoile.h"
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

/* Factory Method */

- (id) layoutPrototype
{
	return [self copy];
}

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
	/* Neither container and delegate have to be retained. For container, only
	   because it retains us and is in charge of us
	   For _displayViewPrototype, it's up to subclasses to manage it. */
	[super dealloc];
}

- (id) copyWithZone: (NSZone *)zone
{
	ETViewLayout *proto = [[[self class] alloc] init];
	
	proto->_container = nil;
	proto->_delegate = nil;
	proto->_displayViewPrototype = [_displayViewPrototype copy];
	
	proto->_layoutSize = _layoutSize;
	proto->_layoutSizeCustomized = _layoutSizeCustomized;
	proto->_maxSizeLayout  = _maxSizeLayout;
	
	return AUTORELEASE(proto);
}

- (void) setContainer: (ETContainer *)newContainer
{
	/* Disconnect layout from existing container */
	// Nothing 
	
	/* Connect layout to new container */
	// NOTE: The container is our owner and retains us... A simple assignement 
	// allows to avoid retain cycle.
	_container = newContainer;
	[[_container layoutItemCache] makeObjectsPerformSelector: @selector(restoreDefaultFrame)];
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

/* Item Sizing Accessors */

- (void) setUsesConstrainedItemSize: (BOOL)flag
{
	_itemSizeConstrained = flag;
	if ([self verticallyConstrainedItemSize] == NO
	 && [self horizontallyConstrainedItemSize] == NO)
	{
		[self setVerticallyConstrainedItemSize: YES];
		[self setHorizontallyConstrainedItemSize: YES];
	}
}

- (BOOL) usesContrainedItemSize
{
	return _itemSizeConstrained;
}

- (void) setConstrainedItemSize: (NSSize)size
{
	_itemSize = size;
}

- (NSSize) constrainedItemSize
{
	return _itemSize;
}

- (void) setVerticallyConstrainedItemSize: (BOOL)flag
{
	_itemSizeConstrainedV = flag;
}

- (BOOL) verticallyConstrainedItemSize
{
	return _itemSizeConstrainedV;
}

- (void) setHorizontallyConstrainedItemSize: (BOOL)flag
{
	_itemSizeConstrainedH = flag;
}

- (BOOL) horizontallyConstrainedItemSize
{
	return _itemSizeConstrainedH;
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
	NSMutableArray *itemsFromSource = [NSMutableArray array];
	ETLayoutItem *layoutItem = nil;
	ETContainer *container = [self container];
	NSString *path = [container path];
	int nbOfItems = [[container source] numberOfItemsAtPath: path inContainer: container];
	
	NSLog(@"-layoutItemsFromTreeSource in %@", self);

	for (int i = 0; i < nbOfItems; i++)
	{
		NSString *subpath = nil;
		
		subpath = [path stringByAppendingPathComponent: [NSString stringWithFormat: @"%d", i]];
		layoutItem = [[container source] itemAtPath: subpath inContainer: container];
		if ([layoutItem isKindOfClass: [ETLayoutItemGroup class]])
		{
			//[[layoutItem container] setSource: [container source]];
			[(ETContainer *)[layoutItem view] setPath: subpath];
		}
		[itemsFromSource addObject: layoutItem];
	}
	
	return itemsFromSource;
}

- (void) render
{
	NSArray *itemDisplayViews = [[[self container] layoutItemCache] valueForKey: @"displayView"];
	NSArray *itemsForRendering = nil;

	/* We remove the display views of cached layout items (they are in current
	   in current implementation the displayed layout items). Note they may be 
	   invisible by being located outside of container bounds. */
//#ifdef REMOVE_FROM_SUPERVIEW_BEFORE_LAYOUT
	//NSLog(@"Remove views of layout items currently displayed from their container");
	[itemDisplayViews makeObjectsPerformSelector: @selector(removeFromSuperview)];
//#endif

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
		//NSLog(@"No source avaible, will make layout directly");
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
			[_delegate layout: self renderLayoutItem: item]; // FIXME: Use proper delegate syntax
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
	
	float scale = [container itemScaleFactor];
	[self resizeLayoutItems: items toScaleFactor: scale];
	
	layoutModel = [self layoutModelForViews: itemViews inContainer: container];
	/* Now computes the location of every views by relying on the line by line 
	   decomposition already made. */
	[self computeViewLocationsForLayoutModel: layoutModel inContainer: container];
		
	/* Don't forget to remove existing display view if we switch from a layout 
	   which reuses a native AppKit control like table layout. */
	[container setDisplayView: nil];
	
	// TODO: Optimize by computing set intersection of visible and unvisible item display views
	//NSLog(@"Remove views of next layout items to be displayed from their superview");
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

- (void) resizeLayoutItems: (NSArray *)items toScaleFactor: (float)factor
{
	NSEnumerator *e = [items objectEnumerator];
	ETLayoutItem *item = nil;
	
	while ((item = [e nextObject]) != nil)
	{
		NSRect unscaledFrame = [item defaultFrame];
		
		/* Apply item size constraint */
		if ([self usesContrainedItemSize])
		{
			if ([self verticallyConstrainedItemSize] 
			 && [self horizontallyConstrainedItemSize])
			{
				unscaledFrame.size = [self constrainedItemSize];
			}
			else if ([self verticallyConstrainedItemSize])
			{
				//unscaledFrame.size.height = [self constrainedItemSize];
				
			}
			else if ([self horizontallyConstrainedItemSize])
			{
			
			}
		}
		
		/* Rescale */
		if ([item view] != nil)
		{
			[[item view] setFrame: ETScaleRect(unscaledFrame, factor)];
			//NSLog(@"Scale %@ to %@", NSStringFromRect(unscaledFrame), 
			//	NSStringFromRect(ETScaleRect(unscaledFrame, factor)));
		}

		if ([item view] == nil)
			NSLog(@"% can't be rescaled because it has no view");
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
	ETViewLayoutLine *line = [self layoutLineForViews: views inContainer: viewContainer];
	
	if (line != nil)
		return [NSArray arrayWithObject: line];

	return nil;
}

/** Overrides this method to interpretate the layout model and compute view 
	locations accordingly. Most of the work of layout process happens in this
	method. */
- (void) computeViewLocationsForLayoutModel: (NSArray *)layoutModel inContainer: (ETContainer *)container
{

}

/* Wrapping Existing View */

- (void) setDisplayViewPrototype: (NSView *)protoView
{
	ASSIGN(_displayViewPrototype, protoView);
}

- (NSView *) displayViewPrototype
{
	return _displayViewPrototype;
}

/* 
 * Utility methods
 */
 
- (NSRect) lineLayoutRectForViewAtIndex: (int)index { return NSZeroRect; }

- (NSPoint) locationForViewAtIndex: (int)index
{
    return NSZeroPoint;
}

/** Returns item for which location is inside its display area. location must 
	be expressed in the coordinates of the container presently associated with 
	layout. */
- (ETLayoutItem *) itemAtLocation: (NSPoint)location
{
	NSArray *layoutItems = [[self container] layoutItemCache];
	NSEnumerator *e = [layoutItems objectEnumerator];
	ETLayoutItem *item = nil;
	
	while ((item = [e nextObject]) != nil)
	{
		if ([item displayView] != nil)
		{
			if (NSPointInRect(location, [[item displayView] frame]))
				return item;
		}
		else /* Layout items uses no display view */
		{
			// FIXME: Implement
		}
	}
	
	return nil;
}

- (NSRect) displayRectOfItem: (ETLayoutItem *)item
{
	if ([item displayView] != nil)
	{
		return [[item displayView] frame];
	}
	else
	{
		// FIXME: Take in account any item decorations drawn by layout directly
		return NSZeroRect;
	}
}

//- (NSRange) viewRangeForLineLayout:
- (NSRange) viewRangeForLineLayoutWithIndex: (int)lineIndex
{
    return NSMakeRange(0, 0);
}

@end
