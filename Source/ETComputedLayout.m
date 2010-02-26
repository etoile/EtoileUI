/*
	Copyright (C) 2008 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  July 2008
	License:  Modified BSD (see COPYING)
 */

#import <EtoileFoundation/Macros.h>
#import "ETComputedLayout.h"
#import "ETLayoutItem.h"
#import "ETLayoutItemGroup.h"
#import "ETLineFragment.h"
#import "ETCompatibility.h"


@implementation ETComputedLayout

/* Ugly hacks to shut down the compiler, so it doesn't complain that inherited 
   methods also declared by ETPositionaLayout aren't implemented */
- (void) setLayoutContext: (id <ETLayoutingContext>)context { return [super setLayoutContext: context]; }
- (id <ETLayoutingContext>) layoutContext { return [super layoutContext]; }
- (ETLayoutItem *) itemAtLocation: (NSPoint)location { return [super itemAtLocation: location]; }

- (void) dealloc
{
	DESTROY(_separatorTemplateItem);
	[super dealloc];
}

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
	[self renderAndInvalidateDisplay];
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
	[self renderAndInvalidateDisplay];
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
	[self renderAndInvalidateDisplay];
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

/** Sets the origin of the given item based on the item rect kind (frame or 
bounding box). */
- (void) setOrigin: (NSPoint)newOrigin forItem: (ETLayoutItem *)anItem
{
	if (_computesItemRectFromBoundingBox)
	{
		NSRect itemRect = [anItem convertRectToParent: [anItem boundingBox]];
		NSPoint oldOrigin = itemRect.origin;
		float dx = newOrigin.x - oldOrigin.x;
		float dy = newOrigin.y - oldOrigin.y;

		[self translateOriginOfItem: anItem byX: dx Y: dy];
	}
	else
	{
		return [anItem setOrigin: newOrigin];
	}
}

- (void) removePreviousSeparatorItems
{
	[[self rootItem] removeAllItems];
}

/* Flattens the given layout model by putting all items into a single array. */
- (NSArray *) itemsUsedInFragments: (NSArray *)fragments
{
	NSMutableArray *visibleItems = [NSMutableArray array];

	FOREACH(fragments, fragment, ETLineFragment *)
	{
		[visibleItems addObjectsFromArray: [fragment items]];
	}

	return visibleItems;
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

	[self removePreviousSeparatorItems];
	NSArray *spacedItems = [self insertSeparatorsBetweenItems: items];
	NSArray *layoutModel = [self generateFragmentsForItems: spacedItems];
	/* Now computes the location of every items by relying on the line by line 
	   decomposition already made. */
	[self computeLocationsForFragments: layoutModel];
	
	// TODO: May be worth to optimize by computing set intersection of visible 
	// and unvisible layout items
	[[self layoutContext] setVisibleItems: [NSArray array]];
	
	/* Adjust layout context size (e.g. when it is embedded in a scroll view) */
	if ([self isContentSizeLayout])
	{
		[[self layoutContext] setContentSize: [self layoutSize]];
		ETDebugLog(@"Layout size is %@ with layout context size %@ and clip view size %@", 
			NSStringFromSize([self layoutSize]), 
			NSStringFromSize([[self layoutContext] size]), 
			NSStringFromSize([[self layoutContext] visibleContentSize]));
	}

	[[self layoutContext] setVisibleItems: [self itemsUsedInFragments: layoutModel]];
}

/* Fragment-based Layout */

/** <override-subclass />
Overrides this method to generate a layout line based on the layout context 
constraints. Usual layout context constraints are size, vertical and horizontal 
scroller visibility. */
- (ETLineFragment *) layoutFragmentWithSubsetOfItems: (NSArray *)items
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
	ETLineFragment *line = [self layoutFragmentWithSubsetOfItems: items];
	
	if (line != nil)
		return A(line);

	return [NSArray array];
}

- (NSPoint) originOfFirstFragment: (id)aFragment 
                 forContentHeight: (float)contentHeight
{
	BOOL isFlipped = [_layoutContext isFlipped];
	 /* Was just reset and equal to the layout context height at this point */
	float layoutHeight = [self layoutSize].height;
	float itemMargin = [self itemMargin];
	float lineY = itemMargin;
	float fragmentHeight = [aFragment height];

	/* The statement below looks simple but is very easy to break and hard to 
	   get right.
	   If you ever edit it, please use PhotoViewExample to test the 4 cases 
	   exhaustively (resizing the layout context and varying item count, margin 
	   and scaling):
	   - [_layoutContext isFlipped] + [_layoutContext decoratorItem] == nil
	   - [_layoutContext isFlipped] + [_layoutContext decoratorItem] == scrollable area
	   - [_layoutContext isFlipped] == NO + [_layoutContext decoratorItem] == nil
	   - [_layoutContext isFlipped] == NO + [_layoutContext decoratorItem] == scrollable area */
	if (isFlipped == NO)
	{
		if ([self isContentSizeLayout] && contentHeight > layoutHeight)
		{
			lineY = contentHeight - fragmentHeight - itemMargin;
		}
		else /* contentHeight < layoutHeight */
		{
			lineY = layoutHeight - fragmentHeight - itemMargin;
		}
		/*if ([self isContentSizeLayout] == NO || contentHeight < layoutHeight)
		{
			lineY = layoutHeight - fragmentHeight - itemMargin;
		}
		else
		{
			lineY = contentHeight - fragmentHeight - itemMargin;	
		}*/
	}

	return NSMakePoint(itemMargin, lineY);
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
	[self renderAndInvalidateDisplay];
}

/** Returns the separator item to be drawn between each layouted item. */			
- (ETLayoutItem *) separatorTemplateItem
{
	return _separatorTemplateItem;
}

- (NSArray *) insertSeparatorsBetweenItems: (NSArray *)items
{
	if ([self separatorTemplateItem] == nil)
		return items;

	ETAssert([self rootItem] != nil);

	NSMutableArray *spacedItems = [NSMutableArray array];
	ETLayoutItem *lastItem = [items lastObject];

	FOREACH(items, item, ETLayoutItem *)
	{
		[spacedItems addObject: item];

		if ([item isEqual: lastItem])
			break;

		ETLayoutItem *separatorItem = AUTORELEASE([[self separatorTemplateItem] copy]);

		[spacedItems addObject: separatorItem];
		[[self rootItem] addItem: separatorItem];
	}

	return spacedItems;
}

@end
