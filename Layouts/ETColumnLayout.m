/*
	Copyright (C) 2007 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  May 2007
	License:  Modified BSD (see COPYING)
 */

#import <EtoileFoundation/Macros.h>
#import <EtoileFoundation/ETCollection.h>
#import "ETColumnLayout.h"
#import "ETGeometry.h"
#import "ETLayoutExecutor.h"
#import "ETLayoutItem.h"
#import "ETLayoutItemFactory.h"
#import "ETLineFragment.h"
#import "ETCompatibility.h"
#include <float.h>


@implementation ETColumnLayout

- (NSImage *) icon
{
	return [NSImage imageNamed: @"ui-split-panel-vertical.png"];
}

/** Returns a line fragment filled with items to layout. */
- (ETLineFragment *) layoutFragmentWithSubsetOfItems: (NSArray *)unlayoutedItems
{
	CGFloat layoutHeight = [self layoutSize].height;

	if ([self isContentSizeLayout])
	{
		layoutHeight = FLT_MAX;
	}

	ETLineFragment *line = [ETLineFragment verticalLineWithOwner: self 
	                                                  itemMargin: [self itemMargin]
	                                                   maxHeight: layoutHeight 
	                                                   isFlipped: [_layoutContext isFlipped]];
	NSArray *acceptedItems = [line fillWithItems: unlayoutedItems];

	if ([acceptedItems isEmpty])
		return nil;

	return line;
}

- (NSSize) computeLocationsForFragments: (NSArray *)layoutModel
{
	if ([layoutModel isEmpty])
		return NSZeroSize;

	NSParameterAssert([layoutModel count] == 1);

	ETLineFragment *line = [layoutModel lastObject];
	CGFloat lineHeight = [line height];
	CGFloat totalMargin = ([self borderMargin] + [self itemMargin]) * 2;
	CGFloat contentHeight = lineHeight + totalMargin;

	/* Will compute and set the item locations */
	[line setOrigin: [self originOfFirstFragment: line
	                            forContentHeight: contentHeight]];

	ETDebugLog(@"Item locations computed by layout line :%@", line);

	/* lineHeight already includes itemMargin * 2 */
	return NSMakeSize([self horizontalAlignmentGuidePosition] + [line width] + totalMargin, contentHeight);
}

static const CGFloat undeterminedWidth = 10;

- (void) prepareSeparatorItem: (ETLayoutItem *)separator
{
	NSString *identifier = [separator identifier];
 
	if ([identifier isEqualToString: kETLineSeparatorItemIdentifier])
	{
		[separator setSize: NSMakeSize(undeterminedWidth, kETLineSeparatorMinimumSize)];
	}
	else if ([identifier isEqualToString: kETSpaceSeparatorItemIdentifier])
	{
		[separator setWidth: undeterminedWidth];
	}
	if ([identifier isEqualToString: kETFlexibleSpaceSeparatorItemIdentifier])
	{
		[separator setSize: NSZeroSize];
	}
}

- (void) prepareFlexibleItem: (ETLayoutItem *)anItem
{
	[anItem setHeight: 0];
}

/** Returns YES if the item autoresizing mask includes ETAutoresizingFlexibleHeight. */
- (BOOL) isFlexibleItem: (ETLayoutItem *)anItem
{
	return [anItem autoresizingMask] & ETAutoresizingFlexibleHeight;
}

- (NSSize) sizeOfFlexibleItem: (ETLayoutItem *)anItem
         forCurrentLayoutSize: (NSSize)aLayoutSize 
        numberOfFlexibleItems: (NSUInteger)nbOfFlexibleItems
                inMaxAreaSize: (NSSize)maxSize 
{
	return NSMakeSize([anItem width], (maxSize.height - aLayoutSize.height) / nbOfFlexibleItems);
}

- (void) adjustSeparatorItem: (ETLayoutItem *)separator 
               forLayoutSize: (NSSize)newLayoutSize
{
	CGFloat totalEndMargin = [self separatorItemEndMargin];

	[separator setX: totalEndMargin];
	[separator setWidth: (newLayoutSize.width - totalEndMargin * 2)];
}

- (void) resizeItems: (NSArray *)items
    forNewLayoutSize: (NSSize)newLayoutSize
             oldSize: (NSSize)oldLayoutSize
{
	/* For a collapsed ETTitleBarItem, the decorated item content bounds is set zero */
	BOOL collapsing = NSEqualSizes(NSZeroSize, newLayoutSize);
	BOOL expanding = NSEqualSizes(NSZeroSize, oldLayoutSize);

	if (collapsing || expanding)
		return;

	NSParameterAssert(NSEqualSizes(ETNullSize, oldLayoutSize) == NO);
	NSParameterAssert(NSEqualSizes(NSZeroSize, newLayoutSize) == NO && NSEqualSizes(NSZeroSize, oldLayoutSize) == NO);
	
	if (NSEqualSizes(newLayoutSize, oldLayoutSize))
		return;

	NSLog(@"Resize column from %@ to %@ for %@ - %@", NSStringFromSize(oldLayoutSize),
		NSStringFromSize(newLayoutSize), [(id)[self layoutContext] primitiveDescription],
		[[(id)[self layoutContext] ifResponds] identifier]);

	for (ETLayoutItem *item in items)
	{
		ETAutoresizing autoresizing = [item autoresizingMask];
		NSRect frame = [item frame];
		BOOL isItemClipped = (NSMaxX(frame) > MAX(newLayoutSize.width, oldLayoutSize.width)
			|| NSMaxY(frame) > MAX(newLayoutSize.height, oldLayoutSize.height));

		if (isItemClipped)
		{
			[NSException raise: NSInternalInconsistencyException
						format: @"Layout size (%@ -> %@) clips autoresized item %@. "
			                     "You should usually increase the size passed to "
			                     "+[ETLayoutItemFactory itemGroupWithFrame:] for "
			                     "the layout context.",
			                    NSStringFromSize(oldLayoutSize), NSStringFromSize(newLayoutSize), item];
		}
		ETAutoresize(&frame.origin.x, &frame.size.width,
					 NO,
					 (autoresizing & ETAutoresizingFlexibleWidth),
					 NO,
					 newLayoutSize.width, oldLayoutSize.width);
		
		[item setWidth: frame.size.width];
		/* For a non-recursive update, the resize must trigger a layout update. 
		   Layout updates are bracketed inside +disableAutolayout and
		   +enableAutolayout. As a result, -setNeedsLayoutUpdate is disabled.
		   If a recursive update is underway, the item will be automatically 
		   unscheduled when reached by the recursive traversal (just before  
		   -updateLayoutRecursively: returns for this item). */
		[[ETLayoutExecutor sharedInstance] addItem: (id)item];
	}
}

@end
