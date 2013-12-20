/*
	Copyright (C) 2008 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  July 2008
	License:  Modified BSD (see COPYING)
 */

#import <EtoileFoundation/Macros.h>
#import <EtoileFoundation/ETCollection+HOM.h>
#import "ETComputedLayout.h"
#import "ETLayoutExecutor.h"
#import "ETLayoutItem.h"
#import "ETLayoutItemFactory.h"
#import "ETLayoutItemGroup.h"
#import "ETLineFragment.h"
#import "ETCompatibility.h"

CGFloat ETAlignmentHintNone = FLT_MIN;


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

	newLayout->_borderMargin = _borderMargin;
	newLayout->_itemMargin = _itemMargin;
	newLayout->_autoresizesItemToFill = _autoresizesItemToFill;
	newLayout->_horizontalAlignment = _horizontalAlignment;
	newLayout->_horizontalAlignmentGuidePosition = _horizontalAlignmentGuidePosition;
	newLayout->_computesItemRectFromBoundingBox = _computesItemRectFromBoundingBox;
	newLayout->_separatorTemplateItem = [_separatorTemplateItem copyWithZone: aZone];
	newLayout->_separatorItemEndMargin = _separatorItemEndMargin;

	return newLayout;
}

/** <override-never /> 
Returns YES. */
- (BOOL) isComputedLayout
{
	return YES;
}

/* Alignment and Margins */

/** Returns the size of the inside margin along the layout context bounds. */
- (CGFloat) borderMargin
{
	return _borderMargin;
}

/** Sets the size of the inside margin along the layout context bounds and 
triggers a layout update.

The presented content appears inset when a positive margin is set. */
- (void) setBorderMargin: (CGFloat)aMargin
{
	_borderMargin = aMargin;
	[self renderAndInvalidateDisplay];
}

/** Sets the size of the margin around each item to be layouted and triggers a 
layout update. */
- (void) setItemMargin: (CGFloat)aMargin
{
	_itemMargin = aMargin;
	[self renderAndInvalidateDisplay];
}

/** Returns the size of the margin around each item to be layouted. */
- (CGFloat) itemMargin
{
	return _itemMargin;
}

- (BOOL) autoresizesItemToFill
{
	return _autoresizesItemToFill;
}

