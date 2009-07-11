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


@implementation ETStackLayout

/** Returns a line filled with items to layout (stored in an array). */
- (ETLayoutLine *) layoutLineForLayoutItems: (NSArray *)items
{
	NSMutableArray *layoutedItems = [NSMutableArray array];
	ETLayoutLine *line = nil;
	float vAccumulator = 0;
	float itemMargin = [self itemMargin];
    
	FOREACH(items, itemToLayout, ETLayoutItem *)
	{
		vAccumulator += itemMargin + [itemToLayout height];
		
		if ([self isContentSizeLayout] || vAccumulator < [self layoutSize].height)
		{
			[layoutedItems addObject: itemToLayout];
		}
		else
		{
			break;
		}
	}
	
	if ([layoutedItems count] == 0)
		return nil;
		
	line = [ETLayoutLine layoutLineWithLayoutItems: layoutedItems];
	[line setVerticallyOriented: YES];
	
	/* Update layout size, useful when the layout context is embedded in a scroll view */
	if ([self isContentSizeLayout])
		[self setLayoutSize: NSMakeSize([line width], vAccumulator)];

	return line;
}

// Must override unless you use a display view
- (void) computeLayoutItemLocationsForLayoutModel: (NSArray *)layoutModel
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
	ETLayoutItem *item = nil;
	float itemMargin = [self itemMargin];
	NSPoint itemLocation = NSMakePoint(itemMargin, itemMargin);
	BOOL isFlipped = [[self layoutContext] isFlipped];

	if (isFlipped)
	{
		lineWalker = [[line items] objectEnumerator];
	}
	else
	{
		/* Don't reverse the item order or selection and sorting will be messed */
		lineWalker = [[line items] reverseObjectEnumerator];
		itemLocation = NSMakePoint(itemMargin, [self layoutSize].height + itemMargin);	
	}
		
	while ((item = [lineWalker nextObject]) != nil)
	{
		[item setX: itemLocation.x];
		[item setY: itemLocation.y];
		if (isFlipped)
		{
			itemLocation.y += itemMargin + [item height];
		}
		else
		{
			itemLocation.y -= itemMargin + [item height];
		}
	}
	
	// TODO: To avoid computing item locations when they are outside of the
	// frame, think to add an exit condition here.
	
	ETDebugLog(@"Item locations computed by layout line :%@", line);
}

@end
