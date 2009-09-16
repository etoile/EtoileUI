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

/** Returns a line fragment filled with items to layout. */
- (ETLayoutLine *) layoutFragmentWithSubsetOfItems: (NSArray *)unlayoutedItems
{
	float layoutHeight = [self layoutSize].height;

	if ([self isContentSizeLayout])
	{
		layoutHeight = FLT_MAX;
	}

	ETLayoutLine *line = [ETLayoutLine verticalLineWithOwner: self 
	                                          fragmentMargin: [self itemMargin]
	                                               maxHeight: layoutHeight 
	                                               isFlipped: [_layoutContext isFlipped]];
	NSArray *acceptedItems = [line fillWithFragments: unlayoutedItems];

	if ([acceptedItems isEmpty])
		return nil;

	return line;
}

- (NSPoint) originOfFirstFragment: (id)line
{
	BOOL isFlipped = [_layoutContext isFlipped];
	float lineHeight = [line height];
	float layoutHeight = [self layoutSize].height;
	float lineY = 0; /* itemMargin already includes in the line height */

	/* The statement below looks simple but is very easy to break and hard to 
	   get right.
	   If you ever edit, please use PhotoViewExample to test the 4 cases 
	   exhaustively (resizing the layout context and varying item count, margin 
	   and scaling):
	   - [_layoutContext isFlipped] + [_layoutContext decoratorItem] == nil
	   - [_layoutContext isFlipped] + [_layoutContext decoratorItem] == scrollable area
	   - [_layoutContext isFlipped] == NO + [_layoutContext decoratorItem] == nil
	   - [_layoutContext isFlipped] == NO + [_layoutContext decoratorItem] == scrollable area */
	if (isFlipped == NO)
	{
		if ([self isContentSizeLayout] == NO || lineHeight < layoutHeight)
		{
			lineY = layoutHeight - lineHeight;
		}
	}

	return NSMakePoint([self itemMargin], lineY);
}

- (void) computeLocationsForFragments: (NSArray *)layoutModel
{
	if ([layoutModel isEmpty])
		return;

	NSParameterAssert([layoutModel count] == 1);

	ETLayoutLine *line = [layoutModel lastObject];
	float lineHeight = [line height];

	/* Will compute and set the item locations */
	[line setOrigin: [self originOfFirstFragment: line]];

	/* Update layout size, useful when the layout context is embedded in a scroll view */
	if ([self isContentSizeLayout])
	{
		/* lineHeight already includes itemMargin * 2 */
		[self setLayoutSize: NSMakeSize([line width] + [self itemMargin] * 2, lineHeight)];
	}

	ETDebugLog(@"Item locations computed by layout line :%@", line);
}

@end