- (void) setAutoresizesItemToFill: (BOOL)stretchToFill
{
	_autoresizesItemToFill = stretchToFill;
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
- (CGFloat) horizontalAlignmentGuidePosition
{
	return _horizontalAlignmentGuidePosition;
}

/** Sets the horizontal alignment guide 'x' coordinate relative to the layout 
context left edge.

The horizontal alignment guide is like a virtual vertical guide against which 
the layouted items can be aligned. See -setHorizontalAlignment:.

When -horizontalAlignment is not equal to ETHorizontalAlignmentGuided, this 
guide is ignored by the layout computation.  */
- (void) setHorizontalAlignmentGuidePosition: (CGFloat)aPosition
{
	_horizontalAlignmentGuidePosition = aPosition;
	[self renderAndInvalidateDisplay];
}

- (BOOL) usesAlignmentHint
{
	return _usesAlignmentHint;
}

- (void) setUsesAlignmentHint: (BOOL)usesHint
{
	_usesAlignmentHint = usesHint;
}

- (BOOL) isLayoutExecutionItemDependent
{
	return [self usesAlignmentHint];
}

- (CGFloat) horizontalAlignmentGuidePositionForItems: (NSArray *)items
{
	CGFloat guidePosition = ETAlignmentHintNone;
	CGFloat maxCombinedBoundingWidth = 0;

	for (ETLayoutItem *item in items)
	{
		CGFloat hint = ETAlignmentHintNone;
		CGFloat combinedBoundingWidth = 0;
		
		if ([[item layout] conformsToProtocol: @protocol(ETAlignmentHint)])
		{
			combinedBoundingWidth = [[item layout] maxCombinedBoundingWidth];
			hint = [[item layout] alignmentHintForLayout: self];
		}
		if (combinedBoundingWidth > maxCombinedBoundingWidth && hint != ETAlignmentHintNone)
		{
			maxCombinedBoundingWidth = combinedBoundingWidth;
			guidePosition = hint;
		}
	}
	return guidePosition;
}

- (void) adjustHorizontalAlignmentGuidePositionForItems: (NSArray *)items
{
	if ([self usesAlignmentHint] == NO)
		return;

	CGFloat guidePosition = [self horizontalAlignmentGuidePositionForItems: items];

	if (guidePosition == ETAlignmentHintNone)
		return;

	//NSLog(@"Computed guide position %0.2f", guidePosition);

	for (ETLayoutItem *item in items)
	{
		[[[item layout] ifResponds] setHorizontalAlignmentGuidePosition: guidePosition];
	}
}

- (CGFloat) maxWidthForItems: (NSArray *)items
{
	CGFloat maxWidth = 0;
	
	for (ETLayoutItem *item in items)
	{
		CGFloat width = [item width];
		
		if (width > maxWidth)
		{
			maxWidth = width;
		}
	}
	return maxWidth;
}

- (void) adjustWidthForItems: (NSArray *)items
{
	if ([self autoresizesItemToFill] == NO)
		return;

	CGFloat maxWidth = [self maxWidthForItems: items];

	NSLog(@"Computed max width %0.2f", maxWidth);

	[(ETLayoutItem *)[items mappedCollection] setWidth: maxWidth];
	/* For a non-recursive update, the resize must trigger a layout update. 
	   Layout updates are bracketed inside +disableAutolayout and
	   +enableAutolayout. As a result, -setNeedsLayoutUpdate is disabled.
	   If a recursive update is underway, the items will be automatically 
	   unscheduled when reached by the recursive traversal (just before  
	   -updateLayoutRecursively: returns for each item). */
	[[ETLayoutExecutor sharedInstance] addItems: items];
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
- (void) translateOriginOfItem: (ETLayoutItem *)anItem byX: (CGFloat)dx Y: (CGFloat)dy
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
		CGFloat dx = newOrigin.x - oldOrigin.x;
		CGFloat dy = newOrigin.y - oldOrigin.y;

		[self translateOriginOfItem: anItem byX: dx Y: dy];
	}
	else
	{
		return [anItem setOrigin: newOrigin];
	}
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

- (void) adjustSeparatorItemsForLayoutSize: (NSSize)newLayoutSize 
{
	FOREACH([[self layerItem] items], separator, ETLayoutItem *)
	{
		[self adjustSeparatorItem: separator forLayoutSize: newLayoutSize];
	}
}

- (void) prepareFlexibleItem: (ETLayoutItem *)anItem
{

}

- (void) prepareFlexibleItemsInItems: (NSArray *)items
{
	for (ETLayoutItem *item in items)
	{
		if ([self isFlexibleItem: item] == NO)
			continue;

		[self prepareFlexibleItem: item];
	}
}

- (BOOL) isFlexibleItem: (ETLayoutItem *)anItem
{
	return NO;
}

- (BOOL) sizeFlexibleItemsInItems: (NSArray *)items
                    forLayoutSize: (NSSize)newLayoutSize
                    maxLayoutSize: (NSSize)maxSize
{
	if (newLayoutSize.width == maxSize.width && newLayoutSize.height == maxSize.height)
		return NO;

	BOOL didResize = NO;
	NSArray *flexibleItems = [items filteredCollectionWithBlock: ^ BOOL (ETLayoutItem *item)
	{
		return [self isFlexibleItem: item];
	}];
	NSUInteger count = [flexibleItems count];

	for (ETLayoutItem * flexibleItem in flexibleItems)
	{
		[flexibleItem setSize: [self sizeOfFlexibleItem: flexibleItem
		                           forCurrentLayoutSize: newLayoutSize
                                  numberOfFlexibleItems: count
		                                  inMaxAreaSize: maxSize]];
		/* For a non-recursive update, the resize must trigger a layout update. 
		   Layout updates are bracketed inside +disableAutolayout and
		   +enableAutolayout. As a result, -setNeedsLayoutUpdate is disabled.
		   If a recursive update is underway, the item will be automatically 
		   unscheduled when reached by the recursive traversal (just before  
		   -updateLayoutRecursively: returns for this item). */
		[[ETLayoutExecutor sharedInstance] addItem: (id)flexibleItem];
		didResize = YES;
	}
	return didResize;
}

- (ETLayoutItem *) itemForLayoutContext
{
	return ([(id)[self layoutContext] isLayoutItem] ? (id)[self layoutContext]: (id)[(id)[self layoutContext] layoutContext]);
}

/** <override-never />
Runs the layout computation.<br />
See also -[ETLayout renderLayoutItems:isNewContent:].

This method is usually called by -render and you should rarely need to do it by 
yourself. If you want to update the layout, just uses 
-[ETLayoutItemGroup updateLayout]. 
	
You may need to override this method in your layout subclasses if you want
to create a very special layout. This method will sequentially invoke:

<list>
<item>-resetLayoutSize</item>
<item>-resizeLayoutItems:toScaleFactor:</item>
<item>-insertSeparatorsBetweenItems:</item>
<item>-generateFragmentsForItems:</item>
<item>-computeLocationsForFragments:</item>
<item>-adjustSeparatorItem:forLayoutSize:</item>
</list>

If flexible separators are used, before -adjustSeparatorItemsForLayoutSize: we have:
<list>
<item>-sizeOfFlexibleSeparatorItem:forLayoutSize:maxLayoutSize:</item>
<item>-computeLocationsForFragments: (a second pass if flexible separators are visible)</item>
</list>

Finally once the layout is computed, this method set the layout item visibility 
by calling -setVisibleItems: on the layout context. */
- (void) renderWithItems: (NSArray *)items isNewContent: (BOOL)isNewContent
{
	//NSLog(@" === UPDATE LAYOUT - %@ === ", [[self itemForLayoutContext] identifier]);

	/* Will compute the initial layout size with -resetLayoutSize */	
	[super renderWithItems: items isNewContent: isNewContent];

	[self adjustHorizontalAlignmentGuidePositionForItems: items];
	[self adjustWidthForItems: items];
	
	[self prepareFlexibleItemsInItems: items];

	NSSize initialLayoutSize = [self layoutSize];
	NSArray *spacedItems = [self insertSeparatorsBetweenItems: items];
	NSArray *layoutModel = [self generateFragmentsForItems: spacedItems];
	/* Now computes the location of every items by relying on the line by line 
	   decomposition already made. */
	NSSize newLayoutSize = [self computeLocationsForFragments: layoutModel];
	NSArray *usedItems = [self itemsUsedInFragments: layoutModel];
	NSSize maxSize = ([usedItems count] < [items count] ? newLayoutSize : initialLayoutSize);
	BOOL recomputesLayout = [self sizeFlexibleItemsInItems: usedItems
	                                         forLayoutSize: newLayoutSize
	                                         maxLayoutSize: maxSize];

	if (recomputesLayout)
	{
		// TODO: -generateFragmentsForItems: must be called here if we 
		// decide to support flexible separators in ETFlowLayout or similar.
		newLayoutSize = [self computeLocationsForFragments: layoutModel];
		usedItems = [self itemsUsedInFragments: layoutModel];
	}

	[self adjustSeparatorItemsForLayoutSize: newLayoutSize];
	// TODO: We should return this value rather than void
	[self setLayoutSize: newLayoutSize];
	
	/* Adjust layout context size (e.g. when it is embedded in a scroll view) */
	if ([self isContentSizeLayout])
	{
		[[self layoutContext] setContentSize: [self layoutSize]];
		ETDebugLog(@"Layout size is %@ with layout context size %@ and clip view size %@", 
			NSStringFromSize([self layoutSize]), 
			NSStringFromSize([[self layoutContext] size]), 
			NSStringFromSize([[self layoutContext] visibleContentSize]));
	}

	[[self layoutContext] setVisibleItems: usedItems];
}

/* Fragment-based Layout */

/** <override-subclass />
Overrides this method to generate a layout fragment based on the layout context 
constraints. Usual layout context constraints are size, vertical and horizontal 
scroller visibility. */
- (ETLineFragment *) layoutFragmentWithSubsetOfItems: (NSArray *)unlayoutedItems
{
	return nil;
}

/** <override-dummy />
Returns a fragment array, whose indexes indicate in which order these fragments 
should be presented.<br />

Overrides this method to generate your own fragment array based on the layout 
context constraints. Usual layout context constraints are size, vertical and 
horizontal scrollers visibility. How the fragment array is structured is up to you.

Any kind of object that adopts [ETFragment] protocol can put in the returned array.
e.g. [ETLayoutItem] or [ETLineFragment].

You must override -computeLocationsForFragments: in a compatible way to 
interpret the fragment array.

By default, returns an empty array.<br />
If you implement -layoutFragmentWithSubsetOfItems: in a subclass, returns the 
resulting fragment in the array. */
- (NSArray *) generateFragmentsForItems: (NSArray *)items
{
	ETLineFragment *line = [self layoutFragmentWithSubsetOfItems: items];
	
	if (line != nil)
		return A(line);

	return [NSArray array];
}

/** Returns the location at which the receiver should start to lay out the 
fragments returned by -generateFragmentsForItems:.<br />
Both border and item margins are  to compute the inset origin.

You can use this method in a subclass when overriding 
-computeLocationsForFragments: to retrieve an origin that is valid indepently of 
the layout context flipping. For example:

<example>
ETLineFragment *line = [fragments firstObject];
CGFloat totalMargin = ([self borderMargin] + [self itemMargin]) * 2;
CGFloat contentHeight =  [line height] + totalMargin;


[line setOrigin: [self originOfFirstFragment: line
                            forContentHeight: contentHeight]];
</example> */
- (NSPoint) originOfFirstFragment: (id)aFragment 
                 forContentHeight: (CGFloat)contentHeight
{
	BOOL isFlipped = [_layoutContext isFlipped];
	/* Was just reset and equal to the layout context height at this point */
	CGFloat layoutHeight = [self layoutSize].height;
	CGFloat itemMargin = [self itemMargin];
	CGFloat borderMargin = [self borderMargin];
	CGFloat lineY = borderMargin + itemMargin;
	CGFloat fragmentHeight = [aFragment height];

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
			lineY = contentHeight - fragmentHeight - itemMargin - borderMargin;
		}
		else /* contentHeight < layoutHeight */
		{
			lineY = layoutHeight - fragmentHeight - itemMargin - borderMargin;
		}
	}

	return NSMakePoint(borderMargin + [self horizontalAlignmentGuidePosition] + itemMargin, lineY);
}

