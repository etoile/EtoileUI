/*  <title>ETLayout</title>

	ETLayout.m
	
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
 
#import <EtoileUI/ETLayoutItemGroup.h>

#import <EtoileUI/ETLayout.h>
#import <EtoileUI/ETViewLayoutLine.h>
#import <EtoileUI/ETContainer.h>
#import <EtoileUI/NSView+Etoile.h>
#import <EtoileUI/GNUstep.h>

@interface ETContainer (PackageVisibility)
- (BOOL) isScrollViewShown;
- (void) setShowsScrollView: (BOOL)scroll;
@end

/*
 * Private methods
 */

@interface ETLayout (Private)
/* Utility methods */
- (NSRect) lineLayoutRectForItemAtIndex: (int)index;
- (ETLayoutItem *) itemAtLocation: (NSPoint)location;
@end

/*
 * Main implementation
 */

@implementation ETLayout

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
		_layoutContext = nil;
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
	ETLayout *proto = [[[self class] alloc] init];
	
	proto->_layoutContext = nil;
	proto->_delegate = nil;
	proto->_displayViewPrototype = [_displayViewPrototype copy];
	
	proto->_layoutSize = _layoutSize;
	proto->_layoutSizeCustomized = _layoutSizeCustomized;
	proto->_maxSizeLayout  = _maxSizeLayout;
	
	proto->_itemSizeConstraintStyle = _itemSizeConstraintStyle;
	
	return AUTORELEASE(proto);
}

/** Returns the view where the layout happens (by computing locations of a layout item series). */
- (ETContainer *) container;
{
	return (ETContainer *)[[self layoutContext] view];
}

/** Sets the context where the layout should happen. 
	When a layout context is set, on next layout update the receiver will 
	arrange the layout items in a specific style and order.
	context isn't retained, but it is expected context has already
	retained the receiver. */
- (void) setLayoutContext: (id <ETLayoutingContext>)context
{
	// NOTE: Avoids retain cycle by weak referencing the context
	_layoutContext = context;
	[[_layoutContext items] makeObjectsPerformSelector: @selector(restoreDefaultFrame)];
}

- (id <ETLayoutingContext>) layoutContext
{
	return _layoutContext;
}

/** Overrides in subclasses to indicate whether the layout is a semantic layout
	or not. Returns NO by default.
	ETTableLayout is a normal layout but ETPropertyLayout (which displays a 
	list of properties) is semantic, the latter works by delegating everything 
	to an existing normal layout and may eventually replace this layout by 
	another one. If you overrides this method to return YES, forwarding of all
	non-overidden methods to the delegate will be handled automatically. */
- (BOOL) isSemantic
{
	return NO;
}

/** Returns YES when the layout computes the location of the layout items and
	updates these locations as necessary by itself. 
	By default returns YES, overrides to return NO when the layout subclass let
	the user sets the layout item locations. 
	The returned value alters the order in which ETContainer data source 
	methods are called. */
- (BOOL) isComputedLayout
{
	return YES;
}

/** Returns YES if all layout items are visible in the bounds of the related 
	container once the layout has been computed, otherwise returns NO when
	the layout has run out of space.
	Whether all items are visible depends of the layout itself and also whether
	the container is embedded in a scroll view because in such case the 
	container size is altered. */
- (BOOL) isAllContentVisible
{
	int nbOfItems = [[[self layoutContext] items] count];
	
	return [[[self layoutContext] visibleItems] count] == nbOfItems;
}

/** By default layout size is precisely matching frame size of the container to 
	which the receiver is bound to.
	When the container uses a scroll view, layout size is set the mininal size 
	which encloses all the layout item frames once they have been layouted. 
	This size is the maximal layout size you can compute for the receiver with 
	the content provided by the container.
	Whether the layout size is computed in horizontal, vertical direction or 
	both depends of layout kind, settings of the layout and finally scroller 
	visibility in related container.
	If you call -setUsesCustomLayoutSize:, the layout size won't be adjusted anymore by
	the layout and container together until you delegate it again by calling
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
	if ([[self layoutContext] isScrollViewShown])
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

/** Returns whether the receiver is currently computing and rendering its 
	layout right now or not.
	You must call this method in your code before calling any Layouting related
	methods. If YES is returned, don't call the method you want to and wait a 
	bit before giving another try to -isRendering. When NO is returned, you are 
	free to call any Layouting related methods. */
- (BOOL) isRendering
{
	return _isLayouting;
}

/** Renders a collection of items by requesting them to the container to which
	the receiver is bound to.
	Layout items can be requested in two styles: to the container itself or
	indirectly to a data source provided by the container. When the layout 
	items are provided through a data source, the layout will only request 
	lazily the subset of them to be displayed (not currently true). 
	This method is usually called by ETContainer and you should rarely need to
	do it by yourself. If you want to update the layout, just uses 
	-[ETContainer updateLayout]. */
