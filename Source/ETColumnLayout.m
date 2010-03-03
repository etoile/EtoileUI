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
#import "ETLayoutItem.h"
#import "ETLineFragment.h"
#import "ETCompatibility.h"
#include <float.h>


@implementation ETColumnLayout

/** Returns a line fragment filled with items to layout. */
- (ETLineFragment *) layoutFragmentWithSubsetOfItems: (NSArray *)unlayoutedItems
{
	float layoutHeight = [self layoutSize].height;

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

- (void) computeLocationsForFragments: (NSArray *)layoutModel
{
	if ([layoutModel isEmpty])
		return;

	NSParameterAssert([layoutModel count] == 1);

	ETLineFragment *line = [layoutModel lastObject];
	float lineHeight = [line height];
	float totalMargin = ([self borderMargin] + [self itemMargin]) * 2;
	float contentHeight = lineHeight + totalMargin;

	/* Will compute and set the item locations */
	[line setOrigin: [self originOfFirstFragment: line
	                            forContentHeight: contentHeight]];

	/* Update layout size, useful when the layout context is embedded in a scroll view */
	if ([self isContentSizeLayout])
	{
		/* lineHeight already includes itemMargin * 2 */
		[self setLayoutSize: NSMakeSize([line width] + totalMargin, contentHeight)];
	}

	ETDebugLog(@"Item locations computed by layout line :%@", line);
}

static const float undeterminedWidth = 10;

- (void) prepareSeparatorItem: (ETLayoutItem *)separator
{
	[separator setSize: NSMakeSize(undeterminedWidth, 5)];
}

- (void) adjustSeparatorItem: (ETLayoutItem *)separator forLayoutSize: (NSSize)newLayoutSize
{
	float totalEndMargin = [self separatorItemEndMargin];

	[separator setX: totalEndMargin];
	[separator setWidth: (newLayoutSize.width - totalEndMargin * 2)];
}

@end
