/*
	Copyright (C) 2007 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  May 2007
	License:  Modified BSD (see COPYING)
 */

#import <EtoileFoundation/Macros.h>
#import <EtoileFoundation/ETCollection.h>
#import "ETLineLayout.h"
#import "ETLayoutExecutor.h"
#import "ETLayoutItem.h"
#import "ETLayoutItemFactory.h"
#import "ETLineFragment.h"
#import "ETGeometry.h"
#import "ETCompatibility.h"
#include "float.h"


@implementation ETLineLayout

- (NSImage *) icon
{
	return [NSImage imageNamed: @"ui-split-panel.png"];
}

/** Returns a line fragment filled with items to layout. */
- (ETLineFragment *) layoutFragmentWithSubsetOfItems: (NSArray *)items
{
	CGFloat layoutWidth = [self layoutSize].width;

	if ([self isContentSizeLayout])
	{
		layoutWidth = FLT_MAX;
	}

	ETLineFragment *line = [ETLineFragment horizontalLineWithOwner: self 
	                                                    itemMargin: [self itemMargin] 
	                                                      maxWidth: layoutWidth];
	NSArray *acceptedItems = [line fillWithItems: items];

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
	CGFloat totalMargin = ([self borderMargin] + [self itemMargin]) * 2;
	CGFloat contentHeight = [line height] + totalMargin;

	/* Will compute and set the item locations */
	[line setOrigin: [self originOfFirstFragment: line
	                            forContentHeight: contentHeight]];

	ETDebugLog(@"Item locations computed by layout line :%@", line);

	return NSMakeSize([line width] + totalMargin, contentHeight);
}

static const CGFloat undeterminedHeight = 10;

- (void) prepareSeparatorItem: (ETLayoutItem *)separator
{
	NSString *identifier = [separator identifier];
 
	if ([identifier isEqual: kETLineSeparatorItemIdentifier])
	{
		[separator setSize: NSMakeSize(kETLineSeparatorMinimumSize, undeterminedHeight)];
	}
	else if ([identifier isEqual: kETSpaceSeparatorItemIdentifier])
	{
		[separator setHeight: undeterminedHeight];
	}
	else if ([identifier isEqual: kETFlexibleSpaceSeparatorItemIdentifier])
	{
		[separator setSize: NSZeroSize];
	}
}

- (void) prepareFlexibleItem: (ETLayoutItem *)anItem
{
	[anItem setWidth: 0];
}

/** Returns YES if the item autoresizing mask includes ETAutoresizingFlexibleWidth. */ 
- (BOOL) isFlexibleItem: (ETLayoutItem *)anItem
{
	return [anItem autoresizingMask] & ETAutoresizingFlexibleWidth;
}

/** Returns a suggested size to adjust the flexible space separators for the 
given layout area size. */ 
- (NSSize) sizeOfFlexibleItem: (ETLayoutItem *)anItem
         forCurrentLayoutSize: (NSSize)aLayoutSize 
        numberOfFlexibleItems: (NSUInteger)nbOfFlexibleItems
                inMaxAreaSize: (NSSize)maxSize 
{
	return NSMakeSize((maxSize.width - aLayoutSize.width) / nbOfFlexibleItems, [anItem height]);
}

- (void) adjustSeparatorItem: (ETLayoutItem *)separator forLayoutSize: (NSSize)newLayoutSize
{
	NSString *identifier = [separator identifier];
 
	if ([identifier isEqualToString: kETLineSeparatorItemIdentifier])
	{
		CGFloat totalEndMargin = [self separatorItemEndMargin];

		[separator setY: totalEndMargin];
		[separator setHeight: (newLayoutSize.height - totalEndMargin * 2)];
	}
	else if ([identifier isEqualToString: kETSpaceSeparatorItemIdentifier])
	{
		[separator setHeight: newLayoutSize.height];
	}
	if ([identifier isEqualToString: kETFlexibleSpaceSeparatorItemIdentifier])
	{
		[separator setHeight: newLayoutSize.height];
	}

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

	NSLog(@"Resize line from %@ to %@ for %@ - %@", NSStringFromSize(oldLayoutSize),
		NSStringFromSize(newLayoutSize), [(id)[self layoutContext] primitiveDescription],
		[[(id)[self layoutContext] ifResponds] identifier]);

	for (ETLayoutItem *item in items)
	{
		ETAutoresizing autoresizing = [item autoresizingMask];
		NSRect frame = [item frame];

		ETAutoresize(&frame.origin.y, &frame.size.height,
					 NO,
					 (autoresizing & ETAutoresizingFlexibleHeight),
					 NO,
					 newLayoutSize.height, oldLayoutSize.height);
		
		[item setHeight: frame.size.height];
		
		if ([item isGroup] == NO)
			continue;

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
