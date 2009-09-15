/*
	Copyright (C) 2007 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  May 2007
	License:  Modified BSD (see COPYING)
 */

#import <EtoileFoundation/Macros.h>
#import "ETStackLayout.h"
#import "ETGeometry.h"
#import "ETLayoutItem.h"
#import "ETLayoutLine.h"
#import "ETCompatibility.h"
#include <float.h>


@implementation ETStackLayout

/** Returns a line filled with items to layout (stored in an array). */
- (ETLayoutLine *) layoutFragmentWithSubsetOfItems: (NSArray *)items
{
	NSMutableArray *layoutedItems = [NSMutableArray array];
	float vAccumulator = 0;
	float itemMargin = [self itemMargin];
    
	FOREACH(items, item, ETLayoutItem *)
	{
		vAccumulator += itemMargin + [self rectForItem: item].size.height;
		
		if ([self isContentSizeLayout] || vAccumulator < [self layoutSize].height)
		{
			[layoutedItems addObject: item];
		}
		else
		{
			break;
		}
	}
	
	if ([layoutedItems isEmpty])
		return nil;
		
	ETLayoutLine *line = [ETLayoutLine verticalLineWithFragmentMargin: 0
		maxHeight: FLT_MAX];
	[line fillWithFragments: layoutedItems];
	
	/* Update layout size, useful when the layout context is embedded in a scroll view */
	if ([self isContentSizeLayout])
	{
		[self setLayoutSize: NSMakeSize([line width], vAccumulator)];
	}

	return line;
}

// Must override unless you use a display view
- (void) computeLocationsForFragments: (NSArray *)layoutModel
{
	if ([layoutModel count] > 1)
	{
		ETLog(@"%@ -computeLayoutItemLocationsForLayoutModel: receives a model "
			  @"with %d objects and not one, this usually means "
			  @"-layoutLineForLayoutItems: isn't overriden as it should.", self, 
			  [layoutModel count]);
	}
	
	[self computeLayoutItemLocationsForLayoutLine: [layoutModel lastObject]];
}

- (void) computeLayoutItemLocationsForLayoutLine: (ETLayoutLine *)line
{
	NSEnumerator *lineWalker = nil;
	float itemMargin = [self itemMargin];
	NSPoint itemLocation = NSMakePoint(itemMargin, itemMargin);
	BOOL isFlipped = [[self layoutContext] isFlipped];

	if (isFlipped)
	{
		lineWalker = [[line fragments] objectEnumerator];
	}
	else
	{
		/* Don't reverse the item order or selection and sorting will be messed */
		lineWalker = [[line fragments] reverseObjectEnumerator];
		itemLocation = NSMakePoint(itemMargin, [self layoutSize].height + itemMargin);	
	}
		
	FOREACHE(nil, item, ETLayoutItem *, lineWalker)
	{
		NSRect itemRect = [self rectForItem: item];
		NSPoint oldOrigin = itemRect.origin;
		NSPoint newOrigin = itemLocation;

		[self translateOriginOfItem: item byX: (newOrigin.x - oldOrigin.x) 
											Y: (newOrigin.y - oldOrigin.y)];

		if (isFlipped)
		{
			itemLocation.y += itemMargin + itemRect.size.height;
		}
		else
		{
			itemLocation.y -= itemMargin + itemRect.size.height;
		}
	}
	
	// TODO: To avoid computing item locations when they are outside of the
	// frame, think to add an exit condition here.
	
	ETDebugLog(@"Item locations computed by layout line :%@", line);
}

@end
