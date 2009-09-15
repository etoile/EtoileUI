/*
	Copyright (C) 2008 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  July 2008
	License:  Modified BSD (see COPYING)
 */

#import <EtoileFoundation/Macros.h>
#import "ETComputedLayout.h"
#import "ETLayoutItem.h"
#import "ETLayoutLine.h"
#import "ETCompatibility.h"


@implementation ETComputedLayout

/* Ugly hacks to shut down the compiler, so it doesn't complain that inherited 
   methods also declared by ETPositionaLayout aren't implemented */
- (void) setLayoutContext: (id <ETLayoutingContext>)context { return [super setLayoutContext: context]; }
- (id <ETLayoutingContext>) layoutContext { return [super layoutContext]; }
- (ETLayoutItem *) itemAtLocation: (NSPoint)location { return [super itemAtLocation: location]; }

DEALLOC(DESTROY(_separatorTemplateItem))

- (id) copyWithZone: (NSZone *)aZone layoutContext: (id <ETLayoutingContext>)ctxt
{
	ETComputedLayout *newLayout = [super copyWithZone: aZone layoutContext: ctxt];

	newLayout->_itemMargin = _itemMargin;
	newLayout->_horizontalAlignment = _horizontalAlignment;
	newLayout->_horizontalAlignmentGuidePosition = _horizontalAlignmentGuidePosition;
	newLayout->_computesItemRectFromBoundingBox = _computesItemRectFromBoundingBox;
	newLayout->_separatorTemplateItem = [_separatorTemplateItem copyWithZone: aZone];

	return newLayout;
}

/** <override-never /> 
Returns YES. */
- (BOOL) isComputedLayout
{
	return YES;
}

/* Alignment and Margins */

/** Sets the size of the margin around each item to be layouted and triggers a 
layout update. */
- (void) setItemMargin: (float)aMargin
{
	_itemMargin = aMargin;

	// TODO: Evaluate whether we should add an API at ETLayout level to request 
	// layout refresh, or rather remove this code and let the developer triggers
	// the layout update.
	if ([self canRender])
	{	
		[self render: nil isNewContent: NO];
		[[self layoutContext] setNeedsDisplay: YES];
	}
}

/** Returns the size of the margin around each item to be layouted. */
- (float) itemMargin
{
	return _itemMargin;
}

/** Returns the content horizontal alignment in the layout context area. */
- (ETLayoutHorizontalAlignment) horizontalAlignment
{
	return _horizontalAlignment;
}

/** Sets the content horizontal alignment in the layout context area. */
- (void) setHorizontalAligment: (ETLayoutHorizontalAlignment)anAlignment
{
	_horizontalAlignment = anAlignment;
}

/** Returns the horizontal alignment guide 'x' coordinate relative to the layout 
context left edge.

See also -setHorizontalAlignmentGuidePosition: */
- (float) horizontalAlignmentGuidePosition
{
	return _horizontalAlignmentGuidePosition;
}

/** Sets the horizontal alignment guide 'x' coordinate relative to the layout 
context left edge.

The horizontal alignment guide is like a virtual vertical guide against which 
the layouted items can be aligned. See -setHorizontalAlignment:.

When -horizontalAlignment is not equal to ETHorizontalAlignmentGuided, this 
guide is ignored by the layout computation.  */
- (void) setHorizontalAlignmentGuidePosition: (float)aPosition
{
	_horizontalAlignmentGuidePosition = aPosition;
}

/* Layout Computation */

/** Returns whether the bounding box rather than the frame is the item area 
that will be used to compute the layout. */
- (BOOL) computesItemRectFromBoundingBox
{
	return _computesItemRectFromBoundingBox;
}

/** Sets whether the bounding box rather than the frame is the item area 
that will be used to compute the layout. */
- (void) setComputesItemRectFromBoundingBox: (BOOL)usesBoundingBox
{
	_computesItemRectFromBoundingBox = usesBoundingBox;
}

/** <override-dummy />
Returns either the given item frame or its bounding box expressed in its parent 
content coordinate space.

The parent is the layout context. */
- (NSRect) rectForItem: (ETLayoutItem *)anItem
{
	if (_computesItemRectFromBoundingBox)
	{
		return [anItem convertRectToParent: [anItem boundingBox]];
	}
	else
	{
		return [anItem frame];
	}
}

/** Moves the item frame by the given delta. */
- (void) translateOriginOfItem: (ETLayoutItem *)anItem byX: (float)dx Y: (float)dy
{
	NSRect itemFrame = [anItem frame];
	[anItem setOrigin: NSMakePoint(itemFrame.origin.x + dx, itemFrame.origin.y + dy)];
}

