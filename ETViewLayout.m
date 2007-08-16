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
 
#import <EtoileUI/ETViewLayout.h>
#import <EtoileUI/ETViewLayoutLine.h>
#import <EtoileUI/ETContainer.h>
#import <EtoileUI/ETLayoutItemGroup.h>
#import <EtoileUI/NSView+Etoile.h>
#import <EtoileUI/GNUstep.h>

@interface ETContainer (PackageVisibility)
- (NSArray *) layoutItems;
- (void) cacheLayoutItems: (NSArray *)cache;
- (NSArray *) layoutItemCache;
- (int) checkSourceProtocolConformance;
- (NSArray *) visibleItems;
- (void) setVisibleItems: (NSArray *)visibleItems;
- (BOOL) isScrollViewShown;
- (void) setShowsScrollView: (BOOL)scroll;
@end

/*
 * Private methods
 */

@interface ETViewLayout (Private)

- (NSArray *) layoutItemsFromFlatSource;
- (NSArray *) layoutItemsFromTreeSource;

- (void) adjustLayoutSizeToSizeOfContainer: (ETContainer *)container;

/* Utility methods */
- (NSRect) lineLayoutRectForItemAtIndex: (int)index;
- (ETLayoutItem *) itemAtLocation: (NSPoint)location;

@end

/*
 * Main implementation
 */

@implementation ETViewLayout

/* Factory Method */

/** Returns a prototype which is a receiver copy you can freely assign to 
	another container. Because a layout can be bound to only one container, 
	this method is useful for sharing a customized layout between several 
	containers without having to recreate a new instance from scratch each
	time. */
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
		_displayViewPrototype = nil;
		_isLayouting = NO;
		_layoutSize = NSMakeSize(200, 200); /* Dummy value */
		_layoutSizeCustomized = NO;
		_maxSizeLayout = NO;
		_itemSize = NSMakeSize(256, 256); /* Default max item size */
		/* By default both width and height must be equal or inferior to related _itemSize values */
		_itemSizeConstraintStyle = ETSizeConstraintStyleVerticalHorizontal;
    }
    
	return self;
}