/** <override-subclass />
Overrides this method to interpret the layout model and compute the fragments 
geometrical attributes (position, size, scale etc.) accordingly.

Must return the resulting layout size, in other words the minimum bouding 
rectangle that encloses the items and include border and item margins. */
- (NSSize) computeLocationsForFragments: (NSArray *)layoutModel
{
	return NSZeroSize;
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

/** Sets the size trimmed at each separator item extremities and triggers a 
layout update.

The separator extremities vary with its orientation vertical vs horizontal. 
e.g. left/right with [ETColumnLayout] and bottom/top with [ETLineLayout].<br />
How to interpret the separator end margin value is a subclass responsability.

-[ETColumn/LineLayout adjustSeparatorItem:forLayoutSize:] sums the separator end 
margin with the item margin to compute the space around each separator.

When the separator is the space, the end margin has usually no visible effects. */
- (void) setSeparatorItemEndMargin: (CGFloat)aMargin
{
	_separatorItemEndMargin = aMargin;
	[self renderAndInvalidateDisplay];
}

/** Returns the size trimmed at each separator item extremities. */
- (CGFloat) separatorItemEndMargin
{
	return _separatorItemEndMargin;
}

- (void) removePreviousSeparatorItems
{
	[[self layerItem] removeAllItems];
}

/** Prepares and inserts separator item based on -separatorTemplateItem into the 
layer item.

Separator items previously inserted by this method are automatically removed the 
next time you call it. */
- (NSArray *) insertSeparatorsBetweenItems: (NSArray *)items
{
	ETAssert([self layerItem] != nil);

	[self removePreviousSeparatorItems];

	if ([self separatorTemplateItem] == nil)
		return items;

	NSMutableArray *spacedItems = [NSMutableArray array];
	ETLayoutItem *lastItem = [items lastObject];

	FOREACH(items, item, ETLayoutItem *)
	{
		[spacedItems addObject: item];

		if ([item isEqual: lastItem])
			break;

		ETLayoutItem *separatorItem = AUTORELEASE([[self separatorTemplateItem] copy]);

		[self prepareSeparatorItem: separatorItem];
		[spacedItems addObject: separatorItem];
		[[self layerItem] addItem: separatorItem];
	}

	return spacedItems;
}

/** <override-dummy />
Overrides to customize and resize template separator item copies to be inserted.

The layout computation has not started when this method is called. 

Take note the final separator sizing is often not possible before 
-adjustSeparatorItem:forLayoutSize:. To determine their length or position 
usually requires to know other element sizes that the receiver computes. */
- (void) prepareSeparatorItem: (ETLayoutItem *)separator
{

}

- (NSSize) sizeOfFlexibleItem: (ETLayoutItem *)anItem
         forCurrentLayoutSize: (NSSize)aLayoutSize 
        numberOfFlexibleItems: (NSUInteger)nbOfFlexibleItems
                inMaxAreaSize: (NSSize)maxSize 
{
	return NSZeroSize;
}

/** <override-dummy />
Overrides to resize newly inserted separator items based on the item sizes and 
layout size which were just computed and returns the updated layout size.

Flexible separators can be adjusted to fill the space unoccupied between 
newLayoutSize and maxSize. 

If you have resized the separators in a way that doesn't change the layout 
size, you can return newLayoutSize.

The layout size might be the same than previously in -prepareSeparatorItem:.

The layout computation is finished when this method is called.  */
- (void) adjustSeparatorItem: (ETLayoutItem *)separator forLayoutSize: (NSSize)newLayoutSize
{

}

@end
