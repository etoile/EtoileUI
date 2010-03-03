/*
	Copyright (C) 2007 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  May 2007
	License:  Modified BSD (see COPYING)
 */

#import <EtoileFoundation/Macros.h>
#import <EtoileFoundation/ETCollection.h>
#import "ETLineLayout.h"
#import "ETLineFragment.h"
#import "ETCompatibility.h"


@implementation ETLineLayout

/** Returns a line fragment filled with items to layout. */
- (ETLineFragment *) layoutFragmentWithSubsetOfItems: (NSArray *)items
{
	float layoutWidth = [self layoutSize].width;

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

- (void) computeLocationsForFragments: (NSArray *)layoutModel
{
	if ([layoutModel isEmpty])
		return;

	NSParameterAssert([layoutModel count] == 1);

	ETLineFragment *line = [layoutModel lastObject];
	float totalMargin = ([self borderMargin] + [self itemMargin]) * 2;
	float contentHeight = [line height] + totalMargin;

	/* Will compute and set the item locations */
	[line setOrigin: [self originOfFirstFragment: line
	                            forContentHeight: contentHeight]];

	/* Update layout size, useful when the layout context is embedded in a scroll view */
	if ([self isContentSizeLayout])
	{
		[self setLayoutSize: NSMakeSize([line width] + totalMargin, contentHeight)];
	}

	ETDebugLog(@"Item locations computed by layout line :%@", line);
}

@end