- (void) dealloc
{
	/* Neither container and delegate have to be retained. For container, only
	   because it retains us and is in charge of us.
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
	
	proto->_itemSizeConstraintStyle = _itemSizeConstraintStyle;
	
	return AUTORELEASE(proto);
}

/** Sets the view where the layout should happen. 
	When a container is set, on next layout update the receiver will 
	arrange container layout items in a specific style and order.
	newContainer isn't retained, but it is expected newContainer has already
	retained the receiver. */
- (void) setContainer: (ETContainer *)newContainer
{
	/* Disconnect layout from existing container */
	// Nothing 
	
	/* Connect layout to new container */
	// NOTE: Avoids retain cycle by weak referencing the container.
	_container = newContainer;
	[[_container layoutItemCache] makeObjectsPerformSelector: @selector(restoreDefaultFrame)];
}

/** Returns the view where the layout happens (by computing locations of a layout item series). */
- (ETContainer *) container;
{
	return _container;
}

/** Returns YES if all layout items are visible in the bounds of the related 
	container once the layout has been computed, otherwise returns NO when
	the layout has run out of space.
	Whether all items are visible depends of the layout itself and also whether
	the container is embedded in a scroll view because in such case the 
	container size is altered. */
- (BOOL) isAllContentVisible
{
	int nbOfItems = [[[self container] layoutItemCache] count];
	
	return [[[self container] visibleItems] count] == nbOfItems;
}

/** This methods triggers layout render, so you must not call it inside any
	rendering methods to avoid any reentrancy issues. 
	There is no need to use -updateLayout or -render, the method does any 
	necessary rendering and avoids it when possible. 
	You can use this method to get an idea of the size of a layout even when
	no container is bound to this layout, just pass an arbitrary container in 
	parameter. Passing nil is equivalent to calling 
	-adjustLayoutSizeToContentSize. */
- (void) adjustLayoutSizeToSizeOfContainer: (ETContainer *)container
{
	BOOL needsRender = YES;
	
	if ([self isAllContentVisible])
		needsRender = NO;
	
	[self setLayoutSize: [container frame].size];
	
	if (needsRender)
		[self render];
}

/** This methods triggers layout render, so you must not call it inside any
	rendering methods to avoid any reentrancy issues. 
	There is no need to use -updateLayout or -render, the method does any 
	necessary rendering and avoids it when possible.*/
- (void) adjustLayoutSizeToContentSize
{
	/* May be the layout size is already sufficient to display all items */
	if ([self isAllContentVisible])
		return;
	
	// FIXME: Evaluate the interest of the first branch...
	if ([self isContentSizeLayout] == NO)
	{
		[self setContentSizeLayout: YES];
		[self render];
		[self setContentSizeLayout: NO];
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

/** Layout size can be set directly only if -usesCustomLayoutSize returns
	YES.
	In this case, you can restrict layout size to your personal needs by 
	calling -setLayoutSize: and only then -render. */
- (void) setLayoutSize: (NSSize)size
{
	//NSLog(@"-setLayoutSize");
	_layoutSize = size;
}

- (NSSize) layoutSize
{
	return _layoutSize;
}

- (void) setContentSizeLayout: (BOOL)flag
{
	//NSLog(@"-setContentSizeLayout");
	_maxSizeLayout = flag;
}

- (BOOL) isContentSizeLayout
{
	if ([[self container] isScrollViewShown])
		return YES;

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

- (void) setItemSizeConstraintStyle: (ETSizeConstraintStyle)constraint
{
	_itemSizeConstraintStyle = constraint;
}

- (ETSizeConstraintStyle) itemSizeConstraintStyle
{
	return _itemSizeConstraintStyle;
}

- (void) setConstrainedItemSize: (NSSize)size
{
	_itemSize = size;
}

- (NSSize) constrainedItemSize
{
	return _itemSize;
}

- (NSArray *) layoutItemsFromSource
{
	switch ([[self container] checkSourceProtocolConformance])
	{
		case 1:
			//NSLog(@"Will -layoutItemsFromFlatSource");
			return [self layoutItemsFromFlatSource];
			break;
		case 2:
			//NSLog(@"Will -layoutItemsFromTreeSource");
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

/** Returns whether the layout object is currently computing and rendering its 
	layout right now or not.
	You must call this method in your code before calling any Layouting section
	methods. If YES is returned, don't call the method you want to and wait a 
	bit to give another try to -isRendering. When NO is returned, you are free
	to call any Layouting related methods. */
- (BOOL) isRendering
{
	return _isLayouting;
}

- (void) render
{
	/* Prevent reentrancy. In a threaded environment, it isn't perfectly safe 
	   because _isLayouting test and _isLayouting assignement doesn't occur in
	   an atomic way. */
	if (_isLayouting)
	{
		NSLog(@"WARNING: Trying to reenter -render when the layout is already getting updated.");
		return;
	}
	else
	{
		_isLayouting = YES;
	}
	
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
	
	/* When the number of layout items is zero and doesn't vary, no layout 
	   update is necessary */
	if ([[[self container] layoutItemCache] count] == 0 && [itemsForRendering count] == 0)
	{
		_isLayouting = NO;
		return;
	}
	
	[[self container] cacheLayoutItems: itemsForRendering];
	
	/* Let layout delegate overrides default layout items rendering */
	if ([_delegate respondsToSelector: @selector(layout:applyLayoutItem:)])
	{
		NSEnumerator *e = [itemsForRendering objectEnumerator];
		ETLayoutItem *item = nil;
		
		while ((item = [e nextObject]) != nil)
		{
			//[_delegate layout: self applyLayoutItem: item];
			//[_delegate layout: self renderLayoutItem: item]; // FIXME: Use proper delegate syntax
		}
	}
	else
	{
		[itemsForRendering makeObjectsPerformSelector: @selector(apply:) withObject: nil];
	}
	
	_isLayouting = NO;
	/* We always set the layout size which should be used to compute the 
	   layout unless a custom layout has been set by calling -setLayoutSize:
	   before -render. */
	if ([self usesCustomLayoutSize] == NO)
	{
		if ([[self container] isScrollViewShown])
		{
			/* Better to request the visible rect than the container frame 
			   which might be severely altered by the previouly set layout. */
			[self setLayoutSize: [[[self container] scrollView] documentVisibleRect].size];
		}
		else /* Using content layout size without scroll view is supported */
		{
			[self setLayoutSize: [[self container] frame].size];
		}
	}
	[self renderWithLayoutItems: itemsForRendering];
}

/** You can adjust the layout size by passing a different container than the one 
	were the layout will be ultimately rendered. Also by passing nil, you can 
	let the layout computes its maximum size associated with current container 
	content. */

/** Run the layout computation which assigns a location in the view container
    to each view added to the flow layout manager. */
- (void) renderWithLayoutItems: (NSArray *)items
{	
	/* Prevent reentrancy. In a threaded environment, it isn't perfectly safe 
	   because _isLayouting test and _isLayouting assignement doesn't occur in
	   an atomic way. */
	if (_isLayouting)
	{
		NSLog(@"WARNING: Trying to reenter -renderWithLayoutItems: when the layout is already getting updated.");
		return;
	}
	else
	{
		_isLayouting = YES;
	}
	
	ETLog(@"Render layout items: %@", items);
	
	NSArray *layoutModel = nil;
	
	float scale = [[self container] itemScaleFactor];
	[self resizeLayoutItems: items toScaleFactor: scale];
	
	layoutModel = [self layoutModelForLayoutItems: items];
	/* Now computes the location of every views by relying on the line by line 
	   decomposition already made. */
	[self computeLayoutItemLocationsForLayoutModel: layoutModel inContainer: [self container]];
	
	// TODO: Optimize by computing set intersection of visible and unvisible item display views
	/*NSLog(@"Remove views %@ of next layout items to be displayed from their superview", itemViews);
	[itemViews makeObjectsPerformSelector: @selector(removeFromSuperview)];
			NSLog(@"Before %@", NSStringFromRect([[self container] frame]));*/
	[[self container] setVisibleItems: [NSArray array]];
	/* Adjust container size when it is embedded in a scroll view */
	if ([[self container] isScrollViewShown])
	{
		// NOTE: For this assertion check -[ETContainer setScrollView:] 
		NSAssert([self isContentSizeLayout] == YES, 
			@"Any layout done in a scroll view must be based on content size");
		
		[[self container] setFrameSize: [self layoutSize]];
		NSLog(@"Layout size is %@ with container size %@ and clip view size %@", 
			NSStringFromSize([self layoutSize]), 
			NSStringFromSize([[self container] frame].size), 
			NSStringFromSize([[[self container] scrollView] contentSize]));
		
		//[[[self container] scrollView] reflectScrolledClipView: [[[self container] scrollView] clipView]];
	}
	
	NSMutableArray *visibleItems = [NSMutableArray array];
	NSEnumerator  *e = [layoutModel objectEnumerator];
	ETViewLayoutLine *line = nil;
	
	/* Flatten layout model by putting all views in a single array */
	while ((line = [e nextObject]) != nil)
	{
		[visibleItems addObjectsFromArray: [line items]];
	}
	
	[[self container] setVisibleItems: visibleItems];
	
	_isLayouting = NO;
}

- (void) resizeLayoutItems: (NSArray *)items toScaleFactor: (float)factor
{
	NSEnumerator *e = [items objectEnumerator];
	ETLayoutItem *item = nil;
	
	while ((item = [e nextObject]) != nil)
	{
		/* Scaling is always computed from item default frame rather than
		   current item view size (or  item display area size) in order to
		   avoid rounding error that would increase on each scale change 
		   because of size width and height expressed as float. */
		NSRect itemFrame = ETScaleRect([item defaultFrame], factor);
		
		/* Apply item size constraint */
		if (itemFrame.size.width > [self constrainedItemSize].width
		 || itemFrame.size.height > [self constrainedItemSize].height)
		{ 
			BOOL isVerticalResize = NO;
			
			if ([self itemSizeConstraintStyle] == ETSizeConstraintStyleVerticalHorizontal)
			{
				if (itemFrame.size.height > itemFrame.size.width)
				{
					isVerticalResize = YES;
				}
				else /* Horizontal resize */
				{
					isVerticalResize = NO;
				}
			}
			else if ([self itemSizeConstraintStyle] == ETSizeConstraintStyleVertical
			      && itemFrame.size.height > [self constrainedItemSize].height)
			{
				isVerticalResize = YES;	
			}
			else if ([self itemSizeConstraintStyle] == ETSizeConstraintStyleHorizontal
			      && itemFrame.size.width > [self constrainedItemSize].width)
			{
				isVerticalResize = NO; /* Horizontal resize */
			}
			
			if (isVerticalResize)
			{
				float maxItemHeight = [self constrainedItemSize].height;
				float heightDifferenceRatio = maxItemHeight / itemFrame.size.height;
				
				itemFrame.size.height = maxItemHeight;
				itemFrame.size.width *= heightDifferenceRatio;
					
			}
			else /* Horizontal resize */
			{
				float maxItemWidth = [self constrainedItemSize].width;
				float widthDifferenceRatio = maxItemWidth / itemFrame.size.width;
				
				itemFrame.size.width = maxItemWidth;
				itemFrame.size.height *= widthDifferenceRatio;				
			}
		}
		
		/* Apply Scaling */
		if ([item view] != nil)
		{

			[item setFrame: itemFrame];
			//NSLog(@"Scale %@ to %@", NSStringFromRect(unscaledFrame), 
			//	NSStringFromRect(ETScaleRect(unscaledFrame, factor)));
		}
		else
		{
			NSLog(@"% can't be rescaled because it has no view");
		}
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
- (ETViewLayoutLine *) layoutLineForLayoutItems: (NSArray *)items
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
- (NSArray *) layoutModelForLayoutItems: (NSArray *)items
{
	ETViewLayoutLine *line = [self layoutLineForLayoutItems: items];
	
	if (line != nil)
		return [NSArray arrayWithObject: line];

	return nil;
}

/** Overrides this method to interpretate the layout model and compute view 
	locations accordingly. Most of the work of layout process happens in this
	method. */
- (void) computeLayoutItemLocationsForLayoutModel: (NSArray *)layoutModel inContainer: (ETContainer *)container
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
 
// FIXME: Implement or remove
// - (NSRect) lineLayoutRectForItem:
// - (NSRect) lineLayoutRectAtLocation:
- (NSRect) lineLayoutRectForItemIndex: (int)index 
{ 
	return NSZeroRect; 
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
			/* Item display view must be a direct subview of our container, 
			   otherwise NSPointInRect test is going to be meaningless. */
			NSAssert1([[[self container] subviews] containsObject: [item displayView]],
				@"Item display view must be a direct subview of %@ to know "
				@"whether it matches given location", [self container]);
		
			if (NSPointInRect(location, [[item displayView] frame]))
				return item;
		}
		else /* Layout items uses no display view */
		{
			// FIXME: Implement
			NSLog(@"WARNING: -itemAtLocation: not implemented when item uses no display view");
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

// NOTE: Extensions probably not really interesting...
//- (NSRange) layoutItemRangeForLineLayout:
//- (NSRange) layoutItemForLineLayoutWithIndex: (int)lineIndex

@end