/** <override-never />
Runs the layout computation.<br />
See also -[ETLayout renderLayoutItems:isNewContent:].

This method is usually called by -render and you should rarely need to do it by 
yourself. If you want to update the layout, just uses 
-[ETLayoutItemGroup updateLayout]. 
	
You may need to override this method in your layout subclasses if you want
to create a very special layout style. This method will sequentially invoke:
<list>
<item>-resetLayoutSize
<item>-resizeLayoutItems:toScaleFactor:</item>
<item>-layoutModelForLayoutItems:</item>
<item>-computeLayoutItemLocationsForLayoutModel:</item>.
</list>

Finally once the layout is computed, this method set the layout item visibility 
by calling -setVisibleItems: on the layout context. 

The scroll view visibility is handled by this method (this is subject to change). */
- (void) renderWithLayoutItems: (NSArray *)items isNewContent: (BOOL)isNewContent
{	
	[super renderWithLayoutItems: items isNewContent: isNewContent];

	NSMutableArray *spacedItems = [NSMutableArray array];
	for (unsigned int i = 0; i < [items count]; i++)
	{
		[spacedItems addObject: [items objectAtIndex: i]];
		if (i < ([items count] - 1) && [self separatorTemplateItem] != nil)
		{
			[spacedItems addObject: AUTORELEASE([[self separatorTemplateItem] copy])];
		}
	}
	
	NSArray *layoutModel = [self generateFragmentsForItems: spacedItems];
	/* Now computes the location of every items by relying on the line by line 
	   decomposition already made. */
	[self computeLocationsForFragments: layoutModel];
	
	// TODO: May be worth to optimize by computing set intersection of visible 
	// and unvisible layout items
	[[self layoutContext] setVisibleItems: [NSArray array]];
	
	/* Adjust layout context size when it is embedded in a scroll view */
	if ([[self layoutContext] isScrollViewShown])
	{
		NSAssert([self isContentSizeLayout], 
			@"Any layout done in a scroll view must be based on content size");
			
		[[self layoutContext] setContentSize: [self layoutSize]];
		ETDebugLog(@"Layout size is %@ with layout context size %@ and clip view size %@", 
			NSStringFromSize([self layoutSize]), 
			NSStringFromSize([[self layoutContext] size]), 
			NSStringFromSize([[self layoutContext] visibleContentSize]));
	}

	NSMutableArray *visibleItems = [NSMutableArray array];
	
	/* Flatten layout model by putting all items into a single array */
	FOREACH(layoutModel, line, ETLayoutLine *)
	{
		[visibleItems addObjectsFromArray: [line fragments]];
	}
	
	[[self layoutContext] setVisibleItems: visibleItems];
}

/* Fragment-based Layout */

/** <override-subclass />
Overrides this method to generate a layout line based on the layout context 
constraints. Usual layout context constraints are size, vertical and horizontal 
scroller visibility. */
- (ETLayoutLine *) layoutFragmentWithSubsetOfItems: (NSArray *)items
{
	return nil;
}

/** <override-dummy />
Returns a layout model where layouts lines have been collected inside an array, 
whose indexes indicate in which order these layout lines should be presented.

Overrides this method to generate your own layout model based on the layout 
context constraints. Usual layout context constraints are size, vertical and 
horizontal scrollers visibility. How the layout model is structured is up to you.

This layout model will be interpreted by -computeViewLocationsForLayoutModel:. */
- (NSArray *) generateFragmentsForItems: (NSArray *)items
{
	ETLayoutLine *line = [self layoutFragmentWithSubsetOfItems: items];
	
	if (line != nil)
		return A(line);

	return nil;
}

/** <override-subclass />
Overrides this method to interpret the layout model and compute the fragments 
geometrical attributes (position, size, scale etc.) accordingly. */
- (void) computeLocationsForFragments: (NSArray *)layoutModel
{

}

/* Seperator support */

/** Sets the separator item to be drawn between each layouted item. */
- (void) setSeparatorTemplateItem: (ETLayoutItem *)separator
{
	ASSIGN(_separatorTemplateItem, separator);
	
	if ([self canRender])
	{	
		[self render: nil isNewContent: NO];
		[[self layoutContext] setNeedsDisplay: YES];
	}
}

/** Returns the separator item to be drawn between each layouted item. */			
- (ETLayoutItem *) separatorTemplateItem
{
	return _separatorTemplateItem;
}

@end