- (void) render
{
	if ([self layoutContext] == nil)
	{
		NSLog(@"WARNING: No layout context available");	
		return;
	}

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

	/* We remove the display views of layout items. Note they may be invisible 
	   by being located outside of container bounds. */
	//NSLog(@"Remove views of layout items currently displayed from their container");
	[[self layoutContext] setVisibleItems: [NSArray array]];
	
	/* When the number of layout items is zero and doesn't vary, no layout 
	   update is necessary */
	if ([[[self layoutContext] items] count] == 0)
	{
		_isLayouting = NO;
		return;
	}
	
	/* Let layout delegate overrides default layout items rendering */
	// FIXME: This delegate stuff isn't really useful. Remove it or make it
	// useful.
	if ([_delegate respondsToSelector: @selector(layout:applyLayoutItem:)])
	{
		NSEnumerator *e = [[[self layoutContext] items] objectEnumerator];
		ETLayoutItem *item = nil;
		
		while ((item = [e nextObject]) != nil)
		{
			//[_delegate layout: self applyLayoutItem: item];
			//[_delegate layout: self renderLayoutItem: item]; // FIXME: Use proper delegate syntax
		}
	}
	else
	{
		[[[self layoutContext] items] makeObjectsPerformSelector: @selector(apply:) withObject: nil];
	}
	
	/* We always set the layout size which should be used to compute the 
	   layout unless a custom layout has been set by calling -setLayoutSize:
	   before -render. */
	if ([self usesCustomLayoutSize] == NO)
	{
		if ([[self layoutContext] isScrollViewShown])
		{
			/* Better to request the visible rect than the container frame 
			   which might be severely altered by the previouly set layout. */
			[self setLayoutSize: [[self layoutContext] visibleContentSize]];
		}
		else /* Using content layout size without scroll view is supported */
		{
			[self setLayoutSize: [[self layoutContext] size]];
		}
	}
	
	_isLayouting = NO;
	[self renderWithLayoutItems: [[self layoutContext] items]];
}

/** Runs the layout computation which finds a location in the view container
    to all layout items passed in parameter. 
	This method is usually called by -render and you should rarely need to
	do it by yourself. If you want to update the layout, just uses 
	-[ETContainer updateLayout]. 
	You may need to override this method in your layout subclasses if you want
	to create very special layout style. In this cases, it's important to know
	this method is in charge of calling -resizeLayoutItems, 
	-layoutModelForLayoutItems:, -computeLayoutItemLocationsForLayoutModel:.
	Finally once the layout is done, this method set the layout item visibility 
	by calling -setVisibleItems: on the related container. Actually it takes 
	care of the scroll view visibility but this may change a little bit in 
	future. */
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
	float scale = [[self layoutContext] itemScaleFactor];
	
	[self resizeLayoutItems: items toScaleFactor: scale];
	
	layoutModel = [self layoutModelForLayoutItems: items];
	/* Now computes the location of every views by relying on the line by line 
	   decomposition already made. */
	[self computeLayoutItemLocationsForLayoutModel: layoutModel];
	
	// TODO: May be worth to optimize by computing set intersection of visible and unvisible layout items
	// NSLog(@"Remove views %@ of next layout items to be displayed from their superview", itemViews);
	[[self layoutContext] setVisibleItems: [NSArray array]];
	
	/* Adjust container size when it is embedded in a scroll view */
	if ([[self layoutContext] isScrollViewShown])
	{
		// NOTE: For this assertion check -[ETContainer setScrollView:] 
		NSAssert([self isContentSizeLayout] == YES, 
			@"Any layout done in a scroll view must be based on content size");
			
		[[self layoutContext] setContentSize: [self layoutSize]];
		NSLog(@"Layout size is %@ with container size %@ and clip view size %@", 
			NSStringFromSize([self layoutSize]), 
			NSStringFromSize([[self layoutContext] size]), 
			NSStringFromSize([[self layoutContext] visibleContentSize]));
	}
	
	NSMutableArray *visibleItems = [NSMutableArray array];
	NSEnumerator  *e = [layoutModel objectEnumerator];
	ETViewLayoutLine *line = nil;
	
	/* Flatten layout model by putting all views in a single array */
	while ((line = [e nextObject]) != nil)
	{
		[visibleItems addObjectsFromArray: [line items]];
	}
	
	[[self layoutContext] setVisibleItems: visibleItems];
	
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

/* 
 * Line-based layouts methods 
 */

/** Overrides this method to generate a layout line based on the container 
    constraints. Usual container constraints are size, vertical and horizontal 
	scroller visibility. */
- (ETViewLayoutLine *) layoutLineForLayoutItems: (NSArray *)items
{
	return nil;
}

/** Overrides this method to generate a layout model based on the container 
    constraints. Usual container constraints are size, vertical and horizontal 
	scrollers visibility.
	A layout model is commonly made of several layouts lines inside an array
	where indexes indicates in which order these layout lines should be 
	displayed. It's up to you if you want to create a layout model with a more 
	elaborated ordering and rendering semantic. Finally the layout model is 
	interpreted by -computeViewLocationsForLayoutModel:. */
- (NSArray *) layoutModelForLayoutItems: (NSArray *)items
{
	ETViewLayoutLine *line = [self layoutLineForLayoutItems: items];
	
	if (line != nil)
		return [NSArray arrayWithObject: line];

	return nil;
}

/** Overrides this method to interpretate the layout model and compute layout 
	item locations accordingly. Most of the work of layout process happens in 
	this method. */
- (void) computeLayoutItemLocationsForLayoutModel: (NSArray *)layoutModel
{

}

/* Wrapping Existing View */

- (void) setDisplayViewPrototype: (NSView *)protoView
{
	ASSIGN(_displayViewPrototype, protoView);

	[_displayViewPrototype removeFromSuperview];
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

/** Returns the layout item for which location is inside its display area (the
	layout item frame). 
	Location must be expressed in the coordinates of the container presently 
	associated with the receiver. */
- (ETLayoutItem *) itemAtLocation: (NSPoint)location
{
	NSArray *layoutItems = [[self layoutContext] items];
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

/** Returns the display area of the layout item passed in parameter. 
	Returned rect is expressed in the coordinates of the container presently 
	associated with the receiver.*/
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
